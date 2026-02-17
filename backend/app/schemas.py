# =============================================================================
# SCHEMAS (API REQUEST/RESPONSE SHAPES)
# =============================================================================
# Schemas define what data your API accepts and returns.
# =============================================================================

from datetime import datetime
from datetime import date as Date
from typing import Optional, List
from pydantic import BaseModel, ConfigDict


# =============================================================================
# ACCESS LEVEL SCHEMAS
# =============================================================================
class AccessLevelCreate(BaseModel):
    role: str
    description: Optional[str] = None

class AccessLevelUpdate(BaseModel):
    description: Optional[str] = None

class AccessLevelResponse(BaseModel):
    role: str
    description: Optional[str]
    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# STAFF SCHEMAS
# =============================================================================
class StaffCreate(BaseModel):
    first_name: str
    last_name: str
    email: str
    role: str  # FK to access_levels.role

class StaffUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[str] = None
    role: Optional[str] = None

class StaffResponse(BaseModel):
    staff_id: int
    first_name: str
    last_name: str
    email: str
    role: str
    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# USER SCHEMAS (Login)
# =============================================================================
class UserCreate(BaseModel):
    staff_id: int
    password: str  # Will be hashed before storing

class UserUpdate(BaseModel):
    password: Optional[str] = None

class UserResponse(BaseModel):
    staff_id: int
    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# STUDENT SCHEMAS
# =============================================================================
class StudentCreate(BaseModel):
    first_name: str
    last_name: str
    date_of_birth: Optional[Date] = None
    year_group: Optional[int] = None
    has_disability: bool = False
    disability_notes: Optional[str] = None

class StudentUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    date_of_birth: Optional[Date] = None
    year_group: Optional[int] = None
    has_disability: Optional[bool] = None
    disability_notes: Optional[str] = None

class StudentResponse(BaseModel):
    student_id: int
    first_name: str
    last_name: str
    date_of_birth: Optional[Date]
    year_group: Optional[int]
    has_disability: bool
    disability_notes: Optional[str]
    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# CLASS SCHEMAS
# =============================================================================
class ClassCreate(BaseModel):
    class_name: str
    staff_id: int  # Teacher

class ClassUpdate(BaseModel):
    class_name: Optional[str] = None
    staff_id: Optional[int] = None

class ClassResponse(BaseModel):
    class_id: int
    class_name: str
    staff_id: int
    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# CLASS-STUDENT SCHEMAS (Enrollment)
# =============================================================================
class ClassStudentCreate(BaseModel):
    class_id: int
    student_id: int

# Note: ClassStudent has composite primary key, no update needed

class ClassStudentResponse(BaseModel):
    class_id: int
    student_id: int
    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# REGISTER SCHEMAS
# =============================================================================
class RegisterCreate(BaseModel):
    register_date: Date
    class_id: int

class RegisterUpdate(BaseModel):
    register_date: Optional[Date] = None
    class_id: Optional[int] = None

class RegisterResponse(BaseModel):
    register_id: int
    register_date: Date
    class_id: int
    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# ATTENDANCE SCHEMAS
# =============================================================================
class AttendanceCreate(BaseModel):
    register_id: int
    student_id: int
    am_present: bool = False
    pm_present: bool = False
    on_site: bool = False
    note: Optional[str] = None

class AttendanceUpdate(BaseModel):
    am_present: Optional[bool] = None
    pm_present: Optional[bool] = None
    on_site: Optional[bool] = None
    note: Optional[str] = None

class AttendanceResponse(BaseModel):
    register_id: int
    student_id: int
    am_present: bool
    pm_present: bool
    on_site: bool
    note: Optional[str]
    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# INCIDENT SCHEMAS
# =============================================================================
class IncidentCreate(BaseModel):
    duty_coordinator_id: int
    incident_date: Date
    class_id: Optional[int] = None
    other_activity: Optional[str] = None
    action: Optional[str] = None
    note: Optional[str] = None
    action_taken: Optional[str] = None
    outcome: Optional[str] = None

class IncidentUpdate(BaseModel):
    duty_coordinator_id: Optional[int] = None
    incident_date: Optional[Date] = None
    class_id: Optional[int] = None
    other_activity: Optional[str] = None
    action: Optional[str] = None
    note: Optional[str] = None
    action_taken: Optional[str] = None
    outcome: Optional[str] = None

class IncidentResponse(BaseModel):
    incident_id: int
    duty_coordinator_id: int
    incident_date: Date
    class_id: Optional[int]
    other_activity: Optional[str]
    action: Optional[str]
    note: Optional[str]
    action_taken: Optional[str]
    outcome: Optional[str]
    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# STAFF-INCIDENT SCHEMAS
# =============================================================================
class StaffIncidentCreate(BaseModel):
    staff_id: int
    incident_id: int

class StaffIncidentResponse(BaseModel):
    staff_id: int
    incident_id: int
    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# STUDENT-INCIDENT SCHEMAS
# =============================================================================
class StudentIncidentCreate(BaseModel):
    student_id: int
    incident_id: int
    time: Optional[datetime] = None
    returned: bool = False

class StudentIncidentUpdate(BaseModel):
    time: Optional[datetime] = None
    returned: Optional[bool] = None

class StudentIncidentResponse(BaseModel):
    student_id: int
    incident_id: int
    time: Optional[datetime]
    returned: bool
    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# GENERIC SCHEMAS
# =============================================================================
class Message(BaseModel):
    message: str
