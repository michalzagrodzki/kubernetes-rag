# RAG Web API (FastAPI + Postgres)

Retrieval-Augmented Generation (RAG) backend built with FastAPI. It ingests PDFs, chunks and embeds them into a pgvector-backed table, and answers questions via OpenAI (or local LLM) while storing ingestion metadata and chat history in Postgres.

## Highlights
- Upload PDFs and query them immediately through LangChain’s pipeline.
- Local Postgres + pgvector managed via Docker Compose with persistent storage.
- Alembic migrations keep schemas in sync (baseline included).
- Streaming/non-streaming answers with optional conversation memory.
- Works with OpenAI APIs, local TEI embeddings, and llama.cpp LLM container.

## Prerequisites
- Python 3.10+
- Docker + Docker Compose v2
- OpenAI API key (or compatible endpoint)
- Optional: Git LFS if you need local TEI/LLM models

## Environment Variables
Two env files are used during development:

1. `backend/.env` — application settings (OpenAI keys, retrieval tunables). Adjust or create your own copy.
2. `.env.postgres` — Postgres connection info shared by Docker Compose, Alembic, and the backend.

Start by copying the template:

```bash
cp .env.postgres.example .env.postgres
```

Update values as needed. Defaults assume the Compose service (`postgres_dev`) with database `ragdb`, user `rag`, password `ragpassword`, on port `5432`.

### Required variables
`backend/.env` must provide at least:

```
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini
EMBEDDING_MODEL=text-embedding-3-small
TOP_K=5
PGVECTOR_DIM=768
```

`.env.postgres` should include:

```
POSTGRES_DB=ragdb
POSTGRES_USER=rag
POSTGRES_PASSWORD=ragpassword
POSTGRES_SERVER=postgres_dev
POSTGRES_PORT=5432
POSTGRES_URL=postgresql+psycopg://rag:ragpassword@postgres_dev:5432/ragdb?sslmode=disable
DATABASE_URL=postgresql+psycopg://rag:ragpassword@localhost:5432/ragdb
``` 

Adjust `POSTGRES_SERVER` to `localhost` if you run the backend outside Docker Compose.

## Local Postgres via Docker Compose

1. Pull models if you plan to run the optional embedding/LLM containers (see repo root README).
2. Copy `.env.postgres.example` to `.env.postgres` and tweak credentials/ports as required.
3. Start the stack (Postgres + optional services):
   ```bash
   docker compose up -d postgres_dev embedding_dev llm_dev
   ```
   Add `backend_dev`/`frontend_dev` if you want the entire stack running in Docker.
4. Confirm the database is reachable:
   ```bash
   docker compose exec postgres_dev psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c 'select now();'
   ```
5. Data persists in the `pgdata` Docker volume. Remove it with `docker volume rm rag-k8s_pgdata` when you need a clean slate.

## Database Schema & Migrations

Alembic handles schema creation. Baseline migration `20250316_01_baseline.py` creates:
- `pdf_ingestion` — ingestion metadata
- `documents` — chunked content + pgvector embeddings
- `chat_history` — conversation transcripts
- `vector` extension (pgvector)

Run migrations after Postgres is up:

```bash
cd backend
alembic upgrade head
```

Alembic reads `POSTGRES_URL` (or `DATABASE_URL`) from the environment. Use `ALEMBIC_DATABASE_URL` to override per command.

Create a new migration when models change:

```bash
alembic revision --autogenerate -m "describe change"
alembic upgrade head
```
Review generated SQL before upgrading.

## Running the Backend Locally (host Python)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --reload --port 8000
```

Ensure the Compose Postgres container is running (or point env vars to another Postgres instance).

## Running via Docker Compose

```bash
docker compose up -d backend_dev frontend_dev
```

- Backend listens on `http://localhost:8000`
- Frontend (if enabled) on `http://localhost:8080`
- Embeddings service on `http://localhost:7070`
- Local LLM API on `http://localhost:8081/v1`

## API Overview
- `POST /v1/upload` — Upload a PDF, chunk, embed, and store metadata in Postgres.
- `GET /v1/documents` — Paginated list of stored documents.
- `POST /v1/query` — Retrieve + answer (non-streaming).
- `POST /v1/query-stream` — Streaming answer; response header `x-conversation-id` persists history.
- `GET /v1/history/{conversation_id}` — Conversation history.

### Example requests
```bash
curl -F "file=@/path/to/file.pdf" http://localhost:8000/v1/upload

curl -X POST http://localhost:8000/v1/query \
  -H 'Content-Type: application/json' \
  -d '{"question": "What are the key points?"}'
```

## Troubleshooting
- **Connection refused**: ensure `docker compose ps postgres_dev` shows `healthy`; verify ports not taken by another Postgres install.
- **SSL errors**: local DSN includes `?sslmode=disable`. Remote instances may require `require` or `verify-full`.
- **Dimension mismatch**: align `PGVECTOR_DIM` with the embedding model dimension; update migration or create a new one when changing models.
- **Resetting data**: `docker compose down` keeps data. Remove volume with `docker compose down --volumes` or `docker volume rm rag-k8s_pgdata` for a clean DB.

## Next Steps
- Add integration tests against the Compose Postgres service.
- Extend migrations for future schema changes.
