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
# - POST   /api/students/bulk-import - Bulk import from CSV
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import csv
import io

from app.database import get_db
from app.models import Student, Class, ClassStudent
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


# -----------------------------------------------------------------------------
# BULK IMPORT
# -----------------------------------------------------------------------------
@router.post("/bulk-import", response_model=Message)
async def bulk_import_students(file: UploadFile = File(...), db: AsyncSession = Depends(get_db)):
    """Bulk import students from CSV file with columns: first_name, surname, class, site"""
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="File must be a CSV")
    
    content = await file.read()
    csv_reader = csv.DictReader(io.StringIO(content.decode('utf-8')))
    
    created_count = 0
    for row in csv_reader:
        first_name = row.get('first name')
        surname = row.get('surname')
        class_name = row.get('class')
        site = row.get('site')
        
        if not first_name or not surname or not class_name:
            continue  # Skip invalid rows
        
        # Find or create class
        result = await db.execute(select(Class).where(Class.class_name == class_name))
        class_obj = result.scalar_one_or_none()
        if not class_obj:
            # Assume teacher is some default, but for now, create without teacher
            class_obj = Class(class_name=class_name, staff_id=1)  # TODO: handle teacher
            db.add(class_obj)
            await db.commit()
            await db.refresh(class_obj)
        
        # Create student
        student = Student(first_name=first_name, last_name=surname, site=site)
        db.add(student)
        await db.commit()
        await db.refresh(student)
        
        # Enroll in class
        enrollment = ClassStudent(class_id=class_obj.class_id, student_id=student.student_id)
        db.add(enrollment)
        await db.commit()
        
        created_count += 1
    
    return Message(message=f"Imported {created_count} students")
