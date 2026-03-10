# AI Coding Assistant Instructions

## Architecture Overview

This is a full-stack school management system with:

- **Backend**: FastAPI (Python) REST API with SQLAlchemy ORM and JWT authentication
- **Frontend**: Flutter (Dart) web/mobile app
- **Database**: SQLite for development, PostgreSQL for production
- **Key Entities**: Sites, Staff, Students, Classes, Attendance, Incidents

## Backend Patterns

- **Routes**: Organized by entity in `app/routes/` - each file handles CRUD for one domain
- **Models**: SQLAlchemy async models in `app/models.py` with relationships (ForeignKey, back_populates)
- **Auth**: JWT tokens via `app/utils/auth.py`, bcrypt password hashing, OAuth2 flow
- **Database**: Async SQLAlchemy sessions, Alembic migrations for schema changes
- **Config**: Pydantic settings from `.env` file

## Frontend Patterns

- **API Client**: Centralized `ApiClient` class handles JWT headers and 401 redirects
- **Config**: `AppConfig.apiUrl` adapts URLs (localhost for web, 10.0.2.2 for Android emulator)
- **State Management**: Stateful widgets with polling timers for data refresh
- **Navigation**: Auto-redirect to `LoginPage` on auth failure

## Development Workflows

- **Backend Setup**: `cd backend && python -m venv venv && venv\Scripts\activate && pip install -r requirements.txt`
- **Backend Run**: `uvicorn app.main:app --reload --host 0.0.0.0 --port 8000`
- **Frontend Setup**: `cd frontend && flutter pub get`
- **Frontend Run**: `flutter run -d chrome` (web) or `flutter run -d windows` (desktop)
- **Database**: `alembic upgrade head` after model changes, `python seed_database.py` for test data

## Key Files

- `backend/app/main.py`: FastAPI app setup, CORS, route registration
- `backend/app/models.py`: Database schema with relationships
- `backend/app/routes/__init__.py`: Route registry (auth public, others protected)
- `frontend/lib/api_client.dart`: HTTP wrapper with auth headers
- `frontend/lib/config.dart`: Environment-specific API URLs

## Common Tasks

- **Add Entity**: Create model in `models.py`, route in `routes/`, update `routes/__init__.py`
- **Database Changes**: Modify models, run `alembic revision --autogenerate -m "msg"`
- **API Calls**: Use `ApiClient.get/post/put/delete()` with context for auth redirects
- **Auth Check**: All protected routes use `Depends(get_current_user)` dependency</content>
  <parameter name="filePath">c:\Users\harry\Documents\git\software-engineering-group25-26-04\.github\copilot-instructions.md
