# =============================================================================
# INCIDENT ROUTES
# =============================================================================
# Endpoints for managing incident/behavior logs
#
# ENDPOINTS:
# - GET    /api/incidents           - Get all incidents
# - GET    /api/incidents/{id}      - Get one incident
# - POST   /api/incidents           - Create incident
# - PUT    /api/incidents/{id}      - Update incident
# - DELETE /api/incidents/{id}      - Delete incident
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import Incident
from app.schemas import IncidentCreate, IncidentUpdate, IncidentResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/incidents", tags=["Incidents"])


# -----------------------------------------------------------------------------
# GET ALL
# -----------------------------------------------------------------------------
@router.get("/", response_model=list[IncidentResponse])
async def get_incidents(db: AsyncSession = Depends(get_db)):
    """Get all incidents"""
    result = await db.execute(select(Incident))
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET ONE
# -----------------------------------------------------------------------------
@router.get("/{incident_id}", response_model=IncidentResponse)
async def get_incident(incident_id: int, db: AsyncSession = Depends(get_db)):
    """Get an incident by ID"""
    result = await db.execute(select(Incident).where(Incident.incident_id == incident_id))
    incident = result.scalar_one_or_none()
    
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    
    return incident


# -----------------------------------------------------------------------------
# CREATE
# -----------------------------------------------------------------------------
@router.post("/", response_model=IncidentResponse, status_code=201)
async def create_incident(data: IncidentCreate, db: AsyncSession = Depends(get_db)):
    """Create a new incident"""
    incident = Incident(**data.model_dump())
    db.add(incident)
    await db.commit()
    await db.refresh(incident)
    return incident


# -----------------------------------------------------------------------------
# UPDATE
# -----------------------------------------------------------------------------
@router.put("/{incident_id}", response_model=IncidentResponse)
async def update_incident(incident_id: int, data: IncidentUpdate, db: AsyncSession = Depends(get_db)):
    """Update an incident"""
    result = await db.execute(select(Incident).where(Incident.incident_id == incident_id))
    incident = result.scalar_one_or_none()
    
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    
    # Update only provided fields
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(incident, key, value)
    
    await db.commit()
    await db.refresh(incident)
    return incident


# -----------------------------------------------------------------------------
# DELETE
# -----------------------------------------------------------------------------
@router.delete("/{incident_id}", response_model=Message)
async def delete_incident(incident_id: int, db: AsyncSession = Depends(get_db)):
    """Delete an incident"""
    result = await db.execute(select(Incident).where(Incident.incident_id == incident_id))
    incident = result.scalar_one_or_none()
    
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    
    await db.delete(incident)
    await db.commit()
    return Message(message="Incident deleted")
