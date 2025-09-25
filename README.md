# RAG on Kubernetes (WIP)

This repository aims to demonstrate how to run a Retrieval-Augmented Generation (RAG) solution on Kubernetes end-to-end. It packages a simple RAG backend, container images, and deployment scaffolding to help you get from local code to a cluster.

## Status
- Work in progress: APIs, images, and manifests may change frequently.
- Goal: a minimal, reproducible path to deploy a RAG stack on any Kubernetes (kind/minikube and managed clusters like GKE/EKS/AKS).

## What’s Included
- Backend: FastAPI RAG service (`app.py`) with local llama.cpp-compatible LLM and Postgres/pgvector support.
- Containers: Dockerfiles in `deploy/containers/` for backend and optional vLLM embeddings.
- Infra scaffold: Terraform skeleton under `deploy/k8s-terraform/` to provision cluster resources (experimental).
- Dev bits: `requirements.txt`, `Makefile`, and a basic project layout.

## Kubernetes Focus
- Containerization: build images for the RAG components.
- Configuration: inject secrets like `POSTGRES_URL` and other database credentials via `Secret` or external managers.
- Storage: optional `PersistentVolumeClaim` for local PDFs or caches.
- Networking: `Service` + (later) `Ingress`/`Gateway` for external access and TLS.
- Scaling: set resource requests/limits and add HPA; GPU notes for embedding/LLM pods (planned).

## Quick Start (WIP)
- Prereqs: `docker`, `kubectl`, and a local cluster (`kind` or `minikube`).
- Build backend image: `docker build -f deploy/containers/Dockerfile.backend -t rag-backend:dev .`
- Load into kind: `kind load docker-image rag-backend:dev` (if using kind).
- Apply manifests: Kubernetes manifests will be added under `deploy/k8s/` (coming soon). For now, follow progress in `deploy/` and `deploy/k8s-terraform/`.
- Access: once deployed, expose via `kubectl port-forward` or Ingress and open `http://localhost:8000/docs`.

## Build and Run (Docker)

### Nomic Embeddings (CPU-only):
Pull model:
```bash
mkdir -p ~/rag-tei/models
cd ~/rag-tei/models

git lfs install
git clone https://huggingface.co/nomic-ai/nomic-embed-text-v1.5
# (optional but safe) ensure all LFS files are present
cd nomic-embed-text-v1.5 && git lfs pull && cd ..
```

Update config.json inside nomic model with following values:
```json
  "hidden_size": 768,
  "num_attention_heads": 12,
  "num_hidden_layers": 12
```

Pull image:
```bash
# CPU-only (portable; good for M1/M2 too)
docker pull ghcr.io/huggingface/text-embeddings-inference:cpu-1.8 --platform linux/amd64
```

### LLama.cpp Chat (CPU-only):
Pull model:
```bash
mkdir -p ~/rag-chat/models
cd ~/rag-chat/models

git lfs install
git clone https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF
# (optional but safe) ensure all LFS files are present
cd Qwen2.5-1.5B-Instruct-GGUF && git lfs pull && cd ..
```

## Roadmap
- Add Kustomize/Helm manifests under `deploy/k8s/` with Secrets, PVCs, and Ingress.
- Horizontal Pod Autoscaler, PodDisruptionBudgets, and readiness/liveness probes.
- Optional GPU-enabled embeddings/LLM runtime (vLLM) and node selectors/taints.
- Observability: basic logs/metrics and guidance for Prometheus/Grafana.
- Examples for managed clouds (GKE/EKS/AKS) and Terraform modules.

## Contributing
Feedback and PRs welcome. Please treat this as a moving target and include your Kubernetes flavor, versions, and any deployment notes in issues.

## Local Development with Docker Compose

1. Copy `.env.postgres.example` to `.env.postgres` and tweak credentials/ports if needed.
2. Start Postgres (and optional services) locally:
   ```bash
   docker compose up -d postgres_dev embedding_dev llm_dev
   ```
3. Run database migrations:
   ```bash
   cd backend
   alembic upgrade head
   ```
4. Start the backend locally (`uvicorn app:app`) or start the Compose `backend_dev`/`frontend_dev` services.
5. Data is stored in the `pgdata` Docker volume. Remove it with `docker compose down --volumes` to reset.

The Compose stack now uses the `pgvector/pgvector:16` image for persistence and shares credentials with the backend via `.env.postgres`.


## Run the stack on Kubernetes (local, prod-like)

