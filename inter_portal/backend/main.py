from fastapi import FastAPI, HTTPException, Depends, status, File, UploadFile, Body
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from passlib.context import CryptContext
from datetime import datetime, timedelta
from typing import Optional, List
from pydantic import BaseModel
import pyodbc
import jwt
from pathlib import Path
import shutil
import os

# Import Firebase Admin SDK
import firebase_admin
from firebase_admin import auth as firebase_auth, credentials

from fastapi.staticfiles import StaticFiles

app = FastAPI()

# Initialize Firebase Admin SDK
cred = credentials.Certificate("c:/Users/PMLS/Downloads/rentelease-77e8b-firebase-adminsdk-fbsvc-b0425f1ea8.json")
firebase_admin.initialize_app(cred)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Database connection
def get_db_connection():
    conn = pyodbc.connect(
       "DRIVER={ODBC Driver 17 for SQL Server};"
       "SERVER=DESKTOP-8BL3MIG\\SQLEXPRESS;"
       "DATABASE=intern2;"
       "Trusted_Connection=yes;"
    )
    return conn

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# JWT settings
SECRET_KEY = "JKH7FrzvIAMgQqZp8LLO4R6X5N96nZn7r5me1Te-z9Q"  
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# Database Schema Creation
def create_database_schema():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Users table (for both admin and internees)
    cursor.execute('''
        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' AND xtype='U')
        CREATE TABLE Users (
        UserId INT PRIMARY KEY IDENTITY(1,1),
		Name VARCHAR(100) NOT NULL,
		FirebaseUID VARCHAR(100) UNIQUE NOT NULL,
        Username VARCHAR(50) UNIQUE NOT NULL,
        Password VARCHAR(100) NULL,
        Email VARCHAR(100) UNIQUE NOT NULL,
        Role VARCHAR(10) NOT NULL,  -- 'admin' or 'internee'
        CreatedAt DATETIME DEFAULT GETDATE()
        )
    ''')

    # Internships table
    cursor.execute('''
        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Internships' AND xtype='U')
        CREATE TABLE Internships (
            InternshipId INT PRIMARY KEY IDENTITY(1,1),
            Title VARCHAR(100) NOT NULL,
            Description TEXT,
            Status VARCHAR(20) NOT NULL,  -- 'available' or 'not available'
            CreatedBy INT FOREIGN KEY REFERENCES Users(UserId),
            CreatedAt DATETIME DEFAULT GETDATE()
        )
    ''')

    # Tasks table
    cursor.execute('''
        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Tasks' AND xtype='U')
        CREATE TABLE Tasks (
            TaskId INT PRIMARY KEY IDENTITY(1,1),
            InternshipId INT FOREIGN KEY REFERENCES Internships(InternshipId),
            Title VARCHAR(100) NOT NULL,
            Description TEXT,
            DueDate DATETIME,
            CreatedBy INT FOREIGN KEY REFERENCES Users(UserId),
            CreatedAt DATETIME DEFAULT GETDATE()
        )
    ''')

    # InternshipApplications table
    cursor.execute('''
        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='InternshipApplications' AND xtype='U')
        CREATE TABLE InternshipApplications (
            ApplicationId INT PRIMARY KEY IDENTITY(1,1),
            InternshipId INT FOREIGN KEY REFERENCES Internships(InternshipId),
            InterneeId INT FOREIGN KEY REFERENCES Users(UserId),
            Status VARCHAR(20) NOT NULL,  -- 'pending', 'approved', 'rejected'
            AppliedAt DATETIME DEFAULT GETDATE()
        )
    ''')

    # TaskAssignments table
    cursor.execute('''
        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='TaskAssignments' AND xtype='U')
        CREATE TABLE TaskAssignments (
            AssignmentId INT PRIMARY KEY IDENTITY(1,1),
            TaskId INT FOREIGN KEY REFERENCES Tasks(TaskId),
            InterneeId INT FOREIGN KEY REFERENCES Users(UserId),
            Status VARCHAR(20) NOT NULL,  -- 'pending', 'completed', 'in_progress'
            SubmissionPath VARCHAR(255),
            SubmittedAt DATETIME,
            CreatedAt DATETIME DEFAULT GETDATE()
        )
    ''')

    conn.commit()
    conn.close()

