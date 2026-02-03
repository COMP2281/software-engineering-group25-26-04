# =============================================================================
# DATABASE CONNECTION
# =============================================================================
# Sets up the connection to your database (SQLite or PostgreSQL).
# You don't need to modify this file - it works with both!
# =============================================================================

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from app.config import settings


# -----------------------------------------------------------------------------
# DATABASE ENGINE
# -----------------------------------------------------------------------------
# The engine connects to your database. It reads the URL from .env

# Check if using SQLite (needs special settings)
is_sqlite = settings.DATABASE_URL.startswith("sqlite")

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,  # Print SQL queries when DEBUG=true
    # SQLite needs this to work with async
    connect_args={"check_same_thread": False} if is_sqlite else {},
)


# -----------------------------------------------------------------------------
# SESSION FACTORY
# -----------------------------------------------------------------------------
# Sessions are how you interact with the database.
# Each API request gets its own session.

SessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


# -----------------------------------------------------------------------------
# BASE MODEL
# -----------------------------------------------------------------------------
# All your database tables inherit from this.
# See models.py for how to use it.

class Base(DeclarativeBase):
    pass


# -----------------------------------------------------------------------------
# GET DATABASE SESSION
# -----------------------------------------------------------------------------
# This is used by FastAPI to give each request a database session.
# You'll see it used as: db: AsyncSession = Depends(get_db)

async def get_db():
    """
    Provides a database session to your API endpoints.
    
    Usage in routes:
        @router.get("/stuff")
        async def get_stuff(db: AsyncSession = Depends(get_db)):
            # use db here
    """
    async with SessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


# -----------------------------------------------------------------------------
# CREATE TABLES
# -----------------------------------------------------------------------------
# Call this once at startup to create all your tables.

async def create_tables():
    """Creates all tables defined in models.py"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
