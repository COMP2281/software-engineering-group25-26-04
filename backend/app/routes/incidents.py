# =============================================================================
# INCIDENT ROUTES
# =============================================================================
# Endpoints for managing incident/behavior logs
#
# ENDPOINTS:
# - GET    /api/incidents           - Get all incidents
# - GET    /api/incidents/site/{id} - Get incidents by site
# - GET    /api/incidents/{id}      - Get one incident
# - POST   /api/incidents           - Create incident
# - PUT    /api/incidents/{id}      - Update incident
# - DELETE /api/incidents/{id}      - Delete incident
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import delete, join, select

from app.database import get_db
from app.models import Class, Incident, StaffIncident, StudentIncident
from app.schemas import IncidentCreate, IncidentUpdate, IncidentResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/incidents", tags=["Incidents"])


# GET ALL - must be before GET ONE to match correctly
@router.get("/", response_model=list[IncidentResponse])
async def get_incidents(db: AsyncSession = Depends(get_db)):
    """Get all incidents"""
    result = await db.execute(select(Incident).order_by(Incident.incident_id.desc()))
    return result.scalars().all()


# GET INCIDENTS BY SITE - must be before GET ONE
@router.get("/site/{site_combination_id}", response_model=list[IncidentResponse])
async def get_incidents_by_site(site_combination_id: int, db: AsyncSession = Depends(get_db)):
    """Get all incidents for a specific site"""
    result = await db.execute(
        select(Incident)
        .join(Class, Incident.class_id == Class.class_id, isouter=True)
        .where(Class.site_combination_id == site_combination_id)
        .order_by(Incident.incident_id.desc())
    )
    return result.scalars().all()


# GET ONE - must be after GET ALL and GET BY SITE
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
    
    await db.execute(
        delete(StaffIncident).where(StaffIncident.incident_id == incident_id)
    )
    await db.execute(
        delete(StudentIncident).where(StudentIncident.incident_id == incident_id)
    )
    await db.delete(incident)
    await db.commit()
    return Message(message="Incident deleted")


# -----------------------------------------------------------------------------
# EXPORT AS PDF
# -----------------------------------------------------------------------------
from fastapi.responses import Response
from fpdf import FPDF
from app.models import Staff, Student

class PDF(FPDF):
    def header(self):
        self.set_font("helvetica", "B", 18)
        self.cell(0, 10, "Duty Coordinator Log / Incident Report", align="C", new_x="LMARGIN", new_y="NEXT")
        self.set_line_width(0.5)
        self.line(10, 22, 200, 22)
        self.ln(10)

    def footer(self):
        self.set_y(-15)
        self.set_font("helvetica", "I", 8)
        self.cell(0, 10, f"Page {self.page_no()}", align="C")

@router.get("/{incident_id}/pdf")
async def export_incident_pdf(incident_id: int, db: AsyncSession = Depends(get_db)):
    """Export an incident as a PDF document"""
    # 1. Fetch incident
    result = await db.execute(select(Incident).where(Incident.incident_id == incident_id))
    incident = result.scalar_one_or_none()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
        
    # 2. Fetch involved staff
    staff_result = await db.execute(
        select(Staff)
        .join(StaffIncident, Staff.staff_id == StaffIncident.staff_id)
        .where(StaffIncident.incident_id == incident_id)
    )
    staff_list = staff_result.scalars().all()
    
    # 3. Fetch involved students
    student_result = await db.execute(
        select(Student, StudentIncident)
        .join(StudentIncident, Student.student_id == StudentIncident.student_id)
        .where(StudentIncident.incident_id == incident_id)
    )
    students_data = student_result.all()

    # 4. Fetch Duty Coordinator (if any)
    coordinator_name = "Unknown"
    if incident.duty_coordinator_id:
        coord_result = await db.execute(select(Staff).where(Staff.staff_id == incident.duty_coordinator_id))
        coord = coord_result.scalar_one_or_none()
        if coord:
            coordinator_name = f"{coord.first_name} {coord.last_name}"

    # Generate PDF
    pdf = PDF()
    pdf.add_page()
    pdf.set_font("helvetica", size=12)

    # Helper function for adding key-value rows
    def add_row(key, value):
        pdf.set_font("helvetica", "B", 12)
        pdf.cell(50, 10, f"{key}:")
        pdf.set_font("helvetica", "", 12)
        pdf.multi_cell(0, 10, str(value) if value else "N/A", new_x="LMARGIN", new_y="NEXT")

    add_row("Incident ID", incident.incident_id)
    add_row("Date", incident.incident_date.strftime("%Y-%m-%d") if incident.incident_date else "N/A")
    add_row("Duty Coordinator", coordinator_name)
    add_row("Status", incident.status)
    
    activity = incident.action or incident.other_activity or "General Incident"
    add_row("Activity/Description", activity)

    pdf.ln(5)

    # Staff Involved
    pdf.set_font("helvetica", "B", 14)
    pdf.cell(0, 10, "Staff Involved", new_x="LMARGIN", new_y="NEXT")
    pdf.set_font("helvetica", "", 12)
    if not staff_list:
        pdf.cell(0, 8, "- None", new_x="LMARGIN", new_y="NEXT")
    else:
        for staff in staff_list:
            pdf.cell(0, 8, f"- {staff.first_name} {staff.last_name}", new_x="LMARGIN", new_y="NEXT")
            
    pdf.ln(5)

    # Students Involved
    pdf.set_font("helvetica", "B", 14)
    pdf.cell(0, 10, "Pupils Involved", new_x="LMARGIN", new_y="NEXT")
    if not students_data:
        pdf.set_font("helvetica", "", 12)
        pdf.cell(0, 8, "- None", new_x="LMARGIN", new_y="NEXT")
    else:
        for st, si in students_data:
            pdf.set_font("helvetica", "B", 12)
            pdf.cell(50, 8, f"- {st.first_name} {st.last_name}")
            pdf.set_font("helvetica", "", 11)
            
            details = []
            if si.time:
                details.append(f"Time: {si.time.strftime('%H:%M')}")
            if si.returned is not None:
                details.append(f"Returned: {'Yes' if si.returned else 'No'}")
            if si.duration_minutes:
                details.append(f"Duration: {si.duration_minutes}m")
                
            pdf.multi_cell(0, 8, " | ".join(details) if details else "", new_x="LMARGIN", new_y="NEXT")

    pdf.ln(5)

    # Detailed Notes
    pdf.set_font("helvetica", "B", 14)
    pdf.cell(0, 10, "Details & Actions", new_x="LMARGIN", new_y="NEXT")
    
    add_row("Brief Description", incident.note)
    add_row("Actions Taken", incident.action_taken)
    add_row("Outcome/Consequence", incident.outcome)

    # Output as bytes
    pdf_bytes = pdf.output()

    headers = {
        'Content-Disposition': f'attachment; filename="Incident_Log_{incident_id}.pdf"'
    }
    return Response(content=bytes(pdf_bytes), media_type="application/pdf", headers=headers)
