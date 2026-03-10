# =============================================================================
# DATABASE MODELS
# =============================================================================
# Each class = one table in your database.
# Run after changes: alembic revision --autogenerate -m "description"
#                    alembic upgrade head
# =============================================================================

from datetime import datetime
from datetime import date
from typing import Optional, List
from sqlalchemy import String, Integer, Boolean, DateTime, Date, Text, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base


# =============================================================================
# SITES
# =============================================================================
class Site(Base):
    """Site combination lookup table"""

    __tablename__ = "sites"

    combination_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    site1: Mapped[bool] = mapped_column(Boolean, nullable=False)
    site2: Mapped[bool] = mapped_column(Boolean, nullable=False)
    site3: Mapped[bool] = mapped_column(Boolean, nullable=False)

    # Relationships
    access_levels: Mapped[List["AccessLevel"]] = relationship(
        "AccessLevel", back_populates="site"
    )
    classes: Mapped[List["Class"]] = relationship("Class", back_populates="site")
    students: Mapped[List["Student"]] = relationship("Student", back_populates="site")


# =============================================================================
# ACCESS LEVELS
# =============================================================================
class AccessLevel(Base):
    """Defines permission levels (e.g., Admin, Teacher, etc.)"""

    __tablename__ = "access_levels"

    role: Mapped[str] = mapped_column(String(50), primary_key=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    site_combination_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("sites.combination_id")
    )

    # Relationship: all staff with this access level
    staff_members: Mapped[List["Staff"]] = relationship(
        "Staff", back_populates="access"
    )
    site: Mapped["Site"] = relationship("Site", back_populates="access_levels")


# =============================================================================
# STAFF
# =============================================================================
class Staff(Base):
    """School staff members (teachers, admins, etc.)"""

    __tablename__ = "staff"

    staff_id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    first_name: Mapped[str] = mapped_column(String(100))
    last_name: Mapped[str] = mapped_column(String(100))
    email: Mapped[str] = mapped_column(String(150), unique=True)
    role: Mapped[str] = mapped_column(String(50), ForeignKey("access_levels.role"))

    # Relationships
    access: Mapped["AccessLevel"] = relationship(
        "AccessLevel", back_populates="staff_members"
    )
    user: Mapped[Optional["User"]] = relationship(
        "User", back_populates="staff", uselist=False
    )
    classes: Mapped[List["Class"]] = relationship("Class", back_populates="teacher")
    incidents_coordinated: Mapped[List["Incident"]] = relationship(
        "Incident", back_populates="duty_coordinator"
    )
    incidents_involved: Mapped[List["StaffIncident"]] = relationship(
        "StaffIncident", back_populates="staff"
    )
    site_assignments: Mapped[List["StaffSite"]] = relationship(
        "StaffSite", back_populates="staff"
    )


# =============================================================================
# STAFF-SITE (Many-to-Many: which sites each staff member can access)
# =============================================================================
class StaffSite(Base):
    """Links staff members to sites they can access"""

    __tablename__ = "staff_sites"

    staff_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("staff.staff_id"), primary_key=True
    )
    site_combination_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("sites.combination_id"), primary_key=True
    )

    # Relationships
    staff: Mapped["Staff"] = relationship("Staff", back_populates="site_assignments")
    site: Mapped["Site"] = relationship("Site")


# =============================================================================
# USERS (Login credentials)
# =============================================================================
class User(Base):
    """Login credentials linked to staff"""

    __tablename__ = "users"

    staff_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("staff.staff_id"), primary_key=True
    )
    password: Mapped[str] = mapped_column(String(128))  # Store hashed passwords!

    # Relationship
    staff: Mapped["Staff"] = relationship("Staff", back_populates="user")


# =============================================================================
# STUDENTS
# =============================================================================
class Student(Base):
    """Student records"""

    __tablename__ = "students"

    student_id: Mapped[int] = mapped_column(
        Integer, primary_key=True, autoincrement=True
    )
    first_name: Mapped[str] = mapped_column(String(100))
    last_name: Mapped[str] = mapped_column(String(100))
    site_combination_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("sites.combination_id")
    )

    # Relationships
    class_enrollments: Mapped[List["ClassStudent"]] = relationship(
        "ClassStudent", back_populates="student"
    )
    attendance_records: Mapped[List["Attendance"]] = relationship(
        "Attendance", back_populates="student"
    )
    incidents: Mapped[List["StudentIncident"]] = relationship(
        "StudentIncident", back_populates="student"
    )
    site: Mapped["Site"] = relationship("Site", back_populates="students")


