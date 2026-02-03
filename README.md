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
│   │   ├── dashboard_page.dart
│   │   ├── logs_page.dart
│   │   └── analytics_page.dart
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