# Pydantic models for request/response
class UserBase(BaseModel):
    username: str
    email: str
    role: str

class UserCreate(UserBase):
    password: str

class User(UserBase):
    user_id: int
    created_at: datetime
    class Config:
        from_attributes = True

class InternshipBase(BaseModel):
    title: str
    description: str
    status: str

class InternshipCreate(InternshipBase):
    pass

class Internship(InternshipBase):
    internship_id: int
    created_by: int
    created_at: datetime
    class Config:
        from_attributes = True

class TaskBase(BaseModel):
    title: str
    description: str
    internship_id: int
    due_date: Optional[datetime]

class TaskCreate(TaskBase):
    pass

class Task(TaskBase):
    task_id: int
    created_at: datetime
    created_by: Optional[int] = None  # Add this
    status: Optional[str] = None
    submission_path: Optional[str] = None
    class Config:
        from_attributes = True

# Helper functions
def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def get_current_user(token: str = Depends(oauth2_scheme)):
    conn = None
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        firebase_uid: str = payload.get("firebase_uid")
        if firebase_uid is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, 
                detail="Invalid authentication credentials"
            )

        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT UserId, Username, Email, Role, CreatedAt 
            FROM Users 
            WHERE FirebaseUID = ?
        """, (firebase_uid,))
        row = cursor.fetchone()
        
        if row is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, 
                detail="User not found"
            )
        
        return {
            "user_id": row[0],
            "username": row[1],
            "email": row[2],
            "role": row[3],
            "created_at": row[4]
        }
    except jwt.JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Invalid authentication credentials"
        )
    except Exception as e:
        print(f"Get current user error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )
    finally:
        if conn:
            conn.close()

# Endpoint to create database schema
@app.on_event("startup")
async def startup_event():
    create_database_schema()

# Authentication endpoints
@app.post("/token")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    raise HTTPException(
        status_code=status.HTTP_405_METHOD_NOT_ALLOWED,
        detail="Username/password login is deprecated. Use Firebase login endpoints."
    )

from pydantic import BaseModel

class TokenRequest(BaseModel):
    token: str

@app.post("/firebase-login")
async def firebase_login(token_request: TokenRequest):
    try:
        decoded_token = firebase_auth.verify_id_token(token_request.token)
        firebase_uid = decoded_token['uid']
        email = decoded_token.get('email', '')
        name = decoded_token.get('name', '')
        
        print(f"Firebase login attempt for UID: {firebase_uid}")
        
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT UserId, Username, Email, Role FROM Users WHERE FirebaseUID = ?", (firebase_uid,))
        user = cursor.fetchone()
        
        print(f"Database query result for UID {firebase_uid}: {user}")
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found. Please register first.",
            )
        
        access_token = create_access_token(data={"firebase_uid": firebase_uid})
        return {"access_token": access_token, "token_type": "bearer"}
    except firebase_auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Firebase ID token",
        )
    except Exception as e:
        print(f"Firebase login error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error",
        )

@app.get("/users/me", response_model=User)
async def get_current_user(current_user: User = Depends(get_current_user)):
    return current_user

@app.post("/firebase-register", response_model=User)
async def firebase_register(token: str = Body(...), username: str = Body(...), role: str = Body(...), name: str = Body(...)):
    try:
        decoded_token = firebase_auth.verify_id_token(token)
        firebase_uid = decoded_token['uid']
        email = decoded_token.get('email', '')
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Check if user already exists
        cursor.execute("SELECT UserId FROM Users WHERE FirebaseUID = ?", (firebase_uid,))
        if cursor.fetchone():
            raise HTTPException(
                status_code=400,
                detail="User already registered",
            )
        
        # Insert new user with FirebaseUID and other info, password is NULL
        cursor.execute("""
            INSERT INTO Users (Name, FirebaseUID, Username, Password, Email, Role)
            VALUES (?, ?, ?, NULL, ?, ?)
        """, (name, firebase_uid, username, email, role))
        conn.commit()
        
        cursor.execute("SELECT @@IDENTITY AS ID")
        user_id = cursor.fetchone()[0]
        
        return { "user_id": user_id, "username": username, "email": email, "role": role, "created_at": datetime.now() }
    except firebase_auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Firebase ID token",
        )
    except pyodbc.IntegrityError as ie:
        print(f"Firebase register IntegrityError: {ie}")
        raise HTTPException(
            status_code=400,
            detail="Username already taken",
        )
    except Exception as e:
        import traceback
        print(f"Firebase register error: {e}")
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error",
        )

# Internship endpoints
@app.get("/internships/available", response_model=List[Internship])
async def get_available_internships():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT i.InternshipId, i.Title, i.Description, i.Status, i.CreatedBy, i.CreatedAt
            FROM Internships i
            WHERE i.Status = 'available'
            ORDER BY i.CreatedAt DESC
        """)
        rows = cursor.fetchall()
        
        internships = []
        for row in rows:
            internships.append({
                "internship_id": row[0],
                "title": row[1],
                "description": row[2],
                "status": row[3],
                "created_by": row[4],
                "created_at": row[5]
            })
        return internships
    except Exception as e:
        print(f"Get available internships error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )
    finally:
        if conn:
            conn.close()

@app.get("/tasks/assigned", response_model=List[Task])
async def get_assigned_tasks(current_user: User = Depends(get_current_user)):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT t.TaskId, t.Title, t.Description, t.InternshipId, t.DueDate, t.CreatedAt,
                   ta.Status, ta.SubmissionPath
            FROM Tasks t
            INNER JOIN TaskAssignments ta ON t.TaskId = ta.TaskId
            WHERE ta.InterneeId = ?
            ORDER BY t.DueDate DESC
        """, (current_user["user_id"],))
        rows = cursor.fetchall()
        
        tasks = []
        for row in rows:
            tasks.append({
                "task_id": row[0],
                "title": row[1],
                "description": row[2],
                "internship_id": row[3],
                "due_date": row[4],
                "created_at": row[5],
                "status": row[6],
                "submission_path": row[7]
            })
        return tasks
    except Exception as e:
        print(f"Get assigned tasks error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )
    finally:
        if conn:
            conn.close()

# Admin endpoints
@app.get("/internships/all", response_model=List[Internship])
async def get_all_internships(current_user: User = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Only admins can view all internships")
    
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT InternshipId, Title, Description, Status, CreatedBy, CreatedAt 
            FROM Internships 
            ORDER BY CreatedAt DESC
        """)
        rows = cursor.fetchall()
        
        internships = []
        for row in rows:
            internships.append({
                "internship_id": row[0],
                "title": row[1],
                "description": row[2],
                "status": row[3],
                "created_by": row[4],
                "created_at": row[5]
            })
        return internships
    finally:
        if conn:
            conn.close()

