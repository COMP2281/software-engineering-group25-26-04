# =============================================================================
# USER ROUTES (EXAMPLE - MODIFY OR DELETE!)
# =============================================================================
# This shows how to create API endpoints. Copy this pattern for your own routes.
#
# ENDPOINTS:
# - GET    /api/users      - Get all users
# - GET    /api/users/{id} - Get one user
# - POST   /api/users      - Create user
# - PUT    /api/users/{id} - Update user
# - DELETE /api/users/{id} - Delete user
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import User
from app.schemas import UserCreate, UserUpdate, UserResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/users", tags=["Users"])


# -----------------------------------------------------------------------------
# GET ALL
# -----------------------------------------------------------------------------
@router.get("/", response_model=list[UserResponse])
async def get_users(db: AsyncSession = Depends(get_db)):
    """Get all users"""
    result = await db.execute(select(User))
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET ONE
# -----------------------------------------------------------------------------
@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, db: AsyncSession = Depends(get_db)):
    """Get a user by ID"""
    result = await db.execute(select(User).where(User.staff_id == user_id))
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return user


# -----------------------------------------------------------------------------
# CREATE
# -----------------------------------------------------------------------------
@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(data: UserCreate, db: AsyncSession = Depends(get_db)):
    """Create a new user"""
    user = User(**data.model_dump())
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


# -----------------------------------------------------------------------------
# UPDATE
# -----------------------------------------------------------------------------
@router.put("/{user_id}", response_model=UserResponse)
async def update_user(user_id: int, data: UserUpdate, db: AsyncSession = Depends(get_db)):
    """Update a user"""
    result = await db.execute(select(User).where(User.staff_id == user_id))
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Update only provided fields
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(user, key, value)
    
    await db.commit()
    await db.refresh(user)
    return user


# -----------------------------------------------------------------------------
# DELETE
# -----------------------------------------------------------------------------
@router.delete("/{user_id}", response_model=Message)
async def delete_user(user_id: int, db: AsyncSession = Depends(get_db)):
    """Delete a user"""
    result = await db.execute(select(User).where(User.staff_id == user_id))
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    await db.delete(user)
    await db.commit()
    return Message(message="User deleted")


# =============================================================================
# 
#                    HOW TO CREATE YOUR OWN ROUTES
# 
# =============================================================================
# 
# 1. Create a new file: app/routes/your_routes.py
# 2. Copy this file's structure
# 3. Replace User with YourModel
# 4. Update imports for your schemas
# 5. Add router to app/routes/__init__.py
# 
# =============================================================================