Spin up a local Kubernetes cluster on macOS (Apple Silicon supported) that’s close to production, then deploy the stack using the manifests under `deploy/k8s/` and your existing images.

### Prerequisites

* Docker Desktop for Mac (Apple Silicon OK)
* `kubectl`, `helm`, `kind`

```bash
# macOS (Homebrew)
brew install kind kubectl helm
```

Create the cluster, start from the root folder of project:

```bash
kind create cluster --config deploy/k8s/kind-cluster.yaml
kubectl get nodes -o wide
```

### 2) Install base add-ons (Ingress, Storage, TLS, Metrics)

```bash
# Default storage (local-path)
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl annotate sc local-path storageclass.kubernetes.io/is-default-class="true" --overwrite
```

```bash
# Ingress (ingress-nginx)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ing ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace --set controller.publishService.enabled=true
```

```bash
# TLS (cert-manager + self-signed ClusterIssuer)
helm repo add jetstack https://charts.jetstack.io
helm upgrade --install cert jetstack/cert-manager -n cert-manager --create-namespace --set crds.enabled=true
```

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata: { name: selfsigned-issuer }
spec:
  selfSigned: {}
EOF
```

```bash
# Metrics API (for HPA later)
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm install metrics metrics-server/metrics-server -n kube-system --set args={--kubelet-insecure-tls}
```

> Optional but recommended for “cloud-like” behavior:
>
> * **MetalLB** (LoadBalancer simulation)
> * **CNI with NetworkPolicies** (e.g., Cilium)
> * **Monitoring** (kube-prometheus-stack)

### 3) Build your images and load them into kind

Build for **linux/arm64** (Apple Silicon):

```bash
# Backend
docker build -f deploy/containers/Dockerfile.backend -t rag-backend:dev --platform linux/arm64 .
# Frontend
docker build -f deploy/containers/Dockerfile.frontend -t rag-frontend:dev --platform linux/arm64 .
# LLM (llama.cpp)
docker build -f deploy/containers/Dockerfile.llamacpp -t rag-llm:dev --platform linux/arm64 .

# Load local images into the kind cluster
kind load docker-image rag-backend:dev --name rag-dev
kind load docker-image rag-frontend:dev --name rag-dev
kind load docker-image rag-llm:dev --name rag-dev
```

**Embeddings note (Apple Silicon):** if you use an x86\_64 embeddings image (e.g., TEI cpu builds), Docker Desktop will emulate it; it runs but is slower. You don’t need to build it—Kubernetes can pull it as-is. If you prefer native ARM later, swap to an ARM-friendly embedding server and update the `Deployment`.

### 4) Prepare model/data folders (if mounting local data)

If your manifests mount local model directories (e.g., for llama.cpp or embeddings), ensure they exist and are populated as per your current Docker workflow:

```bash
mkdir -p ~/rag-chat/models
mkdir -p ~/rag-tei/models
```

### 5) Apply Kubernetes manifests

The manifests are under `deploy/k8s/` (adjust names if your repo differs):

```
deploy/k8s/
├─ 00-namespace.yaml
├─ 10-secrets.yaml
├─ 20-postgres.yaml
├─ 30-backend.yaml
├─ 40-embeddings.yaml
├─ 50-llm.yaml
└─ 60-frontend-and-ingress.yaml
```

Deploy in order (or all at once):

```bash
kubectl apply -f deploy/k8s/00-namespace.yaml
kubectl apply -f deploy/k8s/10-secrets.yaml
kubectl apply -f deploy/k8s/20-postgres.yaml
kubectl apply -f deploy/k8s/30-backend.yaml
kubectl apply -f deploy/k8s/40-embeddings.yaml
kubectl apply -f deploy/k8s/50-llm.yaml
kubectl apply -f deploy/k8s/60-frontend-and-ingress.yaml

kubectl -n rag-dev get pods,svc
```

### 6) Access the app

The Ingress is configured for `rag.localtest.me` with a self-signed cert (issued by `selfsigned-issuer`).

```bash
open https://rag.localtest.me
```

If you prefer without TLS during testing, remove the TLS section from the Ingress and use `http://rag.localtest.me`.

### 7) Troubleshooting

* **Pods Pending** → check default StorageClass and PVC binding: `kubectl get sc,pvc -A`.
* **ImagePullBackOff** → ensure `kind load docker-image ...` for locally built images or push to a reachable registry.
* **Apple Silicon perf** → x86\_64 embeddings under emulation can be slow; consider a native ARM alternative once the flow is verified.
* **DB connectivity** → verify backend env/Secret for `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`.
