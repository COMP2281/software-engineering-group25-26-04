# =============================================================================
# SITE ROUTES
# =============================================================================
# Endpoints for managing site records
#
# ENDPOINTS:
# - GET    /api/sites/      - Get all sites
# - GET    /api/sites/{name} - Get one site
# - POST   /api/sites/      - Create site
# - DELETE /api/sites/{name} - Delete site
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import Site
from app.schemas import SiteCreate, SiteResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/sites", tags=["Sites"])


# GET ALL
@router.get("/", response_model=list[SiteResponse])
async def get_all_sites(db: AsyncSession = Depends(get_db)):
    """Get all sites"""
    result = await db.execute(select(Site))
    return result.scalars().all()


# CREATE
@router.post("/", response_model=SiteResponse, status_code=201)
async def create_site(data: SiteCreate, db: AsyncSession = Depends(get_db)):
    """Create a new site"""
    site = Site(**data.model_dump())
    db.add(site)
    await db.commit()
    await db.refresh(site)
    return site


# GET ONE
@router.get("/{site_name}", response_model=SiteResponse)
async def get_site(site_name: str, db: AsyncSession = Depends(get_db)):
    """Get a site by name"""
    result = await db.execute(select(Site).where(Site.site_name == site_name))
    site = result.scalar_one_or_none()

    if not site:
        raise HTTPException(status_code=404, detail="Site not found")

    return site


# DELETE
@router.delete("/{site_name}", response_model=Message)
async def delete_site(site_name: str, db: AsyncSession = Depends(get_db)):
    """Delete a site"""
    result = await db.execute(select(Site).where(Site.site_name == site_name))
    site = result.scalar_one_or_none()

    if not site:
        raise HTTPException(status_code=404, detail="Site not found")

    await db.delete(site)
    await db.commit()
    return Message(message="Site deleted")