# =============================================================================
# CLASSES
# =============================================================================
class Class(Base):
    """School classes (e.g., Biology 101)"""

    __tablename__ = "classes"

    class_id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    class_name: Mapped[str] = mapped_column(String(100))
    staff_id: Mapped[int] = mapped_column(Integer, ForeignKey("staff.staff_id"))
    site_combination_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("sites.combination_id")
    )

    # Relationships
    teacher: Mapped["Staff"] = relationship("Staff", back_populates="classes")
    student_enrollments: Mapped[List["ClassStudent"]] = relationship(
        "ClassStudent", back_populates="class_"
    )
    registers: Mapped[List["Register"]] = relationship(
        "Register", back_populates="class_"
    )
    site: Mapped["Site"] = relationship("Site", back_populates="classes")


# =============================================================================
# CLASS-STUDENT (Many-to-Many: which students are in which classes)
# =============================================================================
class ClassStudent(Base):
    """Links students to classes (enrollment)"""

    __tablename__ = "class_students"

    class_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("classes.class_id"), primary_key=True
    )
    student_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("students.student_id"), primary_key=True
    )

    # Relationships
    class_: Mapped["Class"] = relationship(
        "Class", back_populates="student_enrollments"
    )
    student: Mapped["Student"] = relationship(
        "Student", back_populates="class_enrollments"
    )


# =============================================================================
# REGISTER (Attendance session for a class on a date)
# =============================================================================
class Register(Base):
    """A register/attendance session for a class"""

    __tablename__ = "registers"

    register_id: Mapped[int] = mapped_column(
        Integer, primary_key=True, autoincrement=True
    )
    register_date: Mapped[date] = mapped_column(Date)
    class_id: Mapped[int] = mapped_column(Integer, ForeignKey("classes.class_id"))

    # Relationships
    class_: Mapped["Class"] = relationship("Class", back_populates="registers")
    attendance_records: Mapped[List["Attendance"]] = relationship(
        "Attendance", back_populates="register"
    )


# =============================================================================
# ATTENDANCE (Student attendance per register)
# =============================================================================
class Attendance(Base):
    """Individual student attendance for a register"""

    __tablename__ = "attendance"

    register_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("registers.register_id"), primary_key=True
    )
    student_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("students.student_id"), primary_key=True
    )
    am_present: Mapped[bool] = mapped_column(Boolean, default=False)
    pm_present: Mapped[bool] = mapped_column(Boolean, default=False)
    on_site: Mapped[bool] = mapped_column(Boolean, default=False)
    note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Relationships
    register: Mapped["Register"] = relationship(
        "Register", back_populates="attendance_records"
    )
    student: Mapped["Student"] = relationship(
        "Student", back_populates="attendance_records"
    )


# =============================================================================
# INCIDENT LOG
# =============================================================================
class Incident(Base):
    """Incident/behavior log"""

    __tablename__ = "incidents"

    incident_id: Mapped[int] = mapped_column(
        Integer, primary_key=True, autoincrement=True
    )
    duty_coordinator_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("staff.staff_id")
    )
    incident_date: Mapped[date] = mapped_column(Date)
    class_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("classes.class_id"), nullable=True
    )
    other_activity: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    status: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    action: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    action_taken: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    outcome: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Relationships
    duty_coordinator: Mapped["Staff"] = relationship(
        "Staff", back_populates="incidents_coordinated"
    )
    staff_involved: Mapped[List["StaffIncident"]] = relationship(
        "StaffIncident", back_populates="incident"
    )
    students_involved: Mapped[List["StudentIncident"]] = relationship(
        "StudentIncident", back_populates="incident"
    )


# =============================================================================
# STAFF-INCIDENT (Which staff are involved in an incident)
# =============================================================================
class StaffIncident(Base):
    """Links staff to incidents they're involved in"""

    __tablename__ = "staff_incidents"

    staff_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("staff.staff_id"), primary_key=True
    )
    incident_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("incidents.incident_id"), primary_key=True
    )

    # Relationships
    staff: Mapped["Staff"] = relationship("Staff", back_populates="incidents_involved")
    incident: Mapped["Incident"] = relationship(
        "Incident", back_populates="staff_involved"
    )


# =============================================================================
# STUDENT-INCIDENT (Which students are involved in an incident)
# =============================================================================
class StudentIncident(Base):
    """Links students to incidents with details"""

    __tablename__ = "student_incidents"

    student_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("students.student_id"), primary_key=True
    )
    incident_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("incidents.incident_id"), primary_key=True
    )
    time: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    returned: Mapped[bool] = mapped_column(Boolean, default=False)
    duration_minutes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Relationships
    student: Mapped["Student"] = relationship("Student", back_populates="incidents")
    incident: Mapped["Incident"] = relationship(
        "Incident", back_populates="students_involved"
    )
