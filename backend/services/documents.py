from typing import Any, Dict, List
from sqlmodel import select
from services.models import Document
from services.db import get_session
import logging

logger = logging.getLogger(__name__)

def list_documents(skip: int = 0, limit: int = 10) -> List[Dict[str, Any]]:
    """
    Open a single AsyncSession, SELECT * FROM documents, and return
    a list of plain dicts (id, content, embedding, metadata).
    """
    try:
        with get_session() as session:
            logger.debug("Starting to fetch documents")
            stmt = select(Document).offset(skip).limit(limit)
            result = session.exec(stmt)
            docs = result.all()
            logger.debug(f"Fetched {len(docs)} documents from DB")
            documents_list: List[Dict[str, Any]] = []
            for doc in docs:
                logger.debug(f"Type of embedding: {type(doc.embedding)}")
                documents_list.append({
                    "id": str(doc.id),
                    "content": doc.content,
                    "embedding": safe_embedding(doc.embedding),
                    "metadata": doc.meta,
                })
            return documents_list
    except Exception as e:
        logger.error(f"Database error in list_documents: {e}")
        raise

def safe_embedding(embedding) -> list | None:
    if embedding is None:
        return None
    try:
        if hasattr(embedding, "tolist"):
            return embedding.tolist()
        if isinstance(embedding, (list, tuple)):
            return list(embedding)
        return [float(x) for x in embedding]  # fallback
    except Exception as e:
        logger.warning(f"Failed to convert embedding: {e}")
        return None
