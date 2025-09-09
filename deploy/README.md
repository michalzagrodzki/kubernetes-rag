RAG Web on Kubernetes — Terraform + Docker

This folder contains draft Dockerfiles and Terraform configuration to deploy the app to Kubernetes with three pods:
- FastAPI backend (this repo)
- vLLM model server (OpenAI-compatible)
- Frontend (React+Vite, served via Nginx)

What’s included
- deploy/containers/Dockerfile.backend — container for FastAPI backend
- deploy/containers/Dockerfile.frontend — container for React+Vite frontend
- deploy/k8s-terraform/*.tf — Terraform for Kubernetes resources: Namespace, Secrets, ConfigMap, PVC, Deployments, Services, Ingress, HPA

Assumptions
- You have a Kubernetes cluster and kubectl context configured.
- External services (Supabase URL/Key and Postgres URL) are reachable from the cluster.
- vLLM runs on a GPU node pool (adjust tolerations/nodeSelector if needed).

Quick Start
1) Build and push images (example):
   - Backend: docker build -f deploy/containers/Dockerfile.backend -t <registry>/rag-backend:<tag> .
   - Frontend: docker build -f deploy/containers/Dockerfile.frontend --build-arg VITE_API_URL=https://api.example.com -t <registry>/rag-frontend:<tag> ./path-to-frontend

2) Initialize Terraform:
   - cd deploy/k8s-terraform
   - terraform init

3) Plan and apply:
   - terraform plan -var "backend_image=<registry>/rag-backend:<tag>" -var "frontend_image=<registry>/rag-frontend:<tag>" -var "api_host=api.example.com" -var "frontend_host=app.example.com" -var "supabase_url=..." -var "supabase_key=..." -var "postgres_url=..." -var "openai_api_key=dummy" -var "enable_tls=false"
   - terraform apply ... (same vars)

Notes
- The backend mounts a PVC at /app/pdfs for uploaded files (PDF_DIR).
- vLLM is exposed inside the cluster at http://vllm:8000/v1. The backend can be switched to use it by setting OPENAI_BASE_URL to this value in the future (code change required to read it).
- Ingress is split into two hosts: app (frontend) and api (backend). Enable TLS via enable_tls + secret names.

