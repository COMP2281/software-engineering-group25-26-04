# =============================================================================
# ALEMBIC MIGRATIONS ENVIRONMENT
# =============================================================================
# This file tells Alembic how to connect to your database and find your models.
# You shouldn't need to modify this unless you're doing advanced stuff.
# =============================================================================

from logging.config import fileConfig
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy import create_engine
from alembic import context

# Import your models and settings
from app.config import settings
from app.database import Base
from app.models import *  # Import all models so Alembic can see them

# Alembic Config object
config = context.config

# Setup logging
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Set target metadata (your models)
target_metadata = Base.metadata


def get_url():
    """Get database URL, converting async URL to sync for Alembic."""
    url = settings.DATABASE_URL
    # Alembic needs sync drivers
    url = url.replace("+aiosqlite", "")
    url = url.replace("+asyncpg", "+psycopg2")
    return url


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = get_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    connectable = create_engine(get_url(), poolclass=pool.NullPool)

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
