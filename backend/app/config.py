# =============================================================================
# CONFIGURATION
# =============================================================================
# Loads settings from .env file. Create .env from .env.example first!
# =============================================================================

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """
    App settings - loaded from .env file automatically.
    
    To add a new setting:
    1. Add it here with a type and default value
    2. Add it to your .env file
    """
    
    APP_NAME: str = "My API"
    DEBUG: bool = True
    
    # Database URL - SQLite for dev, PostgreSQL for prod
    # SQLite:    sqlite+aiosqlite:///./app.db
    # Postgres:  postgresql+asyncpg://user:pass@host:5432/dbname
    DATABASE_URL: str = "sqlite+aiosqlite:///./app.db"
    
    class Config:
        env_file = ".env"


# Create a single settings instance to use everywhere
settings = Settings()
