# =============================================================================
# ATTENDANCE ROUTES
# =============================================================================
# Endpoints for managing student attendance records
#
# ENDPOINTS:
# - GET    /api/attendance                              - Get all attendance records
# - GET    /api/attendance/register/{register_id}       - Get attendance for a register
# - GET    /api/attendance/student/{student_id}         - Get attendance for a student
# - GET    /api/attendance/{register_id}/{student_id}   - Get one attendance record
# - POST   /api/attendance                              - Create attendance record
# - PUT    /api/attendance/{register_id}/{student_id}   - Update attendance record
# - DELETE /api/attendance/{register_id}/{student_id}   - Delete attendance record
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.database import get_db
from app.models import Attendance
from app.schemas import AttendanceCreate, AttendanceUpdate, AttendanceResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/attendance", tags=["Attendance"])


# -----------------------------------------------------------------------------
# GET ALL
# -----------------------------------------------------------------------------
@router.get("/", response_model=list[AttendanceResponse])
async def get_attendance_records(db: AsyncSession = Depends(get_db)):
    """Get all attendance records"""
    result = await db.execute(select(Attendance))
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET ATTENDANCE FOR A REGISTER
# -----------------------------------------------------------------------------
@router.get("/register/{register_id}", response_model=list[AttendanceResponse])
async def get_attendance_for_register(register_id: int, db: AsyncSession = Depends(get_db)):
    """Get all attendance records for a specific register"""
    result = await db.execute(
        select(Attendance).where(Attendance.register_id == register_id)
    )
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET ATTENDANCE FOR A STUDENT
# -----------------------------------------------------------------------------
@router.get("/student/{student_id}", response_model=list[AttendanceResponse])
async def get_attendance_for_student(student_id: int, db: AsyncSession = Depends(get_db)):
    """Get all attendance records for a specific student"""
    result = await db.execute(
        select(Attendance).where(Attendance.student_id == student_id)
    )
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET ONE
# -----------------------------------------------------------------------------
@router.get("/{register_id}/{student_id}", response_model=AttendanceResponse)
async def get_attendance(register_id: int, student_id: int, db: AsyncSession = Depends(get_db)):
    """Get a specific attendance record"""
    result = await db.execute(
        select(Attendance).where(
            and_(
                Attendance.register_id == register_id,
                Attendance.student_id == student_id
            )
        )
    )
    attendance = result.scalar_one_or_none()
    
    if not attendance:
        raise HTTPException(status_code=404, detail="Attendance record not found")
    
    return attendance


# -----------------------------------------------------------------------------
# CREATE
# -----------------------------------------------------------------------------
@router.post("/", response_model=AttendanceResponse, status_code=201)
async def create_attendance(data: AttendanceCreate, db: AsyncSession = Depends(get_db)):
    """Create a new attendance record"""
    # Check if record already exists
    result = await db.execute(
        select(Attendance).where(
            and_(
                Attendance.register_id == data.register_id,
                Attendance.student_id == data.student_id
            )
        )
    )
    existing = result.scalar_one_or_none()
    
    if existing:
        raise HTTPException(status_code=400, detail="Attendance record already exists")
    
    attendance = Attendance(**data.model_dump())
    db.add(attendance)
    await db.commit()
    await db.refresh(attendance)
    return attendance


# -----------------------------------------------------------------------------
# UPDATE
# -----------------------------------------------------------------------------
@router.put("/{register_id}/{student_id}", response_model=AttendanceResponse)
async def update_attendance(
    register_id: int, 
    student_id: int, 
    data: AttendanceUpdate, 
    db: AsyncSession = Depends(get_db)
):
    """Update an attendance record"""
    result = await db.execute(
        select(Attendance).where(
            and_(
                Attendance.register_id == register_id,
                Attendance.student_id == student_id
            )
        )
    )
    attendance = result.scalar_one_or_none()
    
    if not attendance:
        raise HTTPException(status_code=404, detail="Attendance record not found")
    
    # Update only provided fields
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(attendance, key, value)
    
    await db.commit()
    await db.refresh(attendance)
    return attendance


# -----------------------------------------------------------------------------
# DELETE
# -----------------------------------------------------------------------------
@router.delete("/{register_id}/{student_id}", response_model=Message)
async def delete_attendance(register_id: int, student_id: int, db: AsyncSession = Depends(get_db)):
    """Delete an attendance record"""
    result = await db.execute(
        select(Attendance).where(
            and_(
                Attendance.register_id == register_id,
                Attendance.student_id == student_id
            )
        )
    )
    attendance = result.scalar_one_or_none()
    
    if not attendance:
        raise HTTPException(status_code=404, detail="Attendance record not found")
    
    await db.delete(attendance)
    await db.commit()
    return Message(message="Attendance record deleted")
