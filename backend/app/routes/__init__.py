# =============================================================================
# ROUTES REGISTRY
# =============================================================================
# Import all your route files here to register them with the app.
# =============================================================================

from app.routes.access_levels import router as access_levels_router
from app.routes.sites import router as sites_router
from app.routes.staff import router as staff_router
from app.routes.students import router as students_router
from app.routes.users import router as users_router
from app.routes.classes import router as classes_router
from app.routes.class_students import router as class_students_router
from app.routes.registers import router as registers_router
from app.routes.attendance import router as attendance_router
from app.routes.incidents import router as incidents_router
from app.routes.staff_incidents import router as staff_incidents_router
from app.routes.student_incidents import router as student_incidents_router

all_routers = [
    access_levels_router,
    sites_router,
    staff_router,
    students_router,
    users_router,
    classes_router,
    class_students_router,
    registers_router,
    attendance_router,
    incidents_router,
    staff_incidents_router,
    student_incidents_router,
]