# Internship Portal

A professional internship management system built with Flutter and Python FastAPI backend.

## Features

### Admin Dashboard
1. Manage internships (add/delete/update) with availability status
2. Manage tasks related to internships and assign them to internees
3. View all internees and their progress
4. Approve or reject internship requests
5. Monitor internee progress with detailed status

### Internee Dashboard
1. View and apply for available internships
2. View assigned tasks
3. Upload documents and submissions for tasks
4. Track progress and status

## Tech Stack

- **Frontend**: Flutter with Material Design
- **Backend**: Python FastAPI
- **Database**: SQL Server
- **Authentication**: JWT with secure storage
- **File Storage**: Local file system with structured organization

## Setup Instructions

### Prerequisites

1. Install Flutter SDK
2. Install Python 3.8+
3. Install SQL Server
4. Install VS Code (recommended)

### Database Setup

1. Open SQL Server Management Studio
2. Connect to your SQL Server instance
3. Run the `backend/schema.sql` script to create the 'intern' database and tables

### Backend Setup

1. Navigate to the backend folder:
   ```bash
   cd backend
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Update the database connection string in `main.py`

4. Run the FastAPI server:
   ```bash
   uvicorn main:app --reload
   ```

### Frontend Setup

1. Navigate to the project root
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Update the API base URL in `lib/services/constants.dart` if needed

4. Run the app:
   ```bash
   flutter run
   ```

## Default Admin Account

- Username: admin
- Password: admin123

## API Documentation

Once the backend server is running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Project Structure

```
internship_portal/
├── backend/
│   ├── main.py              # FastAPI application
│   └── schema.sql           # Database schema
├── lib/
│   ├── models/              # Data models
│   ├── services/            # API services
│   ├── screens/             # UI screens
│   ├── widgets/             # Reusable widgets
│   └── main.dart            # Entry point
└── pubspec.yaml             # Flutter dependencies
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a pull request

## License

This project is licensed under the MIT License.
