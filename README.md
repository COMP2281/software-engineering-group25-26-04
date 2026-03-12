# Software Engineering Project

## Backend Setup

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

5. **Run database migrations:**
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

## Frontend Setup

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

5. **Login Details:** username: admin password: admin