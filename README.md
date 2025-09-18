# RAG on Kubernetes (WIP)

This repository aims to demonstrate how to run a Retrieval-Augmented Generation (RAG) solution on Kubernetes end-to-end. It packages a simple RAG backend, container images, and deployment scaffolding to help you get from local code to a cluster.

## Status
- Work in progress: APIs, images, and manifests may change frequently.
- Goal: a minimal, reproducible path to deploy a RAG stack on any Kubernetes (kind/minikube and managed clusters like GKE/EKS/AKS).

## What’s Included
- Backend: FastAPI RAG service (`app.py`) with OpenAI and pgvector/Supabase support.
- Containers: Dockerfiles in `deploy/containers/` for backend and optional vLLM embeddings.
- Infra scaffold: Terraform skeleton under `deploy/k8s-terraform/` to provision cluster resources (experimental).
- Dev bits: `requirements.txt`, `Makefile`, and a basic project layout.

## Kubernetes Focus
- Containerization: build images for the RAG components.
- Configuration: inject secrets like `OPENAI_API_KEY`, `POSTGRES_URL`, `SUPABASE_URL`, `SUPABASE_KEY` via `Secret` or external secret managers.
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
