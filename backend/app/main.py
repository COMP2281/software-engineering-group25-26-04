# =============================================================================
# MAIN APPLICATION
# =============================================================================
# This is the entry point. Run with: uvicorn app.main:app --reload
# =============================================================================

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from app.config import settings
from app.database import create_tables
from app.routes import all_routers


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
# STATIC FILES (admin panel)
# -----------------------------------------------------------------------------
admin_dir = os.path.join(os.path.dirname(__file__), "../../frontend/build/web")
app.mount("/admin", StaticFiles(directory=admin_dir, html=True), name="admin")


# -----------------------------------------------------------------------------
# REGISTER ROUTES
# -----------------------------------------------------------------------------
for router in all_routers:
    app.include_router(router)


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
