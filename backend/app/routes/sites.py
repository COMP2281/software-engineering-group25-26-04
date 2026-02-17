# =============================================================================
# SITE ROUTES
# =============================================================================
# Endpoints for managing site combinations
#
# ENDPOINTS:
# - GET    /api/sites      - Get all site combinations
# - GET    /api/sites/{id} - Get one site combination
# - POST   /api/sites      - Create site combination
# - PUT    /api/sites/{id} - Update site combination
# - DELETE /api/sites/{id} - Delete site combination
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import Site
from app.schemas import SiteCreate, SiteUpdate, SiteResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/sites", tags=["Sites"])


# -----------------------------------------------------------------------------
# GET ALL
# -----------------------------------------------------------------------------
@router.get("/", response_model=list[SiteResponse])
async def get_sites(db: AsyncSession = Depends(get_db)):
    """Get all site combinations"""
    result = await db.execute(select(Site))
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET ONE
# -----------------------------------------------------------------------------
@router.get("/{combination_id}", response_model=SiteResponse)
async def get_site(combination_id: int, db: AsyncSession = Depends(get_db)):
    """Get a site combination by ID"""
    result = await db.execute(select(Site).where(Site.combination_id == combination_id))
    site = result.scalar_one_or_none()

    if not site:
        raise HTTPException(status_code=404, detail="Site combination not found")

    return site


# -----------------------------------------------------------------------------
# CREATE
# -----------------------------------------------------------------------------
@router.post("/", response_model=SiteResponse, status_code=201)
async def create_site(data: SiteCreate, db: AsyncSession = Depends(get_db)):
    """Create a new site combination"""
    site = Site(**data.model_dump())
    db.add(site)
    await db.commit()
    await db.refresh(site)
    return site


# -----------------------------------------------------------------------------
# UPDATE
# -----------------------------------------------------------------------------
@router.put("/{combination_id}", response_model=SiteResponse)
async def update_site(combination_id: int, data: SiteUpdate, db: AsyncSession = Depends(get_db)):
    """Update a site combination"""
    result = await db.execute(select(Site).where(Site.combination_id == combination_id))
    site = result.scalar_one_or_none()

    if not site:
        raise HTTPException(status_code=404, detail="Site combination not found")

    # Update only provided fields
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(site, key, value)

    await db.commit()
    await db.refresh(site)
    return site


# -----------------------------------------------------------------------------
# DELETE
# -----------------------------------------------------------------------------
@router.delete("/{combination_id}", response_model=Message)
async def delete_site(combination_id: int, db: AsyncSession = Depends(get_db)):
    """Delete a site combination"""
    result = await db.execute(select(Site).where(Site.combination_id == combination_id))
    site = result.scalar_one_or_none()

    if not site:
        raise HTTPException(status_code=404, detail="Site combination not found")

    await db.delete(site)
    await db.commit()
    return Message(message="Site combination deleted")
