import os
import sys
from typing import Any
import uuid
from fastapi import FastAPI, UploadFile, File, HTTPException, APIRouter, Depends
from fastapi.concurrency import asynccontextmanager
from fastapi.middleware.cors import CORSMiddleware   
from sqlalchemy import text
from services.db import get_session, init_db
from services.documents import list_documents
from services.history import append_history, get_history
from services.ingest import ingest_pdf
from schemas import UploadResponse, QueryRequest, QueryResponse
from typing import Any, List, Dict
from services.db import init_db, get_session
from fastapi.responses import JSONResponse, StreamingResponse
import logging
from fastapi import Query
from services.query import answer_question, stream_answer
import asyncio
from starlette.concurrency import run_in_threadpool

logging.basicConfig(
    level=logging.DEBUG,  # or DEBUG
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)

logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Application startup: initialize database (sync)
    init_db()
    yield
    # Application shutdown: (no actions needed currently)

app = FastAPI(
    title="RAG FastAPI (Postgres)",
    version="1.0.0",
    description="RAG service using Postgres + pgvector, local LLM, and SQLModel",
    lifespan=lifespan
)

origins = [
    "http://localhost:3000",
    "http://localhost:3001",
    "http://localhost:5173",   # Vite default
    "http://localhost:5174",
    "http://localhost:8080",
    # add production URL(s) here, e.g. "https://my-frontend.com"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,                 # exact list or ["*"] for all
    allow_credentials=True,                # cookies / Authorization headers
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=[
        "Origin",
        "X-Requested-With",
        "Content-Type",
        "Accept",
        "Authorization",
        "X-HTTP-Method-Override",
    ],
)

router_v1 = APIRouter(prefix="/v1")

@router_v1.get("/test-db")
async def test_db():
    try:
        logger.debug("Running DB health check: SELECT 1")
        def _check():
            with get_session() as session:
                result = session.execute(text("SELECT 1"))
                return result.scalar()
        value = await asyncio.wait_for(run_in_threadpool(_check), timeout=10.0)
        return {"status": "ok", "result": value}
    except Exception as e:
        logger.exception("DB health check failed")
        return {"status": "error", "detail": str(e)}

@router_v1.post(
    "/upload",
    response_model=UploadResponse,
    tags=["Ingestion"],
    summary="Upload a PDF document",
    description="Ingests a PDF, splits into chunks, and stores embeddings in Postgres"
)
async def upload_pdf(file: UploadFile = File(...)):
    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are supported")
    
    contents = await file.read()
    os.makedirs("pdfs", exist_ok=True)
    path = os.path.join("pdfs", file.filename)
    
    with open(path, "wb") as f:
        f.write(contents)

    count = await ingest_pdf(path)

    logger.info(f"Finished ingestion, inserted {count} chunks.")

    return UploadResponse(
        message="PDF ingested successfully",
        inserted_count=count
    )

@router_v1.get(
    "/documents",
    summary="List documents with pagination",
    description="Fetches paginated rows from the Postgres 'documents' table.",
    response_model=List[Dict[str, Any]],
)
async def get_all_documents(skip: int = Query(0, ge=0), limit: int = Query(10, ge=1, le=100)) -> Any:
    """
    Open a single AsyncSession, select all Document rows, and return them.
    """
    try:
        logger.info(f"Fetching documents: skip={skip}, limit={limit}")
        docs = await run_in_threadpool(list_documents, skip=skip, limit=limit)
        logger.info(f"Received docs from list_documents")
        return JSONResponse(content=docs)

    except Exception as e:
        if isinstance(e, asyncio.TimeoutError):
            raise HTTPException(status_code=504, detail="Database request timed out")
        raise HTTPException(status_code=500, detail=f"Database error: {e}")

@router_v1.post(
    "/query",
    response_model=QueryResponse,
    tags=["RAG"],
    summary="Query the knowledge base",
    description="Retrieval-Augmented Generation over ingested documents."
)
async def query_qa(req: QueryRequest):
    answer, sources = await answer_question(req.question)
    return QueryResponse(answer=answer, source_docs=sources)

@router_v1.post(
    "/query-stream",
    response_model=None,
    tags=["RAG"],
    summary="Streamed Q&A with history"
)
async def query_stream(req: QueryRequest):
    if req.conversation_id is None:
        conversation_id = str(uuid.uuid4())
    else:
        # Validate UUID format to prevent SQL errors
        try:
            uuid.UUID(req.conversation_id)
            conversation_id = req.conversation_id
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid conversation_id format (must be UUID)")

    history = await run_in_threadpool(get_history, conversation_id)

    # 2) stream tokens from OpenAI
    async def event_generator():
        full_answer = ""
        try:
            async for token in stream_answer(req.question, history):
                full_answer += token
                yield token
        except asyncio.CancelledError:
            logger.warning("Client disconnected during streaming response")
            return
        except Exception:
            logger.exception("Error while streaming response")
            return
        else:
            # Only persist history if the stream completed successfully
            await run_in_threadpool(append_history, conversation_id, req.question, full_answer)

    return StreamingResponse(
        event_generator(),
        media_type="text/plain; charset=utf-8",
        headers={"x-conversation-id": conversation_id}
    )

@router_v1.get(
    "/history/{conversation_id}",
    response_model=List[Dict[str, str]],
    tags=["History"],
    summary="Get chat history for a conversation",
    description="Returns an array of { question, answer } for the given conversation_id"
)
async def read_history(conversation_id: str):
    history = await run_in_threadpool(get_history, conversation_id)
    return JSONResponse(content=history)

app.include_router(router_v1)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", 8000)))
