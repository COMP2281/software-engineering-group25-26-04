# =============================================================================
# ACCESS LEVEL ROUTES
# =============================================================================
# Endpoints for managing access levels
#
# ENDPOINTS:
# - GET    /api/access-levels      - Get all access levels
# - GET    /api/access-levels/{role} - Get one access level
# - POST   /api/access-levels      - Create access level
# - PUT    /api/access-levels/{role} - Update access level
# - DELETE /api/access-levels/{role} - Delete access level
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import AccessLevel
from app.schemas import AccessLevelCreate, AccessLevelUpdate, AccessLevelResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/access-levels", tags=["Access Levels"])


# -----------------------------------------------------------------------------
# GET ALL
# -----------------------------------------------------------------------------
@router.get("/", response_model=list[AccessLevelResponse])
async def get_access_levels(db: AsyncSession = Depends(get_db)):
    """Get all access levels"""
    result = await db.execute(select(AccessLevel))
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET ONE
# -----------------------------------------------------------------------------
@router.get("/{role}", response_model=AccessLevelResponse)
async def get_access_level(role: str, db: AsyncSession = Depends(get_db)):
    """Get an access level by role"""
    result = await db.execute(select(AccessLevel).where(AccessLevel.role == role))
    access_level = result.scalar_one_or_none()
    
    if not access_level:
        raise HTTPException(status_code=404, detail="Access level not found")
    
    return access_level


# -----------------------------------------------------------------------------
# CREATE
# -----------------------------------------------------------------------------
@router.post("/", response_model=AccessLevelResponse, status_code=201)
async def create_access_level(data: AccessLevelCreate, db: AsyncSession = Depends(get_db)):
    """Create a new access level"""
    access_level = AccessLevel(**data.model_dump())
    db.add(access_level)
    await db.commit()
    await db.refresh(access_level)
    return access_level


# -----------------------------------------------------------------------------
# UPDATE
# -----------------------------------------------------------------------------
@router.put("/{role}", response_model=AccessLevelResponse)
async def update_access_level(role: str, data: AccessLevelUpdate, db: AsyncSession = Depends(get_db)):
    """Update an access level"""
    result = await db.execute(select(AccessLevel).where(AccessLevel.role == role))
    access_level = result.scalar_one_or_none()
    
    if not access_level:
        raise HTTPException(status_code=404, detail="Access level not found")
    
    # Update only provided fields
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(access_level, key, value)
    
    await db.commit()
    await db.refresh(access_level)
    return access_level


# -----------------------------------------------------------------------------
# DELETE
# -----------------------------------------------------------------------------
@router.delete("/{role}", response_model=Message)
async def delete_access_level(role: str, db: AsyncSession = Depends(get_db)):
    """Delete an access level"""
    result = await db.execute(select(AccessLevel).where(AccessLevel.role == role))
    access_level = result.scalar_one_or_none()
    
    if not access_level:
        raise HTTPException(status_code=404, detail="Access level not found")
    
    await db.delete(access_level)
    await db.commit()
    return Message(message="Access level deleted")
