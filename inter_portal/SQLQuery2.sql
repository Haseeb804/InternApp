
-- Create Users table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[Users] (
        UserId INT PRIMARY KEY IDENTITY(1,1),
		Name VARCHAR(100) NOT NULL,
		FirebaseUID VARCHAR(100) UNIQUE NOT NULL,
        Username VARCHAR(50) UNIQUE NOT NULL,
        Password VARCHAR(100) NOT NULL,
        Email VARCHAR(100) UNIQUE NOT NULL,
        Role VARCHAR(10) NOT NULL,  -- 'admin' or 'internee'
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END;
GO

-- Create Internships table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Internships]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[Internships] (
        InternshipId INT PRIMARY KEY IDENTITY(1,1),
        Title VARCHAR(100) NOT NULL,
        Description TEXT,
        Status VARCHAR(20) NOT NULL,  -- 'available' or 'not available'
        CreatedBy INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (CreatedBy) REFERENCES [dbo].[Users](UserId)
    );
END;
GO

-- Create Tasks table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Tasks]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[Tasks] (
        TaskId INT PRIMARY KEY IDENTITY(1,1),
        InternshipId INT NOT NULL,
        Title VARCHAR(100) NOT NULL,
        Description TEXT,
        DueDate DATETIME,
        CreatedAt DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (InternshipId) REFERENCES [dbo].[Internships](InternshipId)
    );
END;
GO

-- Create InternshipApplications table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InternshipApplications]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[InternshipApplications] (
        ApplicationId INT PRIMARY KEY IDENTITY(1,1),
        InternshipId INT NOT NULL,
        InterneeId INT NOT NULL,
        Status VARCHAR(20) NOT NULL,  -- 'pending', 'approved', 'rejected'
        AppliedAt DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (InternshipId) REFERENCES [dbo].[Internships](InternshipId),
        FOREIGN KEY (InterneeId) REFERENCES [dbo].[Users](UserId)
    );
END;
GO

-- Step 1: Add columns as nullable
ALTER TABLE [dbo].[InternshipApplications]
ADD 
    Name VARCHAR(100) NULL,
    UniversityName VARCHAR(100) NULL,
    ResumePath VARCHAR(255) NULL,
    Degree VARCHAR(50) NULL,
    Semester VARCHAR(20) NULL;





-- Create TaskAssignments table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TaskAssignments]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[TaskAssignments] (
        AssignmentId INT PRIMARY KEY IDENTITY(1,1),
        TaskId INT NOT NULL,
        InterneeId INT NOT NULL,
        Status VARCHAR(20) NOT NULL,  -- 'pending', 'completed', 'in_progress'
        SubmissionPath VARCHAR(255),
        SubmittedAt DATETIME,
        CreatedAt DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (TaskId) REFERENCES [dbo].[Tasks](TaskId),
        FOREIGN KEY (InterneeId) REFERENCES [dbo].[Users](UserId)
    );
END;
GO

-- Create Indexes if not already created
IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = 'IX_Internships_Status')
    CREATE INDEX IX_Internships_Status ON [dbo].[Internships](Status);
GO

IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = 'IX_Tasks_InternshipId')
    CREATE INDEX IX_Tasks_InternshipId ON [dbo].[Tasks](InternshipId);
GO

IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = 'IX_InternshipApplications_Status')
    CREATE INDEX IX_InternshipApplications_Status ON [dbo].[InternshipApplications](Status);
GO

IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = 'IX_TaskAssignments_Status')
    CREATE INDEX IX_TaskAssignments_Status ON [dbo].[TaskAssignments](Status);
GO


-- Update Tasks table to add CreatedBy column
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Tasks]') AND type = 'U')
BEGIN
    -- Check if column doesn't exist before adding it
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Tasks]') AND name = 'CreatedBy')
    BEGIN
        ALTER TABLE [dbo].[Tasks]
        ADD CreatedBy INT NOT NULL DEFAULT 1  -- Default to admin user (you may need to adjust this)
        CONSTRAINT FK_Tasks_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES [dbo].[Users](UserId);
        
        PRINT 'Added CreatedBy column to Tasks table';
    END
END
GO

-- Step 1: Drop existing foreign key constraint (if known)
-- First, find the foreign key name
-- You can skip this if you didn't set any constraint name manually

DECLARE @fk_name NVARCHAR(255);
SELECT @fk_name = fk.name
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.tables t ON fk.parent_object_id = t.object_id
JOIN sys.columns c ON fkc.parent_object_id = c.object_id AND fkc.parent_column_id = c.column_id
WHERE t.name = 'Tasks' AND c.name = 'InternshipId';

-- Drop the constraint
IF @fk_name IS NOT NULL
BEGIN
    EXEC('ALTER TABLE [dbo].[Tasks] DROP CONSTRAINT ' + @fk_name);
    PRINT 'Old foreign key constraint on Tasks.InternshipId dropped.';
END
GO

-- Step 2: Add new foreign key with ON DELETE CASCADE
ALTER TABLE [dbo].[Tasks]
ADD CONSTRAINT FK_Tasks_InternshipId
FOREIGN KEY (InternshipId) REFERENCES [dbo].[Internships](InternshipId) ON DELETE CASCADE;
GO

PRINT 'New foreign key constraint with ON DELETE CASCADE added to Tasks.InternshipId';


-- First drop existing constraint if it exists
DECLARE @constraint_name NVARCHAR(128)
SELECT @constraint_name = name 
FROM sys.foreign_keys 
WHERE parent_object_id = OBJECT_ID('Tasks') 
AND referenced_object_id = OBJECT_ID('Internships')

IF @constraint_name IS NOT NULL
    EXEC('ALTER TABLE Tasks DROP CONSTRAINT ' + @constraint_name)

-- Add new constraint with CASCADE
ALTER TABLE Tasks
ADD CONSTRAINT FK_Tasks_Internships
FOREIGN KEY (InternshipId) REFERENCES Internships(InternshipId) ON DELETE CASCADE;


ALTER TABLE Users ALTER COLUMN Password VARCHAR(100) NULL;


select *from Users
 DELETE FROM TaskAssignments
                WHERE TaskId IN (SELECT TaskId FROM Tasks WHERE InternshipId =3)

 DELETE FROM Users where UserId = 5
 DELETE FROM TaskAssignments WHERE TaskId = 2


 -- Step 1: Delete from TaskAssignments (depends on Tasks and Users)
DELETE FROM [dbo].[TaskAssignments];

-- Step 2: Delete from Tasks (depends on Internships)
DELETE FROM [dbo].[Tasks];

-- Step 3: Delete from InternshipApplications (depends on Internships and Users)
DELETE FROM [dbo].[InternshipApplications];

-- Step 4: Delete from Internships (depends on Users)
DELETE FROM [dbo].[Internships];

-- Step 5: Delete from Users (root parent)
DELETE FROM [dbo].[Users];
