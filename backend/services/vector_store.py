from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable
import logging

from config import settings
from services.tei_embeddings import TEIEmbeddings
from services.models import Document
from services.db import get_session

logger = logging.getLogger(__name__)


def _extract_content(doc: object) -> str:
    if hasattr(doc, "page_content"):
        return getattr(doc, "page_content") or ""
    if isinstance(doc, dict):
        return doc.get("page_content", "") or ""
    raise TypeError(f"Unsupported document payload: {type(doc)!r}")


def _extract_metadata(doc: object) -> dict:
    if hasattr(doc, "metadata"):
        return getattr(doc, "metadata") or {}
    if isinstance(doc, dict):
        return doc.get("metadata", {}) or {}
    raise TypeError(f"Unsupported document payload: {type(doc)!r}")


@dataclass
class PostgresVectorStore:
    """Embed documents with TEI and persist them in the local Postgres table."""

    embeddings: TEIEmbeddings

    def add_documents(self, docs: Iterable[object]) -> int:
        items = list(docs)
        if not items:
            logger.info("No documents to add to vector store; skipping")
            return 0

        texts = [_extract_content(doc) for doc in items]
        metadatas = [_extract_metadata(doc) for doc in items]
        logger.debug("Embedding %s chunks via TEI", len(texts))
        vectors = self.embeddings.embed_documents(texts)
        if len(vectors) != len(texts):
            raise RuntimeError(
                f"Embedding count mismatch: expected {len(texts)}, got {len(vectors)}"
            )

        logger.debug("Persisting %s embedded chunks to Postgres", len(vectors))
        with get_session() as session:
            for content, metadata, embedding in zip(texts, metadatas, vectors):
                record = Document(
                    content=content,
                    embedding=embedding,
                    meta=metadata,
                )
                session.add(record)
            session.commit()
        return len(items)


vector_store = PostgresVectorStore(
    embeddings=TEIEmbeddings(base_url=settings.tei_base_url)
)

__all__ = ["vector_store", "PostgresVectorStore"]
