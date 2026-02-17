# =============================================================================
# STAFF ROUTES
# =============================================================================
# Endpoints for managing staff records
#
# ENDPOINTS:
# - GET    /api/staff/      - Get all staff
# - GET    /api/staff/{id}  - Get one staff member
# - POST   /api/staff/      - Create staff
# - PUT    /api/staff/{id}  - Update staff
# - DELETE /api/staff/{id}  - Delete staff
# =============================================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import joinedload

from app.database import get_db
from app.models import Staff, Site, StaffSite
from app.schemas import StaffCreate, StaffUpdate, StaffResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/staff", tags=["Staff"])


# GET ALL - must be before GET ONE to match correctly
@router.get("/", response_model=list[StaffResponse])
async def get_all_staff(db: AsyncSession = Depends(get_db)):
    """Get all staff"""
    result = await db.execute(
        select(Staff).options(joinedload(Staff.sites).joinedload(StaffSite.site))
    )
    staff_list = result.unique().scalars().all()
    return staff_list


# CREATE
@router.post("/", response_model=StaffResponse, status_code=201)
async def create_staff(data: StaffCreate, db: AsyncSession = Depends(get_db)):
    """Create a new staff member"""
    # Create staff without sites
    staff_data = data.model_dump()
    sites = staff_data.pop("sites", [])
    staff = Staff(**staff_data)
    db.add(staff)
    await db.commit()
    await db.refresh(staff)

    # Add sites
    for site_name in sites:
        # Ensure site exists
        site_result = await db.execute(select(Site).where(Site.site_name == site_name))
        site = site_result.scalar_one_or_none()
        if not site:
            site = Site(site_name=site_name)
            db.add(site)
            await db.commit()
            await db.refresh(site)
        # Create StaffSite
        staff_site = StaffSite(staff_id=staff.staff_id, site_name=site_name)
        db.add(staff_site)

    await db.commit()
    # Refresh with sites
    result = await db.execute(
        select(Staff)
        .where(Staff.staff_id == staff.staff_id)
        .options(joinedload(Staff.sites).joinedload(StaffSite.site))
    )
    staff = result.unique().scalar_one()
    return staff


# GET ONE - must be after GET ALL
@router.get("/{staff_id}", response_model=StaffResponse)
async def get_staff(staff_id: int, db: AsyncSession = Depends(get_db)):
    """Get a staff member by ID"""
    result = await db.execute(
        select(Staff)
        .where(Staff.staff_id == staff_id)
        .options(joinedload(Staff.sites).joinedload(StaffSite.site))
    )
    staff = result.unique().scalar_one_or_none()

    if not staff:
        raise HTTPException(status_code=404, detail="Staff not found")

    return staff


# UPDATE
@router.put("/{staff_id}", response_model=StaffResponse)
async def update_staff(
    staff_id: int, data: StaffUpdate, db: AsyncSession = Depends(get_db)
):
    """Update a staff member"""
    result = await db.execute(select(Staff).where(Staff.staff_id == staff_id))
    staff = result.scalar_one_or_none()

    if not staff:
        raise HTTPException(status_code=404, detail="Staff not found")

    # Update only provided fields
    update_data = data.model_dump(exclude_unset=True)
    sites = update_data.pop("sites", None)

    for key, value in update_data.items():
        setattr(staff, key, value)

    if sites is not None:
        # Remove existing sites
        await db.execute(
            select(StaffSite).where(StaffSite.staff_id == staff_id).delete()
        )
        # Add new sites
        for site_name in sites:
            # Ensure site exists
            site_result = await db.execute(
                select(Site).where(Site.site_name == site_name)
            )
            site = site_result.scalar_one_or_none()
            if not site:
                site = Site(site_name=site_name)
                db.add(site)
                await db.commit()
                await db.refresh(site)
            # Create StaffSite
            staff_site = StaffSite(staff_id=staff.staff_id, site_name=site_name)
            db.add(staff_site)

    await db.commit()
    # Refresh with sites
    result = await db.execute(
        select(Staff)
        .where(Staff.staff_id == staff_id)
        .options(joinedload(Staff.sites).joinedload(StaffSite.site))
    )
    staff = result.unique().scalar_one()
    return staff


# DELETE
@router.delete("/{staff_id}", response_model=Message)
async def delete_staff(staff_id: int, db: AsyncSession = Depends(get_db)):
    """Delete a staff member"""
    result = await db.execute(select(Staff).where(Staff.staff_id == staff_id))
    staff = result.scalar_one_or_none()

    if not staff:
        raise HTTPException(status_code=404, detail="Staff not found")

    await db.delete(staff)
    await db.commit()
    return Message(message="Staff deleted")
