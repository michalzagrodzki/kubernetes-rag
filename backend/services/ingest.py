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

async def add_embeddings_with_timeout(vector_store, chunks, timeout: int = ASYNC_TIMEOUT_SECONDS) -> None:
    """Run vector_store.add_documents in a background thread with a timeout.

    If the operation exceeds the timeout, proceed without cancelling it; it
    continues to run in the background, and completion/failure is logged.
    """
    logger.info("Adding embeddings to Supabase vector store...")

    task = asyncio.create_task(asyncio.to_thread(vector_store.add_documents, chunks))
    try:
        await asyncio.wait_for(asyncio.shield(task), timeout=timeout)
        logger.info("Successfully added embeddings to Supabase vector store.")
    except asyncio.TimeoutError:
        logger.warning(
            "add_documents exceeded %s seconds; proceeding while it completes in background.",
            timeout,
        )

        def _done(t: asyncio.Task) -> None:
            try:
                t.result()
                logger.info("Background add_documents finished successfully.")
            except Exception as e:  # noqa: BLE001 - log any background failure
                logger.exception("Background add_documents failed: %s", e)

        task.add_done_callback(_done)

async def ingest_pdf(file_path: str) -> int:
    logger.info("Starting PDF ingestion.")
    """
    1) Chunk the PDF & push embeddings to Supabase.
    2) Insert a new row into the Supabase Postgres 'Document' table via SQLModel.
    """
    loader = PyPDFLoader(file_path)
    docs = loader.load()
    logger.info(f"Loaded {len(docs)} documents from PDF.")

    splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
    chunks = splitter.split_documents(docs)
    logger.info(f"Split into {len(chunks)} chunks.")

    # 1) Add embeddings to Supabase vector store with timeout protection
    await add_embeddings_with_timeout(vector_store, chunks)

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
