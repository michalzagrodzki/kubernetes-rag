# RAG on Kubernetes

This repository shows how to ship a Retrieval-Augmented Generation (RAG) stack from a local developer workflow to a Kubernetes cluster. It includes a FastAPI backend wired to Postgres/pgvector, a React frontend, local llama.cpp and TEI services, plus the container and infrastructure assets required to run everything end-to-end.

## Added Value
- Opinionated starting point for running a complete RAG workflow (ingest → embed → store → retrieve → generate) without relying on hosted APIs.
- Reproducible Kubernetes deployment with manifests, secrets scaffolding, and Terraform automation for managed clusters.
- Local-first developer workflow powered by Docker Compose, hot-reload servers, and shared model volumes so you can iterate quickly.
- Model-serving targets for both embeddings (TEI) and llama.cpp-based LLMs that map cleanly between local and cluster environments.

## Technology Stack
- **Backend**: FastAPI + SQLModel + LangChain, backed by Postgres with pgvector.
- **Frontend**: React (Vite) + TypeScript + Tailwind + shadcn/ui + Zustand.
- **RAG Services**: Text Embeddings Inference (nomic-embed-text) and llama.cpp running Qwen 2.5 1.5B Instruct.
- **Orchestration**: Dockerfiles, Docker Compose, Kubernetes manifests, and Terraform modules under `deploy/`.
- **Tooling**: Alembic migrations, pytest-ready backend, ESLint/TypeScript checks, Git LFS for model pulls.

## Prerequisites
- Docker (with BuildKit) and Docker Compose v2.
- Python 3.11+ with `pip` or `uv` for backend dependencies.
- Node.js 20+ and `npm` for the frontend.
- `kubectl` plus a local cluster provider such as `kind` or `minikube` for Kubernetes testing.
- Terraform (optional) when provisioning via `deploy/k8s-terraform/`.
- Git LFS for downloading the embedding and LLM model weights.

## Environment Variables
- `POSTGRES_URL` (required): SQLAlchemy URL including the `postgresql+psycopg` driver and pgvector parameters.
- `POSTGRES_SERVER`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`: individual settings used when `POSTGRES_URL` is not provided.
- `EMBEDDING_MODEL`, `EMBEDDINGS_BASE_URL`: switch embedding model or point to an OpenAI-compatible endpoint.
- `TEI_BASE_URL`: default is the in-cluster or Compose TEI service.
- `LOCAL_LLM_BASE_URL`, `LOCAL_LLM_MODEL`, `LOCAL_LLM_STREAMING`: configure llama.cpp/Qwen runtime.
- `PDF_DIR`: location for uploaded or seeded PDFs mounted into the backend container.

## How to Run
### Local development
1. Copy `.env.postgres.example` to `.env.postgres` and edit credentials if needed.
2. Pull the embedding and LLM model weights with Git LFS (see "Build and Run (Docker)" for commands) so TEI and llama.cpp have local data.
3. Start the supporting services: `docker compose up -d postgres_dev embedding_dev llm_dev`.
4. Launch the backend: `cd backend && uvicorn app:app --reload --port 8000`. Hot reload works against the Compose services.
5. Start the frontend: `cd frontend && npm install && npm run dev` (Vite serves on http://localhost:5173 by default).

### Container images
1. Build the backend image: `docker build -f deploy/containers/Dockerfile.backend -t rag-backend:dev .`.
2. Build the frontend image: `docker build -f deploy/containers/Dockerfile.frontend --build-arg VITE_API_URL=http://localhost:8000 -t rag-frontend:dev .`.
3. Build the llama.cpp image (optional for local GPU/CPU inference): `docker build -f deploy/containers/Dockerfile.llamacpp -t rag-llm:qwen2.5-1.5b .`.

### Kubernetes (kind or minikube)
1. Provision a cluster (example): `kind create cluster --config deploy/k8s/kind-cluster.yaml`.
2. Load or push your images so the cluster can pull them (`kind load docker-image rag-backend:dev rag-frontend:dev`).
3. Update `deploy/k8s/secrets.yaml` with your database credentials and ensure the TEI/LLM ConfigMap values match your deployment.
4. Apply the manifests: `kubectl apply -f deploy/k8s/` (namespace, Postgres, embeddings, LLM, backend, frontend, network policies).
5. Port-forward or expose the services. For example, `kubectl port-forward svc/backend -n rag-dev 8000:8000` and browse to `http://localhost:8000/docs`.

## Project Structure
- `backend/`: FastAPI app (`app.py`), SQLModel schemas, services, and Alembic migrations.
- `frontend/`: React + Vite UI with Zustand state and shadcn/ui components.
- `deploy/containers/`: Dockerfiles for backend, frontend, and llama.cpp runtime.
- `deploy/k8s/`: Kubernetes manifests for local clusters (namespace, secrets, Deployments, Services, PVCs, NetworkPolicies).
- `deploy/k8s-terraform/`: Terraform modules for provisioning equivalent resources in managed Kubernetes.
- `docker-compose.yml`: local stack with Postgres, TEI, llama.cpp, backend, and frontend services.

### Directory Tree
```
.
├── backend/                 FastAPI app, models, services, and migrations
│   ├── app.py               FastAPI entrypoint wiring routes and dependencies
│   └── alembic/             Database migration scripts and env configuration
├── frontend/                React + Vite client with Zustand stores and UI components
│   ├── src/                 Application code, routes, and shared utilities
│   └── public/              Static assets served by Vite
├── deploy/
│   ├── containers/          Dockerfiles for backend, frontend, llama.cpp, and embeddings
│   ├── k8s/                 Kubernetes manifests (namespace, workloads, services, secrets)
│   └── k8s-terraform/       Terraform modules and scripts for provisioning clusters
├── docker-compose.yml       Local development stack definition
└── readme.md                Project overview and operating instructions
```

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

### Provision the stack with Terraform

```bash
# 1. Export ingress hostnames (or add them to .env and run the helper script)
export FRONTEND_HOST=app.localtest.me
export API_HOST=api.localtest.me

# Optional: generate terraform.auto.tfvars from a .env file
./deploy/k8s-terraform/scripts/generate-tfvars.sh

# 2. Initialize and apply
cd deploy/k8s-terraform
terraform init -upgrade
terraform apply \
  -var "backend_image=rag-backend:dev" \
  -var "frontend_image=rag-frontend:dev" \
  -var "postgres_url=postgresql+asyncpg://..." \
  -var "postgres_server=..." \
  -var "postgres_user=..." \
  -var "postgres_password=..." \
  -var "postgres_db=..." \
  -var "enable_tls=false"
```

### Prepare model/data folders (if mounting local data)

If your manifests mount local model directories (e.g., for llama.cpp or embeddings), ensure they exist and are populated as per your current Docker workflow:

```bash
mkdir -p ~/rag-chat/models
mkdir -p ~/rag-tei/models
```

### 6) Access the app

The Ingress is configured for `app.rag.me` with a self-signed cert (issued by `selfsigned-issuer`).

```bash
open https://app.rag.me
```

If you prefer without TLS during testing, remove the TLS section from the Ingress and use `http://app.rag.me`.

### 7) Troubleshooting

* **Pods Pending** → check default StorageClass and PVC binding: `kubectl get sc,pvc -A`.
* **ImagePullBackOff** → ensure `kind load docker-image ...` for locally built images or push to a reachable registry.
* **Apple Silicon perf** → x86\_64 embeddings under emulation can be slow; consider a native ARM alternative once the flow is verified.
* **DB connectivity** → verify backend env/Secret for `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`.
