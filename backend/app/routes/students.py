# =============================================================================
# STUDENT ROUTES
# =============================================================================
# Endpoints for managing student records
#
# ENDPOINTS:
# - GET    /api/students                 - Get all students
# - GET    /api/students/{id}            - Get one student
# - POST   /api/students                 - Create student
# - PUT    /api/students/{id}            - Update student
# - DELETE /api/students/{id}            - Delete student
# - POST   /api/students/import-preview  - Preview CSV import
# - POST   /api/students/import          - Execute CSV import
# =============================================================================

import csv
from io import StringIO
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel

from app.database import get_db
from app.models import Student, Class, Site
from app.schemas import StudentCreate, StudentUpdate, StudentResponse, Message


# Create router with prefix and tag
router = APIRouter(prefix="/api/students", tags=["Students"])


# =============================================================================
# CSV IMPORT SCHEMAS
# =============================================================================
class ImportPreviewRow(BaseModel):
    row: int
    first_name: str
    last_name: str
    class_name: str
    site_name: str
    status: str
    error: str | None = None


class ImportPreviewResponse(BaseModel):
    total: int
    valid: int
    invalid: int
    rows: list[ImportPreviewRow]


class ImportRequest(BaseModel):
    rows: list[ImportPreviewRow]


class ImportResponse(BaseModel):
    imported: int
    failed: int
    message: str


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
async def update_student(
    student_id: int, data: StudentUpdate, db: AsyncSession = Depends(get_db)
):
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


# =============================================================================
# CSV IMPORT - PREVIEW
# =============================================================================
@router.post("/import-preview", response_model=ImportPreviewResponse)
async def import_preview(
    file: UploadFile = File(...), db: AsyncSession = Depends(get_db)
):
    """Preview CSV import before executing - validates data and shows what will be created"""
    try:
        contents = await file.read()
        csv_text = contents.decode("utf-8")
        csv_reader = csv.DictReader(StringIO(csv_text))

        if not csv_reader.fieldnames:
            raise HTTPException(status_code=400, detail="CSV file is empty or invalid")

        # Normalize fieldnames
        expected_fields = {"first name", "second name", "class", "site"}
        actual_fields = {f.strip().lower() for f in csv_reader.fieldnames}

        if not expected_fields.issubset(actual_fields):
            raise HTTPException(
                status_code=400,
                detail=f"CSV must have columns: First Name, Second Name, Class, Site",
            )

        rows = []
        valid_count = 0
        invalid_count = 0
        row_num = 2  # Start at 2 because row 1 is header

        for row_data in csv_reader:
            first_name = row_data.get("First Name", "").strip()
            last_name = row_data.get("Second Name", "").strip()
            class_name = row_data.get("Class", "").strip()
            site_name = row_data.get("Site", "").strip()

            preview_row = ImportPreviewRow(
                row=row_num,
                first_name=first_name,
                last_name=last_name,
                class_name=class_name,
                site_name=site_name,
                status="valid",
                error=None,
            )

            # Validation
            if not first_name:
                preview_row.status = "error"
                preview_row.error = "Missing first name"
                invalid_count += 1
            elif not last_name:
                preview_row.status = "error"
                preview_row.error = "Missing second name"
                invalid_count += 1
            elif not class_name:
                preview_row.status = "error"
                preview_row.error = "Missing class name"
                invalid_count += 1
            elif not site_name:
                preview_row.status = "error"
                preview_row.error = "Missing site name"
                invalid_count += 1
            else:
                # Check if site exists, create if needed
                site_result = await db.execute(
                    select(Site).where(
                        (
                            Site.site1
                            == (
                                site_name.lower() == "elemore"
                                or "site1" in site_name.lower()
                            )
                        )
                        & (
                            Site.site2
                            == (
                                site_name.lower() == "windlestone"
                                or "site2" in site_name.lower()
                            )
                        )
                        & (
                            Site.site3
                            == (
                                site_name.lower() == "pacc"
                                or "site3" in site_name.lower()
                            )
                        )
                    )
                )

                # Simpler approach: map site names to combination IDs
                site_map = {
                    "elemore": 1,
                    "windlestone": 2,
                    "pacc": 3,
                }
                site_id = site_map.get(site_name.lower())

                if not site_id:
                    preview_row.status = "error"
                    preview_row.error = (
                        f"Invalid site: {site_name}. Use: Elemore, Windlestone, or PACC"
                    )
                    invalid_count += 1
                else:
                    # Mark as valid - class will be auto-created if needed
                    valid_count += 1

            rows.append(preview_row)
            row_num += 1

        return ImportPreviewResponse(
            total=len(rows), valid=valid_count, invalid=invalid_count, rows=rows
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error parsing CSV: {str(e)}")


# =============================================================================
# CSV IMPORT - EXECUTE
# =============================================================================
@router.post("/import", response_model=ImportResponse, status_code=201)
async def import_students(data: ImportRequest, db: AsyncSession = Depends(get_db)):
    """Execute CSV import - creates students and classes as needed"""
    imported_count = 0
    failed_count = 0

    site_map = {
        "elemore": 1,
        "windlestone": 2,
        "pacc": 3,
    }

    for row in data.rows:
        if row.status == "error":
            failed_count += 1
            continue

        try:
            # Get or create class
            site_id = site_map.get(row.site_name.lower())
            if not site_id:
                failed_count += 1
                continue

            class_result = await db.execute(
                select(Class).where(
                    (Class.class_name == row.class_name)
                    & (Class.site_combination_id == site_id)
                )
            )
            class_obj = class_result.scalar_one_or_none()

            if not class_obj:
                # Auto-create class - assign to a default teacher (staff_id=1 if exists)
                try:
                    class_obj = Class(
                        class_name=row.class_name,
                        staff_id=1,  # Default to first teacher
                        site_combination_id=site_id,
                    )
                    db.add(class_obj)
                    await db.flush()
                except:
                    # If can't create class, skip this student
                    failed_count += 1
                    continue

            # Create student
            student = Student(
                first_name=row.first_name,
                last_name=row.last_name,
                site_combination_id=site_id,
            )
            db.add(student)
            await db.flush()

            # Enroll student in class
            from app.models import ClassStudent

            enrollment = ClassStudent(
                class_id=class_obj.class_id, student_id=student.student_id
            )
            db.add(enrollment)
            imported_count += 1

        except Exception as e:
            failed_count += 1

    await db.commit()

    return ImportResponse(
        imported=imported_count,
        failed=failed_count,
        message=f"Import complete: {imported_count} students imported, {failed_count} failed",
    )
