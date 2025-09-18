# RAG on Kubernetes - Claude Instructions

This is a Retrieval-Augmented Generation (RAG) solution designed to run on Kubernetes. The project demonstrates end-to-end RAG deployment with FastAPI backend, React frontend, and containerized components.

## Project Structure

- **Backend**: FastAPI application (`backend/`) using:
  - FastAPI with SQLModel for database operations
  - OpenAI API for LLM and embeddings
  - Supabase/pgvector for vector storage
  - LangChain for RAG pipeline
  - Main entry point: `backend/app.py`

- **Frontend**: React/TypeScript application (`frontend/`) using:
  - Vite build system
  - React Router for navigation
  - Zustand for state management
  - Tailwind CSS + shadcn/ui components
  - Axios for API communication

- **Deployment**: Containerization and Kubernetes configs (`deploy/`)
  - Docker containers for backend, frontend, LLaMA.cpp, and TEI embeddings
  - Terraform configurations for K8s infrastructure
  - Support for both local (kind/minikube) and cloud deployments

## Key Commands

### Development
```bash
# Backend development
cd backend
python -m uvicorn app:app --reload --port 8000

# Frontend development
cd frontend
npm run dev

# Type checking
npm run build
npm run lint
```

### Docker Build
```bash
# Backend
docker build -f deploy/containers/Dockerfile.backend -t rag-backend:dev .

# Frontend
docker build -f deploy/containers/Dockerfile.frontend --build-arg VITE_API_URL=http://localhost:8000 -t rag-frontend:dev .

# LLaMA.cpp (chat)
docker build -f deploy/containers/Dockerfile.llamacpp -t rag-llm:qwen2.5-1.5b .
```

### Testing & Quality
- Backend: Python tests likely using pytest (check backend/ for test files)
- Frontend: ESLint for linting, TypeScript compiler for type checking
- Always run `npm run build` and `npm run lint` after frontend changes

## Environment Variables

Required environment variables (see `backend/.env`):
- `OPENAI_API_KEY`: OpenAI API key for LLM/embeddings
- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_KEY`: Supabase service key
- `POSTGRES_URL`: PostgreSQL connection string with pgvector

Optional:
- `OPENAI_MODEL`: LLM model (default: gpt-4)
- `EMBEDDING_MODEL`: Embedding model
- `SUPABASE_TABLE`: Vector table name
- `PDF_DIR`: Directory for PDF documents

## Architecture Notes

- **RAG Pipeline**: PDF ingestion → text embedding → vector storage → similarity search → LLM generation
- **Vector Store**: Uses Supabase with pgvector extension for similarity search
- **Embeddings**: Supports OpenAI embeddings or local Nomic embeddings via TEI
- **LLM**: OpenAI API or local LLaMA.cpp with Qwen models
- **Deployment**: Multi-stage Docker builds, Kubernetes manifests, Terraform infrastructure

## Development Workflow

1. Make changes to backend Python code or frontend React components
2. Test locally using development servers
3. Run linting and type checking
4. Build Docker images for testing
5. Deploy to local Kubernetes cluster (kind/minikube)
6. Test end-to-end functionality

## File Conventions

- Python: Follow FastAPI patterns, use SQLModel for database models
- TypeScript: React functional components, Zustand stores, Tailwind styling
- Docker: Multi-stage builds, platform-specific builds for ARM64/AMD64
- Kubernetes: Standard manifests with ConfigMaps/Secrets for configuration

## Common Tasks

- **Add new API endpoint**: Modify `backend/app.py` and related service files
- **Add UI component**: Create in `frontend/src/components/` following shadcn/ui patterns
- **Database changes**: Update SQLModel schemas and create Alembic migrations
- **Container updates**: Modify Dockerfiles in `deploy/containers/`
- **K8s deployment**: Update Terraform configs in `deploy/k8s-terraform/`

Always use context7 when I need code generation, setup or configuration steps, or library/API documentation. This means you should automatically use the Context7 MCP tools to resolve library id and get library docs without me having to explicitly ask.