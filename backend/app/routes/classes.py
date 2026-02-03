# =============================================================================
# CLASS ROUTES
# =============================================================================
# Endpoints for managing classes
#
# ENDPOINTS:
# - GET    /api/classes      - Get all classes
# - GET    /api/classes/{id} - Get one class
# - POST   /api/classes      - Create class
# - PUT    /api/classes/{id} - Update class
# - DELETE /api/classes/{id} - Delete class
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import Class
from app.schemas import ClassCreate, ClassUpdate, ClassResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/classes", tags=["Classes"])


# -----------------------------------------------------------------------------
# GET ALL
# -----------------------------------------------------------------------------
@router.get("/", response_model=list[ClassResponse])
async def get_classes(db: AsyncSession = Depends(get_db)):
    """Get all classes"""
    result = await db.execute(select(Class))
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET ONE
# -----------------------------------------------------------------------------
@router.get("/{class_id}", response_model=ClassResponse)
async def get_class(class_id: int, db: AsyncSession = Depends(get_db)):
    """Get a class by ID"""
    result = await db.execute(select(Class).where(Class.class_id == class_id))
    class_ = result.scalar_one_or_none()
    
    if not class_:
        raise HTTPException(status_code=404, detail="Class not found")
    
    return class_


# -----------------------------------------------------------------------------
# CREATE
# -----------------------------------------------------------------------------
@router.post("/", response_model=ClassResponse, status_code=201)
async def create_class(data: ClassCreate, db: AsyncSession = Depends(get_db)):
    """Create a new class"""
    class_ = Class(**data.model_dump())
    db.add(class_)
    await db.commit()
    await db.refresh(class_)
    return class_


# -----------------------------------------------------------------------------
# UPDATE
# -----------------------------------------------------------------------------
@router.put("/{class_id}", response_model=ClassResponse)
async def update_class(class_id: int, data: ClassUpdate, db: AsyncSession = Depends(get_db)):
    """Update a class"""
    result = await db.execute(select(Class).where(Class.class_id == class_id))
    class_ = result.scalar_one_or_none()
    
    if not class_:
        raise HTTPException(status_code=404, detail="Class not found")
    
    # Update only provided fields
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(class_, key, value)
    
    await db.commit()
    await db.refresh(class_)
    return class_


# -----------------------------------------------------------------------------
# DELETE
# -----------------------------------------------------------------------------
@router.delete("/{class_id}", response_model=Message)
async def delete_class(class_id: int, db: AsyncSession = Depends(get_db)):
    """Delete a class"""
    result = await db.execute(select(Class).where(Class.class_id == class_id))
    class_ = result.scalar_one_or_none()
    
    if not class_:
        raise HTTPException(status_code=404, detail="Class not found")
    
    await db.delete(class_)
    await db.commit()
    return Message(message="Class deleted")
