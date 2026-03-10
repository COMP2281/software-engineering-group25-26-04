# Software Engineering Project

Full-stack application with Flutter frontend and FastAPI backend.

## Prerequisites

- **Python 3.8+**
- **Flutter SDK** ([Install instructions](https://docs.flutter.dev/get-started/install))
- **Git**
- **IDE**: VS Code with Flutter and Python extensions (recommended)

---

## 🚀 Quick Start

### 1️⃣ Clone the Repository

```bash
git clone <repository-url>
cd software-engineering-group25-26-04
```

---

## 🔗 Run Backend + Database + Frontend (Connected)

Use two terminals so both services run at the same time.

### Terminal 1 — Backend (with venv)

```bash
cd backend

# Mac/Linux
source venv/bin/activate

# Windows
# venv\Scripts\activate

# (Optional) reset + populate local SQLite database with test data
python seed_database.py

# Start API server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Terminal 2 — Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

### Verify they are connected

1. Open API docs at `http://localhost:8000/docs`
2. Open the app and log in
3. Dashboard should load classes/incidents from the backend API

### Quick testing account

If you seeded with `python seed_database.py`, test accounts exist:

**Admin Account:**
- Email: `alice.johnson@school.edu`
- Password: `admin123`
- Access: Admin Panel with full management features

**Regular User Account:**
- Email: *(blank)*
- Password: *(blank)*
- Access: Dashboard only

Leave email/password fields empty and press **Sign In** for the default user.

---

## 🔧 Backend Setup (FastAPI)

### First Time Setup

1. **Navigate to backend folder:**
   ```bash
   cd backend
   ```

2. **Create virtual environment:**
   ```bash
   python -m venv venv
   ```

3. **Activate virtual environment:**
   
   **Windows:**
   ```bash
   venv\Scripts\activate
   ```
   
   **Mac/Linux:**
   ```bash
   source venv/bin/activate
   ```

4. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

5. **Set up environment variables:**
   
   The `.env` file is already configured for local development with SQLite. No additional setup needed!

6. **Run database migrations:**
   ```bash
   alembic upgrade head
   ```

### Running the Backend

```bash
uvicorn app.main:app --reload
```

The API will be available at:
- **API**: http://localhost:8000
- **Interactive API Docs**: http://localhost:8000/docs
- **Alternative Docs**: http://localhost:8000/redoc <!-- cSpell:ignore redoc -->

### Daily Development

**Activate virtual environment** before working:
```bash
# Windows
venv\Scripts\activate

# Mac/Linux
source venv/bin/activate
```

**Deactivate** when done:
```bash
deactivate
```

---

## 📱 Frontend Setup (Flutter)

### First Time Setup

1. **Navigate to frontend folder:**
   ```bash
   cd frontend
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify Flutter installation:**
   ```bash
   flutter doctor
   ```
   *(Fix any issues reported)*

### Running the Frontend

1. **List available devices:**
   ```bash
   flutter devices
   ```

2. **Run the app:**
   
   **On Chrome (Web):**
   ```bash
   flutter run -d chrome
   ```
   
   **On Windows:**
   ```bash
   flutter run -d windows
   ```
   
   **On Android Emulator:**
   ```bash
   flutter run -d <device-id>
   ```

3. **Hot reload:** Press `r` in the terminal to hot reload changes
   
4. **Hot restart:** Press `R` for full restart

---

## 📁 Project Structure

```
.
├── backend/                  # FastAPI Backend
│   ├── app/
│   │   ├── main.py          # FastAPI app entry point
│   │   ├── models.py        # Database models
│   │   ├── schemas.py       # API request/response schemas
│   │   ├── database.py      # Database configuration
│   │   └── routes/          # API endpoints
│   ├── alembic/             # Database migrations
│   ├── requirements.txt     # Python dependencies
│   ├── .env                 # Environment variables
│   └── Dockerfile           # Docker configuration
│
├── frontend/                # Flutter Frontend
│   ├── lib/
│   │   ├── main.dart        # Flutter app entry point
│   │   ├── login_page.dart  # Login and authentication
│   │   ├── dashboard_page.dart
│   │   ├── admin_page.dart  # Admin panel hub
│   │   ├── admin_user_management_page.dart   # Staff management
│   │   ├── admin_class_management_page.dart  # Class management
│   │   ├── admin_import_students_page.dart   # CSV bulk import
│   │   ├── api_client.dart  # HTTP client
│   │   └── auth_service.dart # Authentication service
│   ├── pubspec.yaml         # Flutter dependencies
│   └── android/, ios/, web/ # Platform-specific code
│
└── .gitignore               # Git ignore rules
```

---

## 🔨 Development Workflow

### Backend Changes

1. Activate virtual environment
2. Make code changes
3. If models changed: Create migration
   ```bash
   alembic revision --autogenerate -m "description"
   alembic upgrade head
   ```
4. Test API at http://localhost:8000/docs

### Frontend Changes

1. Make code changes in `lib/`
2. Press `r` to hot reload
3. Test on multiple devices if needed

---

## 👨‍💼 Admin Panel Features

Admin users (role: "Admin") have access to a full management interface:

### 1. **Student Bulk Import**
- Upload CSV files with student data (First Name, Last Name, Class, Site)
- Preview all rows before import with validation status
- Auto-creates classes if they don't exist
- Assigns imported students to their classes

**Test CSV Format:**
```csv
First Name,Second Name,Class,Site
John,Smith,Math 9A,Elemore
Emma,Johnson,English 10B,Windlestone
Oliver,Williams,Science 9C,PACC
```

### 2. **Staff/User Management**
- View all staff members
- Create new staff accounts with password assignment
- Edit staff:
  - Name and email
  - Role assignment (Admin, Teacher, Staff)
  - Site visibility access permissions
  - Password management
- Assign sites: Elemore Hall, Windlestone, PACC

### 3. **Class Management**
- View all classes
- Create and edit classes:
  - Class name
  - Teacher assignment
  - Site assignment
  - Manage enrolled students
- Delete classes
- View student rosters with names

### Admin Panel Layout
The admin page displays:
- **Quick Actions**: Import Students button
- **Staff Members**: Preview list (first 5) with "View All" link
- **Classes**: Preview list (first 5) with "View All" link
- **Dashboard**: Button to access the main user dashboard

---

## 🐛 Troubleshooting

### Backend Issues

- **Port already in use:**
  ```bash
  uvicorn app.main:app --reload --port 8001
  ```

- **Missing packages:**
  ```bash
  pip install -r requirements.txt
  ```

- **Database errors:**
  ```bash
  alembic downgrade -1
  alembic upgrade head
  ```

### Frontend Issues

- **Dependencies not installing:**
  ```bash
  flutter pub upgrade
  flutter clean
  flutter pub get
  ```

- **Build errors:**
  ```bash
  flutter clean
  flutter pub get
  flutter run
  ```

- **Device not detected:**
  ```bash
  flutter devices
  # Follow flutter doctor recommendations
  ```

---

## 📝 Important Notes

- **Never commit** `.env` files or `venv/` folders
- **Database file** (`app.db`) is git-ignored
- **Virtual environment** should be created locally by each developer
- **Flutter packages** will be downloaded via `flutter pub get`

