# =============================================================================
# STAFF-SITE ROUTES
# =============================================================================
# Endpoints for managing staff access to specific sites
#
# ENDPOINTS:
# - GET    /api/staff-sites                    - Get all staff-site assignments
# - GET    /api/staff-sites/staff/{staff_id}   - Get all sites for a staff member
# - POST   /api/staff-sites                    - Create staff-site assignment
# - DELETE /api/staff-sites/{staff_id}/{site_id} - Delete staff-site assignment
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.database import get_db
from app.models import StaffSite
from app.schemas import StaffSiteCreate, StaffSiteResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/staff-sites", tags=["Staff Sites"])


# -----------------------------------------------------------------------------
# GET ALL
# -----------------------------------------------------------------------------
@router.get("/", response_model=list[StaffSiteResponse])
async def get_staff_sites(db: AsyncSession = Depends(get_db)):
    """Get all staff-site assignments"""
    result = await db.execute(select(StaffSite))
    return result.scalars().all()


# -----------------------------------------------------------------------------
# GET SITES FOR A STAFF MEMBER
# -----------------------------------------------------------------------------
@router.get("/staff/{staff_id}", response_model=list[StaffSiteResponse])
async def get_sites_for_staff(staff_id: int, db: AsyncSession = Depends(get_db)):
    """Get all sites a staff member can access"""
    result = await db.execute(select(StaffSite).where(StaffSite.staff_id == staff_id))
    return result.scalars().all()


# -----------------------------------------------------------------------------
# CREATE
# -----------------------------------------------------------------------------
@router.post("/", response_model=StaffSiteResponse, status_code=201)
async def create_staff_site(data: StaffSiteCreate, db: AsyncSession = Depends(get_db)):
    """Assign a site to a staff member"""
    # Check if assignment already exists
    result = await db.execute(
        select(StaffSite).where(
            and_(
                StaffSite.staff_id == data.staff_id,
                StaffSite.site_combination_id == data.site_combination_id,
            )
        )
    )
    if result.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=400, detail="Staff member already assigned to this site"
        )

    staff_site = StaffSite(**data.model_dump())
    db.add(staff_site)
    await db.commit()
    await db.refresh(staff_site)
    return staff_site


# -----------------------------------------------------------------------------
# DELETE
# -----------------------------------------------------------------------------
@router.delete("/{staff_id}/{site_id}", response_model=Message)
async def delete_staff_site(
    staff_id: int, site_id: int, db: AsyncSession = Depends(get_db)
):
    """Remove a staff member's access to a site"""
    result = await db.execute(
        select(StaffSite).where(
            and_(
                StaffSite.staff_id == staff_id,
                StaffSite.site_combination_id == site_id,
            )
        )
    )
    staff_site = result.scalar_one_or_none()

    if not staff_site:
        raise HTTPException(status_code=404, detail="Staff-site assignment not found")

    await db.delete(staff_site)
    await db.commit()
    return Message(message="Staff-site assignment deleted")