@app.get("/users/internees", response_model=List[User])
async def get_all_internees(current_user: User = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Only admins can view internees")
    
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT UserId, Username, Email, Role, CreatedAt 
            FROM Users 
            WHERE Role = 'internee' 
            ORDER BY CreatedAt DESC
        """)
        rows = cursor.fetchall()
        
        internees = []
        for row in rows:
            internees.append({
                "user_id": row[0],
                "username": row[1],
                "email": row[2],
                "role": row[3],
                "created_at": row[4]
            })
        return internees
    except Exception as e:
        print(f"Get internees error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )
    finally:
        if conn:
            conn.close()

@app.post("/internships/", response_model=Internship)
async def create_internship(internship: InternshipCreate, current_user: User = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Only admins can create internships")
    
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO Internships (Title, Description, Status, CreatedBy)
            VALUES (?, ?, ?, ?)
        """, (internship.title, internship.description, internship.status, current_user["user_id"]))
        
        conn.commit()
        cursor.execute("SELECT @@IDENTITY AS ID")
        internship_id = cursor.fetchone()[0]
        
        return {
            "internship_id": internship_id,
            "title": internship.title,
            "description": internship.description,
            "status": internship.status,
            "created_by": current_user["user_id"],
            "created_at": datetime.now()
        }
    except Exception as e:
        print(f"Create internship error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create internship"
        )
    finally:
        if conn:
            conn.close()

