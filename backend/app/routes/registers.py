# =============================================================================
# REGISTER ROUTES
# =============================================================================
# Endpoints for managing attendance registers
#
# ENDPOINTS:
# - GET    /api/registers           - Get all registers
# - GET    /api/registers/{id}      - Get one register
# - GET    /api/registers/class/{id} - Get registers for a class
# - POST   /api/registers           - Create register
# - PUT    /api/registers/{id}      - Update register
# - DELETE /api/registers/{id}      - Delete register
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import Register
from app.schemas import RegisterCreate, RegisterUpdate, RegisterResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/registers", tags=["Registers"])


# -----------------------------------------------------------------------------
# GET ALL
# -----------------------------------------------------------------------------
@router.get("/", response_model=list[RegisterResponse])
async def get_registers(db: AsyncSession = Depends(get_db)):
    """Get all registers"""
    result = await db.execute(select(Register))
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET REGISTERS FOR A CLASS
# -----------------------------------------------------------------------------
@router.get("/class/{class_id}", response_model=list[RegisterResponse])
async def get_registers_for_class(class_id: int, db: AsyncSession = Depends(get_db)):
    """Get all registers for a specific class"""
    result = await db.execute(
        select(Register).where(Register.class_id == class_id)
    )
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET ONE
# -----------------------------------------------------------------------------
@router.get("/{register_id}", response_model=RegisterResponse)
async def get_register(register_id: int, db: AsyncSession = Depends(get_db)):
    """Get a register by ID"""
    result = await db.execute(select(Register).where(Register.register_id == register_id))
    register = result.scalar_one_or_none()
    
    if not register:
        raise HTTPException(status_code=404, detail="Register not found")
    
    return register


# -----------------------------------------------------------------------------
# CREATE
# -----------------------------------------------------------------------------
@router.post("/", response_model=RegisterResponse, status_code=201)
async def create_register(data: RegisterCreate, db: AsyncSession = Depends(get_db)):
    """Create a new register"""
    register = Register(**data.model_dump())
    db.add(register)
    await db.commit()
    await db.refresh(register)
    return register


# -----------------------------------------------------------------------------
# UPDATE
# -----------------------------------------------------------------------------
@router.put("/{register_id}", response_model=RegisterResponse)
async def update_register(register_id: int, data: RegisterUpdate, db: AsyncSession = Depends(get_db)):
    """Update a register"""
    result = await db.execute(select(Register).where(Register.register_id == register_id))
    register = result.scalar_one_or_none()
    
    if not register:
        raise HTTPException(status_code=404, detail="Register not found")
    
    # Update only provided fields
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(register, key, value)
    
    await db.commit()
    await db.refresh(register)
    return register


# -----------------------------------------------------------------------------
# DELETE
# -----------------------------------------------------------------------------
@router.delete("/{register_id}", response_model=Message)
async def delete_register(register_id: int, db: AsyncSession = Depends(get_db)):
    """Delete a register"""
    result = await db.execute(select(Register).where(Register.register_id == register_id))
    register = result.scalar_one_or_none()
    
    if not register:
        raise HTTPException(status_code=404, detail="Register not found")
    
    await db.delete(register)
    await db.commit()
    return Message(message="Register deleted")
