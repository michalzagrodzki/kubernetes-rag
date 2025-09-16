from datetime import datetime
from typing import Any, Dict, List, Optional
from uuid import UUID as PyUUID, uuid4
from sqlmodel import SQLModel, Field
from sqlalchemy.dialects.postgresql import UUID as PGUUID, JSONB
from sqlalchemy import JSON, Column
from pgvector.sqlalchemy import Vector
from config import settings

class PdfIngestion(SQLModel, table=True):
    """
    Represents a stored PDF ingestion record.
    """
    # 1) Let SQLModel create the PK column.
    #    The default_factory ensures we get a uuid4() string at runtime.
    __tablename__ = "pdf_ingestion"
    id: PyUUID = Field(
        default_factory=uuid4, 
        sa_column=Column(PGUUID(as_uuid=True), primary_key=True, nullable=False)
    )

    filename: str

    # 2) ingested_at: default to now() in Python.
    ingested_at: datetime = Field(default_factory=datetime.utcnow)

    # 3) metadata: use a JSON column in Postgres.
    meta: Dict[str, Any] = Field(
        default_factory=dict,
        sa_column=Column("metadata", JSON, nullable=False),
    )

class Document(SQLModel, table=True):
    """
    This SQLModel maps to the `public.documents` table that holds the chunked text
    and embeddings. Adjust column types/names as needed to match your actual table.
    """
    __tablename__ = "documents"  # ← must match your actual table name

    id: PyUUID = Field(
        default_factory=uuid4,
        sa_column=Column(PGUUID(as_uuid=True), primary_key=True, nullable=False),
    )
    content: str = Field(sa_column=Column("content", nullable=False))
    # If your embedding column is PGVECTOR, SQLModel won’t know it natively,
    # so you can read it as an ARRAY of floats (or JSONB) if that’s how it’s stored.
    embedding: Optional[List[float]] = Field(
        sa_column=Column("embedding", Vector(settings.pgvector_dim), nullable=True)
    )
    meta: Dict[str, Any] = Field(
        default_factory=dict,
        sa_column=Column("metadata", JSONB, nullable=False),
    )

class ChatHistory(SQLModel, table=True):
    """
    Represents a single chat turn for a conversation.
    Uses plain SQLModel fields to avoid raw SQL usage in services.
    """
    __tablename__ = "chat_history"

    id: int | None = Field(default=None, primary_key=True)
    conversation_id: PyUUID
    question: str
    answer: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
