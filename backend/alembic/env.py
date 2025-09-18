from __future__ import annotations

import os
from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool
from sqlmodel import SQLModel
from dotenv import load_dotenv

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PROJECT_ROOT = os.path.abspath(os.path.join(BASE_DIR, ".."))

# Load backend/.env then root-level overrides (.env.postgres)
load_dotenv(dotenv_path=os.path.join(BASE_DIR, ".env"))
load_dotenv(dotenv_path=os.path.join(PROJECT_ROOT, ".env.postgres"), override=True)
load_dotenv()  # fallback to environment defaults

from config import settings  # noqa: E402
from services import models  # noqa: F401, E402 - ensure models register with metadata

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)


def _get_database_url() -> str:
    url = (
        os.getenv("ALEMBIC_DATABASE_URL")
        or settings.POSTGRES_URL
        or os.getenv("DATABASE_URL")
    )
    if not url:
        raise RuntimeError(
            "Set POSTGRES_URL, DATABASE_URL, or ALEMBIC_DATABASE_URL to run migrations."
        )
    return url


target_metadata = SQLModel.metadata


def run_migrations_offline() -> None:
    url = _get_database_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    configuration = config.get_section(config.config_ini_section) or {}
    configuration["sqlalchemy.url"] = _get_database_url()

    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
        future=True,
    )

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
