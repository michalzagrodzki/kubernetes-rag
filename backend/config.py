from pydantic_settings import BaseSettings
from pydantic import Field
from sqlalchemy.engine import URL

class Settings(BaseSettings):
    # Supabase
    supabase_url: str = Field(..., env="SUPABASE_URL")
    supabase_key: str = Field(..., env="SUPABASE_KEY")
    supabase_table: str = Field("documents", env="SUPABASE_TABLE")
    supabase_documents: str = "documents"

    # OpenAI
    openai_api_key: str = Field(..., env="OPENAI_API_KEY")
    openai_model: str = Field("gpt-3.5-turbo", env="OPENAI_MODEL")
    embedding_model: str = Field("text-embedding-ada-002", env="EMBEDDING_MODEL")
    # Optional: direct embeddings to an OpenAI-compatible base URL (e.g., Docker Desktop model-runner)
    embeddings_base_url: str | None = Field(None, env="EMBEDDINGS_BASE_URL")

    # TEI embeddings service
    # If running locally, not in container, than use: http://localhost:7070
    tei_base_url: str = Field("http://host.docker.internal:7070", env="TEI_BASE_URL")

    # RAG params
    top_k: int = Field(5, env="TOP_K")

    pdf_dir: str = Field("pdfs/", env="PDF_DIR")

    ## PostgreSQL (metadata) credentials, read from .env
    POSTGRES_SERVER: str  = Field(..., env="POSTGRES_SERVER")
    POSTGRES_PORT: int    = Field(6543, env="POSTGRES_PORT")
    POSTGRES_USER: str    = Field(..., env="POSTGRES_USER")
    POSTGRES_PASSWORD: str = Field("", env="POSTGRES_PASSWORD")
    POSTGRES_DB: str      = Field("", env="POSTGRES_DB")
    POSTGRES_URL: str = Field("", env="POSTGRES_URL")

    # PGVector
    pgvector_dim: int = Field(768, env="PGVECTOR_DIM")

    class Config:
        env_file = ".env"

settings = Settings()
