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
import random
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import select
from app.database import Base
from app.config import settings
from app.models import (
    Site, AccessLevel, Staff, User, Student, Class, ClassStudent,
    Register, Attendance, Incident, StaffIncident, StudentIncident
)
from app.utils.auth import hash_password


async def seed_database():
    """Populate the database with test data"""

    # Create engine and session factory
    engine = create_async_engine(
        settings.DATABASE_URL,
        connect_args={"check_same_thread": False} if settings.DATABASE_URL.startswith(
            "sqlite") else {},
    )

    SessionLocal = async_sessionmaker(
        bind=engine, class_=AsyncSession, expire_on_commit=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)  # Clear existing data
        await conn.run_sync(Base.metadata.create_all)  # Create fresh tables

    async with SessionLocal() as session:
        print("🌱 Seeding database...")

        # =============================================================================
        # 1. SITES
        # =============================================================================
        print("  ✓ Creating sites...")
        sites = [
            Site(combination_id=1, site1=True, site2=False, site3=False),
            Site(combination_id=2, site1=False, site2=True, site3=False),
            Site(combination_id=3, site1=False, site2=False, site3=True),
            Site(combination_id=4, site1=True, site2=False, site3=True),
            Site(combination_id=5, site1=False, site2=True, site3=True),
            Site(combination_id=6, site1=True, site2=True, site3=True),
            Site(combination_id=7, site1=True, site2=True, site3=False),
            Site(combination_id=8, site1=False, site2=False, site3=False),
        ]
        session.add_all(sites)
        await session.flush()

        # =============================================================================
        # 2. ACCESS LEVELS
        # =============================================================================
        print("  ✓ Creating access levels...")
        access_levels = [
            AccessLevel(
                role="Admin", description="School administrator with full access", site_combination_id=6),
            AccessLevel(
                role="Teacher", description="Teacher who manages classes and attendance", site_combination_id=7),
            AccessLevel(role="Staff", description="Staff member",
                        site_combination_id=8),
        ]
        session.add_all(access_levels)
        await session.flush()

        # =============================================================================
        # 3. STAFF
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
        # 4. USERS (Login credentials)
        # =============================================================================
        print("  ✓ Creating user accounts...")
        # In production, passwords should be properly hashed!
        # For testing, using simple hashed passwords
        users = [
            User(staff_id=staff_members[0].staff_id, password=hash_password(
                "admin123")),    # Alice
            User(staff_id=staff_members[1].staff_id,
                 password=hash_password("teacher123")),  # Bob
            User(staff_id=staff_members[2].staff_id, password=hash_password(
                "teacher123")),  # Carol
            User(staff_id=staff_members[3].staff_id, password=hash_password(
                "teacher123")),  # David
            User(staff_id=staff_members[4].staff_id, password=hash_password(
                "staff123")),    # Emma
        ]
        session.add_all(users)
        await session.flush()

        # =============================================================================
        # 5. STUDENTS
        # =============================================================================
        print("  ✓ Creating students...")
        students = [
            Student(
                first_name="Liam", last_name="Anderson",
                site_combination_id=1
            ),
            Student(
                first_name="Olivia", last_name="Martinez",
                site_combination_id=2
            ),
            Student(
                first_name="Noah", last_name="Taylor",
                site_combination_id=3
            ),
            Student(
                first_name="Sophia", last_name="Thomas",
                site_combination_id=4
            ),
            Student(
                first_name="Ethan", last_name="Jackson",
                site_combination_id=5
            ),
            Student(
                first_name="Emma", last_name="White",
                site_combination_id=6
            ),
            Student(
                first_name="Mason", last_name="Harris",
                site_combination_id=7
            ),
            Student(
                first_name="Isabella", last_name="Clark",
                site_combination_id=8
            ),
            Student(
                first_name="James", last_name="Lewis",
                site_combination_id=1
            ),
            Student(
                first_name="Mia", last_name="Walker",
                site_combination_id=2
            ),
        ]

        random_first_names = [
            "Amelia", "Ava", "Benjamin", "Caleb", "Chloe", "Daniel", "Elijah",
            "Ella", "Freya", "Grace", "Hannah", "Harper", "Henry", "Jack",
            "Jacob", "Leo", "Lily", "Logan", "Lucas", "Maya", "Oscar",
            "Ruby", "Samuel", "Sienna", "Theo", "William", "Zara"
        ]
        random_last_names = [
            "Adams", "Bailey", "Baker", "Collins", "Cooper", "Edwards", "Evans",
            "Fisher", "Foster", "Green", "Hall", "Hughes", "King", "Lee",
            "Morgan", "Morris", "Parker", "Reed", "Scott", "Turner", "Ward",
            "Wood", "Young"
        ]

        for _ in range(40):
            students.append(
                Student(
                    first_name=random.choice(random_first_names),
                    last_name=random.choice(random_last_names),
                    site_combination_id=random.choice([1, 2, 3]),
                )
            )

        session.add_all(students)
        await session.flush()

        # =============================================================================
        # 6. CLASSES
        # =============================================================================
        print("  ✓ Creating classes...")
        classes = [
            # Elemore Hall (site_combination_id=1)
            Class(class_name="Elemore - Mathematics 9A",
                  staff_id=staff_members[1].staff_id, site_combination_id=1),
            Class(class_name="Elemore - English 10B",
                  staff_id=staff_members[2].staff_id, site_combination_id=1),
            Class(class_name="Elemore - Science 9C",
                  staff_id=staff_members[3].staff_id, site_combination_id=1),

            # Windlestone (site_combination_id=2)
            Class(class_name="Windlestone - Mathematics 10A",
                  staff_id=staff_members[1].staff_id, site_combination_id=2),
            Class(class_name="Windlestone - History 11B",
                  staff_id=staff_members[2].staff_id, site_combination_id=2),
            Class(class_name="Windlestone - PE 9D",
                  staff_id=staff_members[3].staff_id, site_combination_id=2),

            # PACC (site_combination_id=3)
            Class(class_name="PACC - Art 10E",
                  staff_id=staff_members[1].staff_id, site_combination_id=3),
            Class(class_name="PACC - Drama 11F",
                  staff_id=staff_members[2].staff_id, site_combination_id=3),
            Class(class_name="PACC - Music 9G",
                  staff_id=staff_members[3].staff_id, site_combination_id=3),
        ]

        subject_pool = [
            "Maths", "English", "Science", "History", "Geography", "Computing",
            "Design", "Food Tech", "PSHE", "Music", "Drama", "Art"
        ]
        site_labels = {
            1: "Elemore",
            2: "Windlestone",
            3: "PACC",
        }
        teacher_ids = [
            staff_members[1].staff_id,
            staff_members[2].staff_id,
            staff_members[3].staff_id,
        ]

        for site_id in [1, 2, 3]:
            for group in range(4):
                classes.append(
                    Class(
                        class_name=f"{site_labels[site_id]} - {random.choice(subject_pool)} {random.randint(7, 11)}{chr(65 + group)}",
                        staff_id=random.choice(teacher_ids),
                        site_combination_id=site_id,
                    )
                )

        session.add_all(classes)
        await session.flush()

        # =============================================================================
        # 7. CLASS-STUDENT ENROLLMENTS
        # =============================================================================
        print("  ✓ Enrolling students in classes...")
        enrollments = [
            # Elemore Hall classes
            # Elemore Math 9A
            ClassStudent(class_id=classes[0].class_id,
                         student_id=students[0].student_id),
            ClassStudent(class_id=classes[0].class_id,
                         student_id=students[1].student_id),
            ClassStudent(class_id=classes[0].class_id,
                         student_id=students[8].student_id),

            # Elemore English 10B
            ClassStudent(class_id=classes[1].class_id,
                         student_id=students[0].student_id),
            ClassStudent(class_id=classes[1].class_id,
                         student_id=students[2].student_id),
            ClassStudent(class_id=classes[1].class_id,
                         student_id=students[5].student_id),

            # Elemore Science 9C
            ClassStudent(class_id=classes[2].class_id,
                         student_id=students[1].student_id),
            ClassStudent(class_id=classes[2].class_id,
                         student_id=students[8].student_id),

            # Windlestone classes
            # Windlestone Math 10A
            ClassStudent(class_id=classes[3].class_id,
                         student_id=students[1].student_id),
            ClassStudent(class_id=classes[3].class_id,
                         student_id=students[3].student_id),
            ClassStudent(class_id=classes[3].class_id,
                         student_id=students[9].student_id),

            # Windlestone History 11B
            ClassStudent(class_id=classes[4].class_id,
                         student_id=students[3].student_id),
            ClassStudent(class_id=classes[4].class_id,
                         student_id=students[4].student_id),
            ClassStudent(class_id=classes[4].class_id,
                         student_id=students[6].student_id),

            # Windlestone PE 9D
            ClassStudent(class_id=classes[5].class_id,
                         student_id=students[1].student_id),
            ClassStudent(class_id=classes[5].class_id,
                         student_id=students[9].student_id),

            # PACC classes
            # PACC Art 10E
            ClassStudent(class_id=classes[6].class_id,
                         student_id=students[2].student_id),
            ClassStudent(class_id=classes[6].class_id,
                         student_id=students[4].student_id),
            ClassStudent(class_id=classes[6].class_id,
                         student_id=students[7].student_id),

            # PACC Drama 11F
            ClassStudent(class_id=classes[7].class_id,
                         student_id=students[5].student_id),
            ClassStudent(class_id=classes[7].class_id,
                         student_id=students[6].student_id),

            # PACC Music 9G
            ClassStudent(class_id=classes[8].class_id,
                         student_id=students[2].student_id),
            ClassStudent(class_id=classes[8].class_id,
                         student_id=students[7].student_id),
            ClassStudent(class_id=classes[8].class_id,
                         student_id=students[9].student_id),
        ]

        existing_enrollment_pairs = {
            (enrollment.class_id, enrollment.student_id)
            for enrollment in enrollments
        }

        classes_by_site = {
            1: [cls for cls in classes if cls.site_combination_id == 1],
            2: [cls for cls in classes if cls.site_combination_id == 2],
            3: [cls for cls in classes if cls.site_combination_id == 3],
        }

        for student in students:
            candidate_classes = classes_by_site.get(
                student.site_combination_id, [])
            if not candidate_classes:
                candidate_classes = classes

            class_count = random.randint(2, min(4, len(candidate_classes)))
            for selected_class in random.sample(candidate_classes, k=class_count):
                pair = (selected_class.class_id, student.student_id)
                if pair in existing_enrollment_pairs:
                    continue
                enrollments.append(
                    ClassStudent(
                        class_id=selected_class.class_id,
                        student_id=student.student_id,
                    )
                )
                existing_enrollment_pairs.add(pair)

        session.add_all(enrollments)
        await session.flush()

        # =============================================================================
        # 8. REGISTERS (Attendance sessions)
        # =============================================================================
        print("  ✓ Creating attendance registers...")
        today = date.today()
        registers = []

        # Create registers for the past 10 school days
        for i in range(10):
            current_date = today - timedelta(days=i)
            if current_date.weekday() < 5:  # Skip weekends (5=Saturday, 6=Sunday)
                for cls in classes:
                    reg = Register(register_date=current_date,
                                   class_id=cls.class_id)
                    registers.append(reg)

        session.add_all(registers)
        await session.flush()

        # =============================================================================
        # 9. ATTENDANCE RECORDS
        # =============================================================================
        print("  ✓ Recording attendance...")
        attendance_records_count = 0
        for register in registers:
            # Get all students in this class (async-friendly query)
            result = await session.execute(
                select(ClassStudent).where(
                    ClassStudent.class_id == register.class_id)
            )
            class_students = result.scalars().all()

            for cs in class_students:
                # Randomly mark students as present/absent by session
                am_present = random.choices(
                    [True, False], weights=[0.9, 0.1])[0]
                pm_present = random.choices(
                    [True, False], weights=[0.9, 0.1])[0]
                on_site = am_present or pm_present
                if not on_site:
                    note = random.choice([
                        "Sick leave",
                        "Medical appointment",
                        "Family appointment",
                        "Transport issue",
                    ])
                elif random.random() < 0.06:
                    note = random.choice([
                        "Arrived late AM",
                        "Left early PM",
                        "Temporary offsite visit",
                    ])
                else:
                    note = None

                attendance = Attendance(
                    register_id=register.register_id,
                    student_id=cs.student_id,
                    am_present=am_present,
                    pm_present=pm_present,
                    on_site=on_site,
                    note=note
                )
                session.add(attendance)
                attendance_records_count += 1

        await session.flush()

        # =============================================================================
        # 10. INCIDENTS
        # =============================================================================
        print("  ✓ Creating incidents...")
        incidents = [
            # ELEMORE HALL INCIDENTS
            Incident(
                duty_coordinator_id=staff_members[0].staff_id,  # Alice
                incident_date=today - timedelta(days=2),
                class_id=classes[0].class_id,  # Elemore Math
                action="Student was late to Elemore Hall class",
                note="Arrived 10 minutes after register at Elemore",
                action_taken="Verbal warning given",
                outcome="Student apologized and settled"
            ),
            Incident(
                duty_coordinator_id=staff_members[0].staff_id,
                incident_date=today - timedelta(days=5),
                class_id=classes[1].class_id,  # Elemore English
                action="Disruptive behavior in Elemore Hall English class",
                note="Talking during instruction without permission",
                action_taken="Sent to think about behavior",
                outcome="Improved after discussion"
            ),
            Incident(
                duty_coordinator_id=staff_members[0].staff_id,
                incident_date=today - timedelta(days=3),
                class_id=classes[2].class_id,  # Elemore Science
                action="Late homework submission from Elemore Hall student",
                note="Assignment submitted without prior notification",
                action_taken="Discussed expectations",
                outcome="Student will submit on time going forward"
            ),
            # WINDLESTONE INCIDENTS
            Incident(
                duty_coordinator_id=staff_members[1].staff_id,  # Bob
                incident_date=today - timedelta(days=4),
                class_id=classes[3].class_id,  # Windlestone Math
                action="Windlestone student forgot PE uniform",
                note="At Windlestone during Math class",
                action_taken="Allowed to participate in alternative activity",
                outcome="Student brought uniform next day"
            ),
            Incident(
                duty_coordinator_id=staff_members[2].staff_id,  # Carol
                incident_date=today - timedelta(days=1),
                class_id=classes[4].class_id,  # Windlestone History
                action="Windlestone History class - minor conflict between students",
                note="Two students disagreed during group work",
                action_taken="Separated groups and mediated discussion",
                outcome="Agreement reached, completed assignment together"
            ),
            Incident(
                duty_coordinator_id=staff_members[1].staff_id,
                incident_date=today,
                class_id=classes[5].class_id,  # Windlestone PE
                action="Windlestone PE injury - minor twisted ankle",
                note="Student twisted ankle during Windlestone PE class",
                action_taken="First aid applied, parent contacted",
                outcome="Student sent home for observation"
            ),
            # PACC INCIDENTS
            Incident(
                duty_coordinator_id=staff_members[2].staff_id,  # Carol
                incident_date=today - timedelta(days=6),
                class_id=classes[6].class_id,  # PACC Art
                action="PACC Art student used materials without permission",
                note="Expensive art supplies used incorrectly at PACC",
                action_taken="Discussed proper procedure and respect for materials",
                outcome="Student agreed to be more careful, supervised going forward"
            ),
            Incident(
                duty_coordinator_id=staff_members[3].staff_id,  # David
                incident_date=today - timedelta(days=2),
                class_id=classes[7].class_id,  # PACC Drama
                action="PACC Drama student left class without permission",
                note="Student walked out during PACC Drama rehearsal",
                action_taken="Called parents and discussed frustration",
                outcome="Resolved - student returned and completed rehearsal"
            ),
            Incident(
                duty_coordinator_id=staff_members[2].staff_id,
                incident_date=today - timedelta(days=4),
                class_id=classes[8].class_id,  # PACC Music
                action="PACC Music equipment damage - drum stand broken",
                note="Drum stand damaged during PACC Music session",
                action_taken="Reported to maintenance, equipment secured",
                outcome="Stand repaired - incident logged for records"
            ),
        ]

        random_actions = [
            "Late arrival to lesson",
            "Refused to engage in activity",
            "Minor disruption during class",
            "Positive contribution in group task",
            "Peer conflict resolved by staff",
            "Forgot required classroom equipment",
            "Temporary offsite movement",
            "Low-level defiance to instruction",
        ]
        random_outcomes = [
            "Resolved",
            "Pending",
            "Monitored",
            "Follow-up required",
            "Resolved with parent contact",
        ]

        for _ in range(28):
            selected_class = random.choice(classes)
            incident_date = today - timedelta(days=random.randint(0, 20))
            incidents.append(
                Incident(
                    duty_coordinator_id=random.choice(
                        staff_members[:4]).staff_id,
                    incident_date=incident_date,
                    class_id=selected_class.class_id,
                    action=random.choice(random_actions),
                    note=random.choice([
                        "Observed and recorded by duty coordinator",
                        "Short intervention completed in class",
                        "Logged for pastoral follow-up",
                        "No additional concerns at end of lesson",
                    ]),
                    action_taken=random.choice([
                        "Verbal reminder",
                        "Restorative conversation",
                        "Parent contacted",
                        "Referred to pastoral team",
                    ]),
                    outcome=random.choice(random_outcomes),
                )
            )

        session.add_all(incidents)
        await session.flush()

        # =============================================================================
        # 11. STAFF-INCIDENT LINKS
        # =============================================================================
        print("  ✓ Linking staff to incidents...")
        staff_incidents = [
            StaffIncident(
                # Bob
                staff_id=staff_members[1].staff_id, incident_id=incidents[0].incident_id),
            StaffIncident(
                # Carol
                staff_id=staff_members[2].staff_id, incident_id=incidents[1].incident_id),
            StaffIncident(
                staff_id=staff_members[1].staff_id, incident_id=incidents[2].incident_id),
        ]

        existing_staff_incident_pairs = {
            (item.staff_id, item.incident_id) for item in staff_incidents
        }

        for incident in incidents[3:]:
            involved_staff = random.sample(
                staff_members[1:], k=random.randint(1, 2))
            for staff_member in involved_staff:
                pair = (staff_member.staff_id, incident.incident_id)
                if pair in existing_staff_incident_pairs:
                    continue
                staff_incidents.append(
                    StaffIncident(
                        staff_id=staff_member.staff_id,
                        incident_id=incident.incident_id,
                    )
                )
                existing_staff_incident_pairs.add(pair)

        session.add_all(staff_incidents)
        await session.flush()

        # =============================================================================
        # 12. STUDENT-INCIDENT LINKS
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
                time=today - timedelta(days=5) +
                timedelta(hours=10, minutes=30),
                returned=True,
                duration_minutes=10,
                note="Disruptive behavior"
            ),
            StudentIncident(
                student_id=students[4].student_id,
                incident_id=incidents[1].incident_id,
                time=today - timedelta(days=5) +
                timedelta(hours=10, minutes=30),
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

        class_students_map = {}
        for enrollment in enrollments:
            class_students_map.setdefault(
                enrollment.class_id, []).append(enrollment.student_id)

        existing_student_incident_pairs = {
            (item.student_id, item.incident_id) for item in student_incidents
        }

        for incident in incidents:
            if incident.class_id is None:
                continue

            candidate_student_ids = class_students_map.get(
                incident.class_id, [])
            if not candidate_student_ids:
                continue

            link_count = random.randint(1, min(3, len(candidate_student_ids)))
            linked_students = random.sample(
                candidate_student_ids, k=link_count)

            for student_id in linked_students:
                pair = (student_id, incident.incident_id)
                if pair in existing_student_incident_pairs:
                    continue

                incident_time = datetime.combine(
                    incident.incident_date,
                    datetime.min.time(),
                ) + timedelta(hours=random.randint(8, 15), minutes=random.choice([0, 10, 20, 30, 40, 50]))

                student_incidents.append(
                    StudentIncident(
                        student_id=student_id,
                        incident_id=incident.incident_id,
                        time=incident_time,
                        returned=random.choice([True, True, True, False]),
                        duration_minutes=random.choice([0, 5, 10, 15, 20, 30]),
                        note=random.choice([
                            "Discussed with staff",
                            "Short break then returned",
                            "Pastoral support requested",
                            "No further action required",
                        ]),
                    )
                )
                existing_student_incident_pairs.add(pair)

        session.add_all(student_incidents)
        await session.flush()

        # Commit all changes
        await session.commit()

        print("\n✅ Database seeded successfully!")
        print(f"\n📊 Summary:")
        print(f"   • {len(sites)} site combinations")
        print(f"   • {len(access_levels)} access levels")
        print(f"   • {len(staff_members)} staff members")
        print(f"   • {len(users)} user accounts")
        print(f"   • {len(students)} students")
        print(f"   • {len(classes)} classes")
        print(f"   • {len(enrollments)} class enrollments")
        print(f"   • {len(registers)} attendance registers")
        print(f"   • {attendance_records_count} attendance rows")
        print(f"   • {len(incidents)} incidents")
        print(f"   • {len(staff_incidents)} staff-incident links")
        print(f"   • {len(student_incidents)} student-incident links")
        print(f"\n📝 Test Accounts:")
        print(f"   Admin:   alice.johnson@school.edu / admin123")
        print(f"   Teacher: bob.smith@school.edu / teacher123")
        print(f"   Teacher: carol.davis@school.edu / teacher123")
        print(f"   Staff:   emma.brown@school.edu / staff123")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(seed_database())