@app.post("/tasks/", response_model=Task)
async def create_task(task: TaskCreate, current_user: User = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Only admins can create tasks")
    
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # First verify that the internship exists
        cursor.execute("SELECT InternshipId FROM Internships WHERE InternshipId = ?", (task.internship_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Internship not found")
        
        # Insert the task with CreatedBy
        cursor.execute("""
            INSERT INTO Tasks (InternshipId, Title, Description, DueDate, CreatedBy)
            VALUES (?, ?, ?, ?, ?)
        """, (task.internship_id, task.title, task.description, task.due_date, current_user["user_id"]))
        
        conn.commit()
        cursor.execute("SELECT @@IDENTITY AS ID")
        task_id = cursor.fetchone()[0]
        
        return {
            "task_id": task_id,
            "internship_id": task.internship_id,
            "title": task.title,
            "description": task.description,
            "due_date": task.due_date,
            "created_at": datetime.now(),
            "created_by": current_user["user_id"],  # Add this
            "status": None,
            "submission_path": None
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"Create task error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create task"
        )
    finally:
        if conn:
            conn.close()

# File upload handling
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

@app.post("/tasks/{task_id}/submit")
async def submit_task(
    task_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    if current_user["role"] != "internee":
        raise HTTPException(status_code=403, detail="Only internees can submit tasks")
    
    # Create user-specific directory
    user_dir = UPLOAD_DIR / str(current_user["user_id"])
    user_dir.mkdir(exist_ok=True)
    
    # Save the file
    file_path = user_dir / f"{task_id}_{file.filename}"
    with file_path.open("wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Update task assignment
    cursor.execute("""
        UPDATE TaskAssignments
        SET Status = 'completed', SubmissionPath = ?, SubmittedAt = GETDATE()
        WHERE TaskId = ? AND InterneeId = ?
    """, (str(file_path), task_id, current_user["user_id"]))
    
    conn.commit()
    conn.close()
    
    return {"message": "Task submitted successfully"}

# Update and Delete endpoints for Internships
@app.put("/internships/{internship_id}", response_model=Internship)
async def update_internship(
    internship_id: int,
    internship: InternshipCreate,
    current_user: User = Depends(get_current_user)
):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Only admins can update internships")
    
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            UPDATE Internships 
            SET Title = ?, Description = ?, Status = ?
            WHERE InternshipId = ?
            """, (internship.title, internship.description, internship.status, internship_id))
        
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Internship not found")
            
        conn.commit()
        
        # Get the updated internship
        cursor.execute("""
            SELECT InternshipId, Title, Description, Status, CreatedBy, CreatedAt
            FROM Internships WHERE InternshipId = ?
        """, (internship_id,))
        
        row = cursor.fetchone()
        return {
            "internship_id": row[0],
            "title": row[1],
            "description": row[2],
            "status": row[3],
            "created_by": row[4],
            "created_at": row[5]
        }
    finally:
        if conn:
            conn.close()

@app.delete("/internships/{internship_id}")
async def delete_internship(internship_id: int, current_user: User = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Only admins can delete internships")
    
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Start a transaction
        cursor.execute("BEGIN TRANSACTION")
        
        try:
            # Get internship details before deletion
            cursor.execute("""
                SELECT InternshipId, Title, Description 
                FROM Internships WHERE InternshipId = ?
            """, (internship_id,))
            internship = cursor.fetchone()
            
            if not internship:
                raise HTTPException(status_code=404, detail="Internship not found")
            
            # Delete related data
            cursor.execute("""
                DELETE FROM TaskAssignments
                WHERE TaskId IN (SELECT TaskId FROM Tasks WHERE InternshipId = ?)
            """, (internship_id,))
            
            cursor.execute("DELETE FROM Tasks WHERE InternshipId = ?", (internship_id,))
            cursor.execute("DELETE FROM InternshipApplications WHERE InternshipId = ?", (internship_id,))
            
            # Delete the internship
            cursor.execute("DELETE FROM Internships WHERE InternshipId = ?", (internship_id,))
            
            if cursor.rowcount == 0:
                raise HTTPException(status_code=404, detail="Internship not found")
            
            conn.commit()
            
            return {
                "success": True,
                "data": {
                    "internship_id": internship[0],
                    "title": internship[1],
                    "description": internship[2]
                },
                "message": "Internship deleted successfully"
            }
            
        except Exception as e:
            conn.rollback()
            print(f"Error deleting internship: {e}")
            raise HTTPException(
                status_code=500,
                detail="Failed to delete internship and related data"
            )
            
    except HTTPException:
        raise
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error"
        )
    finally:
        if conn:
            conn.close()
            
@app.get("/applications")
async def get_applications(current_user: User = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Only admins can view applications")
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('''
            SELECT a.ApplicationId, a.InternshipId, a.InterneeId, a.Status, a.AppliedAt,
                   i.Title, u.Username, u.Email,
                   a.Name, a.UniversityName, a.ResumePath, a.Degree, a.Semester
            FROM InternshipApplications a
            JOIN Internships i ON a.InternshipId = i.InternshipId
            JOIN Users u ON a.InterneeId = u.UserId
            ORDER BY a.AppliedAt DESC
        ''')
        rows = cursor.fetchall()
        applications = []
        for row in rows:
            applications.append({
                "application_id": row[0],
                "internship_id": row[1],
                "internee_id": row[2],
                "status": row[3],
                "applied_at": row[4],
                "internship_title": row[5],
                "internee_name": row[6],
                "internee_email": row[7],
                "name": row[8],
                "universityname": row[9],
                "resumepath": row[10],
                "degree": row[11],
                "semester": row[12],
            })
        return applications
    except Exception as e:
        print(f"Get applications error: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch applications")
    finally:
        if conn:
            conn.close()

from pydantic import BaseModel

class StatusUpdateRequest(BaseModel):
    status: str

@app.put("/applications/{application_id}/status")
async def update_application_status(application_id: int, status_update: StatusUpdateRequest, current_user: User = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Only admins can update applications")
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE InternshipApplications
            SET Status = ?
            WHERE ApplicationId = ?
        """, (status_update.status, application_id))
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Application not found")
        conn.commit()
        return {"message": f"Application {status_update.status} successfully"}
    except Exception as e:
        print(f"Update application status error: {e}")
        raise HTTPException(status_code=500, detail="Failed to update application status")
    finally:
        if conn:
            conn.close()

@app.post("/internships/{internship_id}/apply")
async def apply_for_internship(internship_id: int, current_user: User = Depends(get_current_user)):
    if current_user["role"] != "internee":
        raise HTTPException(status_code=403, detail="Only internees can apply")
    conn = get_db_connection()
    cursor = conn.cursor()
    # Check if already applied
    cursor.execute("SELECT * FROM InternshipApplications WHERE InternshipId = ? AND InterneeId = ?", (internship_id, current_user["user_id"]))
    if cursor.fetchone():
        conn.close()
        raise HTTPException(status_code=400, detail="Already applied")
    cursor.execute(
        "INSERT INTO InternshipApplications (InternshipId, InterneeId, Status) VALUES (?, ?, 'pending')",
        (internship_id, current_user["user_id"])
    )
    conn.commit()
    conn.close()
    return {"message": "Application submitted"}

from fastapi import UploadFile, File, Form

@app.post("/internships/{internship_id}/apply_with_details")
async def apply_for_internship_with_details(
    internship_id: int,
    name: str = Form(...),
    university_name: str = Form(...),
    degree: str = Form(...),
    semester: str = Form(...),
    resume: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    if current_user["role"] != "internee":
        raise HTTPException(status_code=403, detail="Only internees can apply")

    if resume.content_type != "application/pdf":
        raise HTTPException(status_code=400, detail="Resume must be a PDF file")

    conn = get_db_connection()
    cursor = conn.cursor()

    # Check if already applied
    cursor.execute("SELECT * FROM InternshipApplications WHERE InternshipId = ? AND InterneeId = ?", (internship_id, current_user["user_id"]))
    existing_application = cursor.fetchone()

    # Save resume file
    upload_dir = Path("uploads") / str(current_user["user_id"])
    upload_dir.mkdir(parents=True, exist_ok=True)
    resume_path = upload_dir / f"{internship_id}_{resume.filename}"

    with open(resume_path, "wb") as buffer:
        shutil.copyfileobj(resume.file, buffer)

    # Convert path to posix (forward slashes) for URL compatibility
    resume_path_str = str(resume_path).replace("\\", "/")

    if existing_application:
        # Update existing application
        cursor.execute("""
            UPDATE InternshipApplications
            SET Status = 'pending', Name = ?, UniversityName = ?, ResumePath = ?, Degree = ?, Semester = ?, AppliedAt = GETDATE()
            WHERE InternshipId = ? AND InterneeId = ?
        """, (name, university_name, resume_path_str, degree, semester, internship_id, current_user["user_id"]))
    else:
        # Insert new application
        cursor.execute("""
            INSERT INTO InternshipApplications 
            (InternshipId, InterneeId, Status, Name, UniversityName, ResumePath, Degree, Semester) 
            VALUES (?, ?, 'pending', ?, ?, ?, ?, ?)
        """, (internship_id, current_user["user_id"], name, university_name, resume_path_str, degree, semester))

    conn.commit()
    conn.close()

    return {"message": "Application submitted with details"}

@app.post("/tasks/{task_id}/assign")
async def assign_task(task_id: int, internee_id: int, current_user: User = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Only admins can assign tasks")
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO TaskAssignments (TaskId, InterneeId, Status) VALUES (?, ?, 'pending')",
        (task_id, internee_id)
    )
    conn.commit()
    conn.close()
    return {"message": "Task assigned"}

# Add more endpoints as needed...

@app.put("/tasks/{task_id}", response_model=Task)
async def update_task(task_id: int, task: TaskCreate, current_user: User = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Only admins can update tasks")
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Verify task exists
        cursor.execute("SELECT TaskId FROM Tasks WHERE TaskId = ?", (task_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Task not found")

        # Update task details
        cursor.execute("""
            UPDATE Tasks
            SET Title = ?, Description = ?, DueDate = ?
            WHERE TaskId = ?
        """, (task.title, task.description, task.due_date, task_id))

        conn.commit()

        # Return updated task
        cursor.execute("""
            SELECT TaskId, Title, Description, InternshipId, DueDate, CreatedAt
            FROM Tasks WHERE TaskId = ?
        """, (task_id,))
        row = cursor.fetchone()
        return {
            "task_id": row[0],
            "title": row[1],
            "description": row[2],
            "internship_id": row[3],
            "due_date": row[4],
            "created_at": row[5],
            "status": None,
            "submission_path": None
        }
    finally:
        if conn:
            conn.close()

@app.delete("/tasks/{task_id}")
async def delete_task(task_id: int, current_user: User = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Only admins can delete tasks")
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Delete related task assignments
        cursor.execute("DELETE FROM TaskAssignments WHERE TaskId = ?", (task_id,))

        # Delete the task
        cursor.execute("DELETE FROM Tasks WHERE TaskId = ?", (task_id,))

        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Task not found")

        conn.commit()
        return {"message": "Task deleted successfully"}
    finally:
        if conn:
            conn.close()

@app.get("/tasks/admin", response_model=List[Task])
async def get_admin_tasks(current_user: User = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Only admins can view their tasks")
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT t.TaskId, t.Title, t.Description, t.InternshipId, t.DueDate, t.CreatedAt
            FROM Tasks t
            WHERE t.CreatedBy = ?
            ORDER BY t.CreatedAt DESC
        """, (current_user["user_id"],))
        rows = cursor.fetchall()
        tasks = []
        for row in rows:
            tasks.append({
                "task_id": row[0],
                "title": row[1],
                "description": row[2],
                "internship_id": row[3],
                "due_date": row[4],
                "created_at": row[5],
                "status": None,
                "submission_path": None
            })
        return tasks
    except Exception as e:
        print(f"Get admin tasks error: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch admin tasks")
    finally:
        if conn:
            conn.close()

@app.get("/internees/progress")
async def get_internees_progress(current_user: User = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Only admins can view internee progress")
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT u.UserId, u.Username,
                SUM(CASE WHEN ta.Status = 'completed' THEN 1 ELSE 0 END) AS completed_tasks,
                SUM(CASE WHEN ta.Status = 'pending' THEN 1 ELSE 0 END) AS pending_tasks,
                COUNT(ta.AssignmentId) AS total_tasks
            FROM Users u
            LEFT JOIN TaskAssignments ta ON u.UserId = ta.InterneeId
            WHERE u.Role = 'internee'
            GROUP BY u.UserId, u.Username
            ORDER BY u.Username
        """)
        rows = cursor.fetchall()
        progress_list = []
        for row in rows:
            progress_list.append({
                "internee_id": row[0],
                "username": row[1],
                "completed_tasks": row[2],
                "pending_tasks": row[3],
                "total_tasks": row[4]
            })
        return progress_list
    except Exception as e:
        print(f"Get internees progress error: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch internee progress")
    finally:
        if conn:
            conn.close()





if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
