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

Backend (FastAPI)
- Build: `docker build -f deploy/containers/Dockerfile.backend -t rag-backend:dev .`
- Run: `docker run --rm -p 8000:8000 --env-file .env rag-backend:dev`
- Env required (in `.env` or passed as `-e`): `OPENAI_API_KEY`, `SUPABASE_URL`, `SUPABASE_KEY`, `POSTGRES_URL` (and optionally `OPENAI_MODEL`, `EMBEDDING_MODEL`, `SUPABASE_TABLE`, `PDF_DIR`).
- App serves on `http://localhost:8000` (OpenAPI docs at `/docs`).
****
Frontend (Vite + Nginx)
- Build: `docker build -f deploy/containers/Dockerfile.frontend --build-arg VITE_API_URL=http://localhost:8000 -t rag-frontend:dev .`
- Run: `docker run --rm -p 8080:8080 rag-frontend:dev`
- App serves static files on `http://localhost:8080` and talks to the backend at `VITE_API_URL`.
****
vLLM Embeddings (GPU)
- Build: `docker build -f deploy/containers/Dockerfile.vllm-embeddings -t rag-vllm-embeddings:qwen3-8b .`
- Run (requires NVIDIA GPU and drivers):
  `docker run --rm --gpus all -p 8001:8000 -v qwen-hf-cache:/data/hf-cache -e MODEL_ID=Qwen/Qwen3-Embedding-8B -e TENSOR_PARALLEL=1 -e GPU_MEM_UTIL=0.9 -e MAX_MODEL_LEN=8192 -e PREFETCH=1 rag-vllm-embeddings:qwen3-8b`
- Optional: add `-e HF_TOKEN=$HF_TOKEN` if the model requires Hugging Face auth.
- API base: `http://localhost:8001/v1` (embeddings at `/embeddings`, models at `/models`).

Notes
- CORS: The backend’s allowed origins are whitelisted for typical dev ports. If serving the frontend on a different port/host (e.g., 8080), add it to the `allow_origins` list in `backend/app.py` for local testing.
 - vLLM embeddings image: See `deploy/containers/README-vllm-embeddings.md` for more details and production tips.

## Roadmap
- Add Kustomize/Helm manifests under `deploy/k8s/` with Secrets, PVCs, and Ingress.
- Horizontal Pod Autoscaler, PodDisruptionBudgets, and readiness/liveness probes.
- Optional GPU-enabled embeddings/LLM runtime (vLLM) and node selectors/taints.
- Observability: basic logs/metrics and guidance for Prometheus/Grafana.
- Examples for managed clouds (GKE/EKS/AKS) and Terraform modules.

## Contributing
Feedback and PRs welcome. Please treat this as a moving target and include your Kubernetes flavor, versions, and any deployment notes in issues.
