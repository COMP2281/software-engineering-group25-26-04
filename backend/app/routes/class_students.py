# =============================================================================
# CLASS-STUDENT ROUTES (Enrollment)
# =============================================================================
# Endpoints for managing class enrollments (which students are in which classes)
#
# ENDPOINTS:
# - GET    /api/class-students                          - Get all enrollments
# - GET    /api/class-students/class/{class_id}         - Get students in a class
# - GET    /api/class-students/student/{student_id}     - Get classes for a student
# - POST   /api/class-students                          - Create enrollment
# - DELETE /api/class-students/{class_id}/{student_id}  - Delete enrollment
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.database import get_db
from app.models import ClassStudent
from app.schemas import ClassStudentCreate, ClassStudentResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/class-students", tags=["Class Students"])


# -----------------------------------------------------------------------------
# GET ALL
# -----------------------------------------------------------------------------
@router.get("/", response_model=list[ClassStudentResponse])
async def get_class_students(db: AsyncSession = Depends(get_db)):
    """Get all class-student enrollments"""
    result = await db.execute(select(ClassStudent))
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET STUDENTS IN A CLASS
# -----------------------------------------------------------------------------
@router.get("/class/{class_id}", response_model=list[ClassStudentResponse])
async def get_students_in_class(class_id: int, db: AsyncSession = Depends(get_db)):
    """Get all students enrolled in a specific class"""
    result = await db.execute(
        select(ClassStudent).where(ClassStudent.class_id == class_id)
    )
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET CLASSES FOR A STUDENT
# -----------------------------------------------------------------------------
@router.get("/student/{student_id}", response_model=list[ClassStudentResponse])
async def get_classes_for_student(student_id: int, db: AsyncSession = Depends(get_db)):
    """Get all classes a student is enrolled in"""
    result = await db.execute(
        select(ClassStudent).where(ClassStudent.student_id == student_id)
    )
    return result.scalars().all()


# -----------------------------------------------------------------------------
# CREATE
# -----------------------------------------------------------------------------
@router.post("/", response_model=ClassStudentResponse, status_code=201)
async def create_class_student(data: ClassStudentCreate, db: AsyncSession = Depends(get_db)):
    """Enroll a student in a class"""
    # Check if enrollment already exists
    result = await db.execute(
        select(ClassStudent).where(
            and_(
                ClassStudent.class_id == data.class_id,
                ClassStudent.student_id == data.student_id
            )
        )
    )
    existing = result.scalar_one_or_none()
    
    if existing:
        raise HTTPException(status_code=400, detail="Student already enrolled in this class")
    
    class_student = ClassStudent(**data.model_dump())
    db.add(class_student)
    await db.commit()
    await db.refresh(class_student)
    return class_student


# -----------------------------------------------------------------------------
# DELETE
# -----------------------------------------------------------------------------
@router.delete("/{class_id}/{student_id}", response_model=Message)
async def delete_class_student(class_id: int, student_id: int, db: AsyncSession = Depends(get_db)):
    """Remove a student from a class"""
    result = await db.execute(
        select(ClassStudent).where(
            and_(
                ClassStudent.class_id == class_id,
                ClassStudent.student_id == student_id
            )
        )
    )
    class_student = result.scalar_one_or_none()
    
    if not class_student:
        raise HTTPException(status_code=404, detail="Enrollment not found")
    
    await db.delete(class_student)
    await db.commit()
    return Message(message="Student removed from class")
