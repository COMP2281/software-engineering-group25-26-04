# =============================================================================
# STUDENT-INCIDENT ROUTES
# =============================================================================
# Endpoints for managing student involvement in incidents
#
# ENDPOINTS:
# - GET    /api/student-incidents                             - Get all student-incidents
# - GET    /api/student-incidents/student/{student_id}        - Get incidents for a student
# - GET    /api/student-incidents/incident/{incident_id}      - Get students in an incident
# - GET    /api/student-incidents/{student_id}/{incident_id}  - Get one student-incident
# - POST   /api/student-incidents                             - Create student-incident link
# - PUT    /api/student-incidents/{student_id}/{incident_id}  - Update student-incident link
# - DELETE /api/student-incidents/{student_id}/{incident_id}  - Delete student-incident link
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.database import get_db
from app.models import StudentIncident
from app.schemas import StudentIncidentCreate, StudentIncidentUpdate, StudentIncidentResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/student-incidents", tags=["Student Incidents"])


# -----------------------------------------------------------------------------
# GET ALL
# -----------------------------------------------------------------------------
@router.get("/", response_model=list[StudentIncidentResponse])
async def get_student_incidents(db: AsyncSession = Depends(get_db)):
    """Get all student-incident links"""
    result = await db.execute(select(StudentIncident))
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET INCIDENTS FOR A STUDENT
# -----------------------------------------------------------------------------
@router.get("/student/{student_id}", response_model=list[StudentIncidentResponse])
async def get_incidents_for_student(student_id: int, db: AsyncSession = Depends(get_db)):
    """Get all incidents a student is involved in"""
    result = await db.execute(
        select(StudentIncident).where(StudentIncident.student_id == student_id)
    )
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET STUDENTS INVOLVED IN AN INCIDENT
# -----------------------------------------------------------------------------
@router.get("/incident/{incident_id}", response_model=list[StudentIncidentResponse])
async def get_students_for_incident(incident_id: int, db: AsyncSession = Depends(get_db)):
    """Get all students involved in a specific incident"""
    result = await db.execute(
        select(StudentIncident).where(StudentIncident.incident_id == incident_id)
    )
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET ONE
# -----------------------------------------------------------------------------
@router.get("/{student_id}/{incident_id}", response_model=StudentIncidentResponse)
async def get_student_incident(student_id: int, incident_id: int, db: AsyncSession = Depends(get_db)):
    """Get a specific student-incident link"""
    result = await db.execute(
        select(StudentIncident).where(
            and_(
                StudentIncident.student_id == student_id,
                StudentIncident.incident_id == incident_id
            )
        )
    )
    student_incident = result.scalar_one_or_none()
    
    if not student_incident:
        raise HTTPException(status_code=404, detail="Student-incident link not found")
    
    return student_incident


# -----------------------------------------------------------------------------
# CREATE
# -----------------------------------------------------------------------------
@router.post("/", response_model=StudentIncidentResponse, status_code=201)
async def create_student_incident(data: StudentIncidentCreate, db: AsyncSession = Depends(get_db)):
    """Link a student to an incident"""
    # Check if link already exists
    result = await db.execute(
        select(StudentIncident).where(
            and_(
                StudentIncident.student_id == data.student_id,
                StudentIncident.incident_id == data.incident_id
            )
        )
    )
    existing = result.scalar_one_or_none()
    
    if existing:
        raise HTTPException(status_code=400, detail="Student already linked to this incident")
    
    student_incident = StudentIncident(**data.model_dump())
    db.add(student_incident)
    await db.commit()
    await db.refresh(student_incident)
    return student_incident


# -----------------------------------------------------------------------------
# UPDATE
# -----------------------------------------------------------------------------
@router.put("/{student_id}/{incident_id}", response_model=StudentIncidentResponse)
async def update_student_incident(
    student_id: int, 
    incident_id: int, 
    data: StudentIncidentUpdate, 
    db: AsyncSession = Depends(get_db)
):
    """Update a student-incident link"""
    result = await db.execute(
        select(StudentIncident).where(
            and_(
                StudentIncident.student_id == student_id,
                StudentIncident.incident_id == incident_id
            )
        )
    )
    student_incident = result.scalar_one_or_none()
    
    if not student_incident:
        raise HTTPException(status_code=404, detail="Student-incident link not found")
    
    # Update only provided fields
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(student_incident, key, value)
    
    await db.commit()
    await db.refresh(student_incident)
    return student_incident


# -----------------------------------------------------------------------------
# DELETE
# -----------------------------------------------------------------------------
@router.delete("/{student_id}/{incident_id}", response_model=Message)
async def delete_student_incident(student_id: int, incident_id: int, db: AsyncSession = Depends(get_db)):
    """Remove a student from an incident"""
    result = await db.execute(
        select(StudentIncident).where(
            and_(
                StudentIncident.student_id == student_id,
                StudentIncident.incident_id == incident_id
            )
        )
    )
    student_incident = result.scalar_one_or_none()
    
    if not student_incident:
        raise HTTPException(status_code=404, detail="Student-incident link not found")
    
    await db.delete(student_incident)
    await db.commit()
    return Message(message="Student removed from incident")
