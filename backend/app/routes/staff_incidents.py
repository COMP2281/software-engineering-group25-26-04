# =============================================================================
# STAFF-INCIDENT ROUTES
# =============================================================================
# Endpoints for managing staff involvement in incidents
#
# ENDPOINTS:
# - GET    /api/staff-incidents                         - Get all staff-incidents
# - GET    /api/staff-incidents/staff/{staff_id}        - Get incidents for a staff member
# - GET    /api/staff-incidents/incident/{incident_id}  - Get staff involved in an incident
# - POST   /api/staff-incidents                         - Create staff-incident link
# - DELETE /api/staff-incidents/{staff_id}/{incident_id} - Delete staff-incident link
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.database import get_db
from app.models import StaffIncident
from app.schemas import StaffIncidentCreate, StaffIncidentResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/staff-incidents", tags=["Staff Incidents"])


# -----------------------------------------------------------------------------
# GET ALL
# -----------------------------------------------------------------------------
@router.get("/", response_model=list[StaffIncidentResponse])
async def get_staff_incidents(db: AsyncSession = Depends(get_db)):
    """Get all staff-incident links"""
    result = await db.execute(select(StaffIncident))
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET INCIDENTS FOR A STAFF MEMBER
# -----------------------------------------------------------------------------
@router.get("/staff/{staff_id}", response_model=list[StaffIncidentResponse])
async def get_incidents_for_staff(staff_id: int, db: AsyncSession = Depends(get_db)):
    """Get all incidents a staff member is involved in"""
    result = await db.execute(
        select(StaffIncident).where(StaffIncident.staff_id == staff_id)
    )
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET STAFF INVOLVED IN AN INCIDENT
# -----------------------------------------------------------------------------
@router.get("/incident/{incident_id}", response_model=list[StaffIncidentResponse])
async def get_staff_for_incident(incident_id: int, db: AsyncSession = Depends(get_db)):
    """Get all staff involved in a specific incident"""
    result = await db.execute(
        select(StaffIncident).where(StaffIncident.incident_id == incident_id)
    )
    return result.scalars().all()


# -----------------------------------------------------------------------------
# CREATE
# -----------------------------------------------------------------------------
@router.post("/", response_model=StaffIncidentResponse, status_code=201)
async def create_staff_incident(data: StaffIncidentCreate, db: AsyncSession = Depends(get_db)):
    """Link a staff member to an incident"""
    # Check if link already exists
    result = await db.execute(
        select(StaffIncident).where(
            and_(
                StaffIncident.staff_id == data.staff_id,
                StaffIncident.incident_id == data.incident_id
            )
        )
    )
    existing = result.scalar_one_or_none()
    
    if existing:
        raise HTTPException(status_code=400, detail="Staff already linked to this incident")
    
    staff_incident = StaffIncident(**data.model_dump())
    db.add(staff_incident)
    await db.commit()
    await db.refresh(staff_incident)
    return staff_incident


# -----------------------------------------------------------------------------
# DELETE
# -----------------------------------------------------------------------------
@router.delete("/{staff_id}/{incident_id}", response_model=Message)
async def delete_staff_incident(staff_id: int, incident_id: int, db: AsyncSession = Depends(get_db)):
    """Remove a staff member from an incident"""
    result = await db.execute(
        select(StaffIncident).where(
            and_(
                StaffIncident.staff_id == staff_id,
                StaffIncident.incident_id == incident_id
            )
        )
    )
    staff_incident = result.scalar_one_or_none()
    
    if not staff_incident:
        raise HTTPException(status_code=404, detail="Staff-incident link not found")
    
    await db.delete(staff_incident)
    await db.commit()
    return Message(message="Staff removed from incident")
