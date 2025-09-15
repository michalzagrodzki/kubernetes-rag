import os
from contextlib import contextmanager
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlmodel import Session as SQLModelSession
from sqlalchemy.pool import QueuePool
from dotenv import load_dotenv
from config import settings

load_dotenv()

def _build_sync_dsn(raw: str) -> str:
    dsn = raw or ""
    if "+asyncpg" in dsn:
        dsn = dsn.replace("+asyncpg", "+psycopg")
    elif "+psycopg" not in dsn and dsn.startswith("postgresql"):
        dsn = dsn.replace("postgresql://", "postgresql+psycopg://", 1)
    if "sslmode=" not in dsn:
        sep = "&" if "?" in dsn else "?"
        dsn = f"{dsn}{sep}sslmode=require"
    return dsn

SYNC_DSN = _build_sync_dsn(settings.POSTGRES_URL)

engine = create_engine(
    SYNC_DSN,
    poolclass=QueuePool,
    pool_size=int(os.getenv("DB_POOL_SIZE", "5")),
    max_overflow=int(os.getenv("DB_MAX_OVERFLOW", "5")),
    pool_pre_ping=True,
    pool_recycle=1800,
    future=True,
)

SessionLocal = sessionmaker(bind=engine, class_=SQLModelSession, expire_on_commit=False)

def init_db() -> None:
    return None

@contextmanager
def get_session() -> SQLModelSession:  # type: ignore
    session: SQLModelSession = SessionLocal()
    try:
        yield session
    finally:
        session.close()
