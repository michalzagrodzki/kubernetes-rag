import os
from langchain_community.document_loaders import PyPDFLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from services.vector_store import vector_store
from services.models import PdfIngestion
from services.db import get_session
import asyncio
from starlette.concurrency import run_in_threadpool
import logging

logger = logging.getLogger(__name__)
PDF_DIR = os.getenv("PDF_DIR", "pdfs/")
ASYNC_TIMEOUT_SECONDS = int(os.getenv("INGEST_ADD_DOCS_TIMEOUT", "300"))

async def add_embeddings_with_timeout(chunks, timeout: int = ASYNC_TIMEOUT_SECONDS) -> None:
    """Persist chunk embeddings in Postgres with timeout protection."""
    logger.info("Adding embeddings to Postgres vector table...")

    task: asyncio.Task[int] = asyncio.create_task(
        asyncio.to_thread(vector_store.add_documents, chunks)
    )
    try:
        inserted = await asyncio.wait_for(asyncio.shield(task), timeout=timeout)
        logger.info("Successfully persisted %s chunks to Postgres.", inserted)
    except asyncio.TimeoutError:
        logger.warning(
            "Persisting embeddings exceeded %s seconds; allowing background completion.",
            timeout,
        )

        def _done(fut: asyncio.Task[int]) -> None:
            try:
                inserted_bg = fut.result()
                logger.info(
                    "Background embedding persistence finished successfully (%s chunks).",
                    inserted_bg,
                )
            except Exception as exc:  # noqa: BLE001 - log background failures
                logger.exception("Background embedding persistence failed: %s", exc)

        task.add_done_callback(_done)

async def ingest_pdf(file_path: str) -> int:
    logger.info("Starting PDF ingestion.")
    """
    1) Chunk the PDF & embed/store vectors in Postgres.
    2) Insert a new row into the Postgres ingestion metadata table via SQLModel.
    """
    loader = PyPDFLoader(file_path)
    docs = loader.load()
    logger.info(f"Loaded {len(docs)} documents from PDF.")

    splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
    chunks = splitter.split_documents(docs)
    logger.info(f"Split into {len(chunks)} chunks.")

    # 1) Add embeddings to Postgres-backed vector store with timeout protection
    await add_embeddings_with_timeout(chunks)

    # 2) Record ingestion metadata in Postgres
    filename = os.path.basename(file_path)
    metadata = {"chunks": len(chunks), "path": file_path}

    # Use sync DB session in a thread so we don't block the loop
    def _insert_ingestion() -> None:
        with get_session() as session:
            doc = PdfIngestion(filename=filename, meta=metadata)
            session.add(doc)
            session.commit()
    await run_in_threadpool(_insert_ingestion)
    logger.info("Inserted ingestion record into database.")

    return len(chunks)
