# =============================================================================
# STUDENT ROUTES
# =============================================================================
# Endpoints for managing student records
#
# ENDPOINTS:
# - GET    /api/students      - Get all students
# - GET    /api/students/{id} - Get one student
# - POST   /api/students      - Create student
# - PUT    /api/students/{id} - Update student
# - DELETE /api/students/{id} - Delete student
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import Student
from app.schemas import StudentCreate, StudentUpdate, StudentResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/students", tags=["Students"])


# -----------------------------------------------------------------------------
# GET ALL
# -----------------------------------------------------------------------------
@router.get("/", response_model=list[StudentResponse])
async def get_students(db: AsyncSession = Depends(get_db)):
    """Get all students"""
    result = await db.execute(select(Student))
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET ONE
# -----------------------------------------------------------------------------
@router.get("/{student_id}", response_model=StudentResponse)
async def get_student(student_id: int, db: AsyncSession = Depends(get_db)):
    """Get a student by ID"""
    result = await db.execute(select(Student).where(Student.student_id == student_id))
    student = result.scalar_one_or_none()
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    return student


# -----------------------------------------------------------------------------
# CREATE
# -----------------------------------------------------------------------------
@router.post("/", response_model=StudentResponse, status_code=201)
async def create_student(data: StudentCreate, db: AsyncSession = Depends(get_db)):
    """Create a new student"""
    student = Student(**data.model_dump())
    db.add(student)
    await db.commit()
    await db.refresh(student)
    return student


# -----------------------------------------------------------------------------
# UPDATE
# -----------------------------------------------------------------------------
@router.put("/{student_id}", response_model=StudentResponse)
async def update_student(student_id: int, data: StudentUpdate, db: AsyncSession = Depends(get_db)):
    """Update a student"""
    result = await db.execute(select(Student).where(Student.student_id == student_id))
    student = result.scalar_one_or_none()
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    # Update only provided fields
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(student, key, value)
    
    await db.commit()
    await db.refresh(student)
    return student


# -----------------------------------------------------------------------------
# DELETE
# -----------------------------------------------------------------------------
@router.delete("/{student_id}", response_model=Message)
async def delete_student(student_id: int, db: AsyncSession = Depends(get_db)):
    """Delete a student"""
    result = await db.execute(select(Student).where(Student.student_id == student_id))
    student = result.scalar_one_or_none()
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    await db.delete(student)
    await db.commit()
    return Message(message="Student deleted")
