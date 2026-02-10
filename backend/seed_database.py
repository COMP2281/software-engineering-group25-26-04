# =============================================================================
# DATABASE SEEDING SCRIPT
# =============================================================================
# This script populates your local database with test data.
# 
# Usage:
#   python seed_database.py
#
# Run this once after setting up the project to fill your database with
# realistic test data for development and testing.
# =============================================================================

import asyncio
from datetime import date, datetime, timedelta
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import select
from app.database import Base
from app.config import settings
from app.models import (
    AccessLevel, Staff, User, Student, Class, ClassStudent,
    Register, Attendance, Incident, StaffIncident, StudentIncident
)
import secrets
import string


async def seed_database():
    """Populate the database with test data"""
    
    # Create engine and session factory
    engine = create_async_engine(
        settings.DATABASE_URL,
        connect_args={"check_same_thread": False} if settings.DATABASE_URL.startswith("sqlite") else {},
    )
    
    SessionLocal = async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)  # Clear existing data
        await conn.run_sync(Base.metadata.create_all)  # Create fresh tables
    
    async with SessionLocal() as session:
        print("🌱 Seeding database...")
        
        # =============================================================================
        # 1. ACCESS LEVELS
        # =============================================================================
        print("  ✓ Creating access levels...")
        access_levels = [
            AccessLevel(role="Admin", description="School administrator with full access"),
            AccessLevel(role="Teacher", description="Teacher who manages classes and attendance"),
            AccessLevel(role="Staff", description="Staff member"),
        ]
        session.add_all(access_levels)
        await session.flush()
        
        # =============================================================================
        # 2. STAFF
        # =============================================================================
        print("  ✓ Creating staff members...")
        staff_members = [
            Staff(
                first_name="Alice", last_name="Johnson", 
                email="alice.johnson@school.edu", role="Admin"
            ),
            Staff(
                first_name="Bob", last_name="Smith",
                email="bob.smith@school.edu", role="Teacher"
            ),
            Staff(
                first_name="Carol", last_name="Davis",
                email="carol.davis@school.edu", role="Teacher"
            ),
            Staff(
                first_name="David", last_name="Wilson",
                email="david.wilson@school.edu", role="Teacher"
            ),
            Staff(
                first_name="Emma", last_name="Brown",
                email="emma.brown@school.edu", role="Staff"
            ),
        ]
        session.add_all(staff_members)
        await session.flush()
        
        # =============================================================================
        # 3. USERS (Login credentials)
        # =============================================================================
        print("  ✓ Creating user accounts...")
        # In production, passwords should be properly hashed!
        # For testing, using simple hashed passwords
        users = [
            User(staff_id=staff_members[0].staff_id, password="admin123"),  # Alice
            User(staff_id=staff_members[1].staff_id, password="teacher123"),  # Bob
            User(staff_id=staff_members[2].staff_id, password="teacher123"),  # Carol
            User(staff_id=staff_members[3].staff_id, password="teacher123"),  # David
            User(staff_id=staff_members[4].staff_id, password="staff123"),  # Emma
        ]
        session.add_all(users)
        await session.flush()
        
        # =============================================================================
        # 4. STUDENTS
        # =============================================================================
        print("  ✓ Creating students...")
        students = [
            Student(
                first_name="Liam", last_name="Anderson",
                date_of_birth=date(2008, 3, 15), year_group=9,
                has_disability=False
            ),
            Student(
                first_name="Olivia", last_name="Martinez",
                date_of_birth=date(2008, 7, 22), year_group=9,
                has_disability=True, disability_notes="Dyslexia - requires extra reading time"
            ),
            Student(
                first_name="Noah", last_name="Taylor",
                date_of_birth=date(2008, 1, 10), year_group=9,
                has_disability=False
            ),
            Student(
                first_name="Sophia", last_name="Thomas",
                date_of_birth=date(2007, 11, 5), year_group=10,
                has_disability=False
            ),
            Student(
                first_name="Ethan", last_name="Jackson",
                date_of_birth=date(2007, 9, 28), year_group=10,
                has_disability=True, disability_notes="ADHD - medication in morning"
            ),
            Student(
                first_name="Emma", last_name="White",
                date_of_birth=date(2008, 2, 14), year_group=9,
                has_disability=False
            ),
            Student(
                first_name="Mason", last_name="Harris",
                date_of_birth=date(2007, 8, 19), year_group=10,
                has_disability=False
            ),
            Student(
                first_name="Isabella", last_name="Clark",
                date_of_birth=date(2008, 4, 3), year_group=9,
                has_disability=False
            ),
            Student(
                first_name="James", last_name="Lewis",
                date_of_birth=date(2007, 12, 11), year_group=10,
                has_disability=False
            ),
            Student(
                first_name="Mia", last_name="Walker",
                date_of_birth=date(2008, 6, 27), year_group=9,
                has_disability=False
            ),
        ]
        session.add_all(students)
        await session.flush()
        
        # =============================================================================
        # 5. CLASSES
        # =============================================================================
        print("  ✓ Creating classes...")
        classes = [
            Class(class_name="Mathematics 9A", staff_id=staff_members[1].staff_id),  # Bob
            Class(class_name="Mathematics 10A", staff_id=staff_members[1].staff_id),  # Bob
            Class(class_name="English 9B", staff_id=staff_members[2].staff_id),  # Carol
            Class(class_name="Science 10C", staff_id=staff_members[3].staff_id),  # David
        ]
        session.add_all(classes)
        await session.flush()
        
        # =============================================================================
        # 6. CLASS-STUDENT ENROLLMENTS
        # =============================================================================
        print("  ✓ Enrolling students in classes...")
        enrollments = [
            ClassStudent(class_id=classes[0].class_id, student_id=students[0].student_id),  # Math 9A
            ClassStudent(class_id=classes[0].class_id, student_id=students[1].student_id),
            ClassStudent(class_id=classes[0].class_id, student_id=students[2].student_id),
            ClassStudent(class_id=classes[0].class_id, student_id=students[5].student_id),
            ClassStudent(class_id=classes[0].class_id, student_id=students[7].student_id),
            
            ClassStudent(class_id=classes[1].class_id, student_id=students[3].student_id),  # Math 10A
            ClassStudent(class_id=classes[1].class_id, student_id=students[4].student_id),
            ClassStudent(class_id=classes[1].class_id, student_id=students[6].student_id),
            ClassStudent(class_id=classes[1].class_id, student_id=students[8].student_id),
            
            ClassStudent(class_id=classes[2].class_id, student_id=students[0].student_id),  # English 9B
            ClassStudent(class_id=classes[2].class_id, student_id=students[1].student_id),
            ClassStudent(class_id=classes[2].class_id, student_id=students[5].student_id),
            ClassStudent(class_id=classes[2].class_id, student_id=students[9].student_id),
            
            ClassStudent(class_id=classes[3].class_id, student_id=students[3].student_id),  # Science 10C
            ClassStudent(class_id=classes[3].class_id, student_id=students[4].student_id),
            ClassStudent(class_id=classes[3].class_id, student_id=students[8].student_id),
        ]
        session.add_all(enrollments)
        await session.flush()
        
        # =============================================================================
        # 7. REGISTERS (Attendance sessions)
        # =============================================================================
        print("  ✓ Creating attendance registers...")
        today = date.today()
        registers = []
        
        # Create registers for the past 10 school days
        for i in range(10):
            current_date = today - timedelta(days=i)
            if current_date.weekday() < 5:  # Skip weekends (5=Saturday, 6=Sunday)
                for cls in classes:
                    reg = Register(register_date=current_date, class_id=cls.class_id)
                    registers.append(reg)
        
        session.add_all(registers)
        await session.flush()
        
        # =============================================================================
        # 8. ATTENDANCE RECORDS
        # =============================================================================
        print("  ✓ Recording attendance...")
        for register in registers:
            # Get all students in this class (async-friendly query)
            result = await session.execute(
                select(ClassStudent).where(ClassStudent.class_id == register.class_id)
            )
            class_students = result.scalars().all()

            for cs in class_students:
                # Randomly mark students as present/absent
                import random
                present = random.choices([True, False], weights=[0.9, 0.1])[0]
                note = "Sick leave" if not present else None
                
                attendance = Attendance(
                    register_id=register.register_id,
                    student_id=cs.student_id,
                    present=present,
                    note=note
                )
                session.add(attendance)
        
        await session.flush()
        
        # =============================================================================
        # 9. INCIDENTS
        # =============================================================================
        print("  ✓ Creating incidents...")
        incidents = [
            Incident(
                duty_coordinator_id=staff_members[0].staff_id,  # Alice
                incident_date=today - timedelta(days=2),
                class_id=classes[0].class_id,
                action="Student was late to class",
                note="Arrived 10 minutes after register",
                action_taken="Verbal warning given",
                outcome="Student apologized and settled"
            ),
            Incident(
                duty_coordinator_id=staff_members[0].staff_id,
                incident_date=today - timedelta(days=5),
                class_id=classes[2].class_id,
                action="Disruptive behavior during lesson",
                note="Talking during instruction without permission",
                action_taken="Sent to think about behavior",
                outcome="Improved after discussion"
            ),
            Incident(
                duty_coordinator_id=staff_members[4].staff_id,  # Emma
                incident_date=today - timedelta(days=1),
                other_activity="Lunch break",
                action="Minor dispute between students",
                note="Two students disagreed over lunch queue",
                action_taken="Separated and mediated discussion",
                outcome="Agreement reached, no further action needed"
            ),
            Incident(
                duty_coordinator_id=staff_members[0].staff_id,
                incident_date=today - timedelta(days=3),
                class_id=classes[1].class_id,
                action="Late homework submission",
                note="Assignment submitted without prior notification",
                action_taken="Discussed expectations",
                outcome="Student will submit on time going forward"
            ),
        ]
        session.add_all(incidents)
        await session.flush()
        
        # =============================================================================
        # 10. STAFF-INCIDENT LINKS
        # =============================================================================
        print("  ✓ Linking staff to incidents...")
        staff_incidents = [
            StaffIncident(staff_id=staff_members[1].staff_id, incident_id=incidents[0].incident_id),  # Bob
            StaffIncident(staff_id=staff_members[2].staff_id, incident_id=incidents[1].incident_id),  # Carol
            StaffIncident(staff_id=staff_members[1].staff_id, incident_id=incidents[2].incident_id),
        ]
        session.add_all(staff_incidents)
        await session.flush()
        
        # =============================================================================
        # 11. STUDENT-INCIDENT LINKS
        # =============================================================================
        print("  ✓ Linking students to incidents...")
        student_incidents = [
            StudentIncident(
                student_id=students[0].student_id,
                incident_id=incidents[0].incident_id,
                time=today - timedelta(days=2) + timedelta(hours=9),
                returned=True,
                duration_minutes=0,
                note="Late arrival"
            ),
            StudentIncident(
                student_id=students[1].student_id,
                incident_id=incidents[1].incident_id,
                time=today - timedelta(days=5) + timedelta(hours=10, minutes=30),
                returned=True,
                duration_minutes=10,
                note="Disruptive behavior"
            ),
            StudentIncident(
                student_id=students[4].student_id,
                incident_id=incidents[1].incident_id,
                time=today - timedelta(days=5) + timedelta(hours=10, minutes=30),
                returned=True,
                duration_minutes=10,
                note="Involved in dispute"
            ),
            StudentIncident(
                student_id=students[3].student_id,
                incident_id=incidents[2].incident_id,
                time=today - timedelta(days=1) + timedelta(hours=12),
                returned=True,
                duration_minutes=5,
                note="Lunch queue dispute"
            ),
            StudentIncident(
                student_id=students[6].student_id,
                incident_id=incidents[2].incident_id,
                time=today - timedelta(days=1) + timedelta(hours=12),
                returned=True,
                duration_minutes=5,
                note="Lunch queue dispute"
            ),
            StudentIncident(
                student_id=students[4].student_id,
                incident_id=incidents[3].incident_id,
                time=today - timedelta(days=3) + timedelta(hours=15),
                returned=False,
                note="Late homework"
            ),
        ]
        session.add_all(student_incidents)
        await session.flush()
        
        # Commit all changes
        await session.commit()
        
        print("\n✅ Database seeded successfully!")
        print(f"\n📊 Summary:")
        print(f"   • {len(access_levels)} access levels")
        print(f"   • {len(staff_members)} staff members")
        print(f"   • {len(users)} user accounts")
        print(f"   • {len(students)} students")
        print(f"   • {len(classes)} classes")
        print(f"   • {len(registers)} attendance registers")
        print(f"   • {len(incidents)} incidents")
        print(f"\n📝 Test Accounts:")
        print(f"   Admin: alice.johnson@school.edu / admin123")
        print(f"   Teacher: bob.smith@school.edu / teacher123")
        print(f"   Teacher: carol.davis@school.edu / teacher123")
        print(f"   Staff: emma.brown@school.edu / staff123")
    
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(seed_database())
