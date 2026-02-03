[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/B06_mcpV)

## Prerequisites

Install the following:
- Flutter VSCode extension (or equivalent for your IDE)
- Python 3.14 or later
- Language Support for Java(TM) by Red Hat VSCode extension
- **PostgreSQL** (see Database Setup below)

## Database Setup (PostgreSQL)

### 1. Install PostgreSQL

**Windows:**
1. Download from https://www.postgresql.org/download/windows/
2. Run the installer (remember your password for the 'postgres' user!)
3. Use default port 5432
4. pgAdmin will be installed automatically (GUI for managing the database)

**macOS:**
```bash
brew install postgresql
brew services start postgresql
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

### 2. Create the Database

**Using pgAdmin (Windows - Recommended):**
1. Open pgAdmin 4 (search in Start menu)
2. Connect to your local PostgreSQL server
3. Right-click "Databases" → "Create" → "Database"
4. Name it `myapp_db` (or whatever you set in .env)
5. Click "Save"

**Using Command Line:**
```bash
# Windows (open Command Prompt as Admin):
psql -U postgres
CREATE DATABASE myapp_db;
\q

# Mac/Linux:
sudo -u postgres psql
CREATE DATABASE myapp_db;
\q
```

### 3. Configure Environment Variables

1. Navigate to the `backend` folder
2. Copy `.env.example` to `.env`
3. Edit `.env` with your PostgreSQL credentials:
   ```
   DB_USER=postgres
   DB_PASSWORD=your_postgres_password
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=myapp_db
   ```

## Backend Setup

### First Time Setup

**Windows (PowerShell):**
```powershell
cd backend
.\setup.ps1
```

**macOS/Linux:**
```bash
cd backend
chmod +x setup.sh
./setup.sh
```

This will create a virtual environment and install all dependencies.

### Initialize the Database Tables

After setting up the backend, run:
```powershell
cd backend
.\venv\Scripts\Activate.ps1
python init_db.py
```

This creates all the database tables defined in your models.

### Run the API Server

**Option 1 - Using the helper script:**
```powershell
cd backend
.\run.ps1
```

**Option 2 - Manual:**
```powershell
cd backend
.\venv\Scripts\Activate.ps1
uvicorn app.main:app --reload --port 8000
```

The API will be available at:
- **API**: http://localhost:8000
- **Interactive Docs**: http://localhost:8000/docs (try out endpoints here!)
- **Alternative Docs**: http://localhost:8000/redoc

### Daily Development

**Windows (PowerShell):**
```powershell
cd backend
.\venv\Scripts\Activate.ps1
```

**macOS/Linux:**
```bash
cd backend
source venv/bin/activate
```

To deactivate the virtual environment when you're done:
```bash
deactivate
```

### Troubleshooting

- If you get a script execution error on Windows, run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- If packages are missing, run `pip install -r requirements.txt` after activating the virtual environment
- Each team member should create their own virtual environment - do NOT commit the `venv/` folder to git
- **Database connection errors**: Make sure PostgreSQL is running and your `.env` file is configured correctly
- **Port already in use**: Another process is using port 8000. Either stop it or use a different port: `uvicorn app.main:app --reload --port 8001`

## Project Structure

```
backend/
├── app/
│   ├── __init__.py         # Package initializer
│   ├── main.py             # FastAPI application entry point
│   ├── config.py           # Configuration and settings
│   ├── database.py         # Database connection setup
│   ├── models.py           # Database models (tables) - EDIT THIS!
│   ├── schemas.py          # Pydantic schemas (API data shapes)
│   └── routes/
│       ├── __init__.py     # Routes package
│       ├── users.py        # User API endpoints (example)
│       └── items.py        # Item API endpoints (example)
├── .env.example            # Example environment variables
├── .env                    # YOUR environment variables (don't commit!)
├── requirements.txt        # Python dependencies
├── init_db.py              # Database initialization script
├── run.ps1                 # Helper script to run the server
└── setup.ps1               # Setup script
```

## Adding Your Own Database Tables

1. **Define the model** in `backend/app/models.py`:
   ```python
   class YourTable(Base):
       __tablename__ = "your_table_name"
       id: Mapped[int] = mapped_column(Integer, primary_key=True)
       # Add your columns...
   ```

2. **Create schemas** in `backend/app/schemas.py`:
   ```python
   class YourTableCreate(BaseModel):
       # Fields for creating records
   
   class YourTableResponse(BaseModel):
       # Fields returned in API responses
   ```

3. **Create routes** in `backend/app/routes/your_routes.py`:
   ```python
   router = APIRouter(prefix="/api/your-endpoint", tags=["YourTag"])
   
   @router.get("/")
   async def get_all(...):
       # Your logic
   ```

4. **Register the router** in `backend/app/routes/__init__.py`

5. **Run** `python init_db.py` to create the new tables

