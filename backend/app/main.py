# =============================================================================
# MAIN APPLICATION
# =============================================================================
# This is the entry point. Run with: uvicorn app.main:app --reload
# =============================================================================

from contextlib import asynccontextmanager
from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import create_tables
from app.routes import auth_router, protected_routers
from app.utils.auth import get_current_user


# -----------------------------------------------------------------------------
# STARTUP/SHUTDOWN
# -----------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: create database tables
    print("🚀 Starting up...")
    await create_tables()
    print("✅ Database ready!")

    yield  # App runs here

    # Shutdown
    print("👋 Shutting down...")


# -----------------------------------------------------------------------------
# CREATE APP
# -----------------------------------------------------------------------------
app = FastAPI(
    title=settings.APP_NAME,
    lifespan=lifespan,
)


# -----------------------------------------------------------------------------
# CORS (allows frontend to call this API)
# -----------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, list specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# -----------------------------------------------------------------------------
# REGISTER ROUTES
# -----------------------------------------------------------------------------
# Public: login endpoint only — no authentication required
app.include_router(auth_router)

# Protected: every endpoint in these routers requires a valid JWT
for router in protected_routers:
    app.include_router(router, dependencies=[Depends(get_current_user)])


# -----------------------------------------------------------------------------
# HEALTH CHECK
# -----------------------------------------------------------------------------
@app.get("/")
async def root():
    return {"status": "ok", "docs": "/docs"}


# =============================================================================
# HOW TO RUN
# =============================================================================
#
# Development:
#   uvicorn app.main:app --reload
#
# Then open: http://localhost:8000/docs
#
# =============================================================================
