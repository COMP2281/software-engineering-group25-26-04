# Frontend - Flutter School Management Application

A Flutter web/mobile application for school management with role-based access control.

## Features

- **Authentication**: Login with JWT-based session tokens
- **Dashboard**: View and manage school operations
- **Admin Panel** (Admin role only):
  - Bulk student import from CSV
  - Staff management (create, edit, assign roles and sites)
  - Class management (create, edit, delete, manage enrollments)
- **Role-Based Access**: Different features for Admin, Teacher, and Staff roles

## Getting Started

### Prerequisites

- Flutter SDK 3.0+ ([Install here](https://docs.flutter.dev/get-started/install))
- Backend API running on `http://localhost:8000` (see main project README)

### Setup

1. **Install dependencies:**

   ```bash
   flutter pub get
   ```

2. **Verify Flutter installation:**

   ```bash
   flutter doctor
   ```

### Running

**Web (Chrome):**

```bash
flutter run -d chrome
```

**Windows:**

```bash
flutter run -d windows
```

**Android Emulator:**

```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

### Hot Reload

- Press `r` to hot reload (fast refresh during development)
- Press `R` for full restart
- Press `q` to quit

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── login_page.dart               # Authentication
├── dashboard_page.dart           # Main user interface
├── admin_page.dart               # Admin panel hub
├── admin_user_management_page.dart   # Staff management
├── admin_class_management_page.dart  # Class management
├── admin_import_students_page.dart   # CSV import
├── api_client.dart               # HTTP client for backend API
├── auth_service.dart             # Authentication logic
└── config.dart                   # App configuration
```

## API Integration

The app communicates with a FastAPI backend:

- Base URL: `http://localhost:8000` (configurable in `config.dart`)
- Authentication: JWT bearer tokens stored locally
- All secure endpoints require authentication headers

## Key Dependencies

- `http`: HTTP client for API calls
- `google_fonts`: Typography (Inter font for dashboard UI)
- `file_picker`: CSV file selection for imports

## Testing

### Test Accounts

After seeding the database with `python seed_database.py`:

**Admin Account:**

```
Email: alice.johnson@school.edu
Password: admin123
```

**Default User:**

```
Email: (leave blank)
Password: (leave blank)
```

## Troubleshooting

### Dependencies not installing

```bash
flutter pub clean
flutter pub get
```

### Build errors

```bash
flutter clean
flutter pub get
flutter run
```

### Device not detected

```bash
flutter doctor
flutter devices
```

### API connection issues

- Ensure backend is running on `http://localhost:8000`
- Check `config.dart` for correct API URL
- Verify network connectivity

## Development Notes

- All UI components use Material Design 3
- State management via `StatefulWidget` for page-level state
- API calls handled through `ApiClient` class with error handling
- Authentication managed by `AuthService` singleton
