USE master
GO
-- Drop the database if it exists
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'RESDATABASE')
BEGIN
    ALTER DATABASE RESDATABASE SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RESDATABASE;
END
GO

DROP TRIGGER IF EXISTS EnforceSittingConstraints
GO

-- Create the database
CREATE DATABASE RESDATABASE
GO 

-- Use the RESDATABASE database
USE RESDATABASE
GO

-- Create the Users table
CREATE TABLE Users (
    UserId INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(100) UNIQUE,
    Password NVARCHAR(100),
    Role NVARCHAR(20) CHECK (Role IN ('Manager', 'Staff', 'Member', 'Guest'))
);
GO 

-- Create the Area Table
CREATE TABLE Area (
    AreaID INT PRIMARY KEY,
    AreaName NVARCHAR(50),
	AreaDescription NVARCHAR(MAX)
);
GO

-- Create the RestaurantTable Table
CREATE TABLE ResTables (
    TableId INT PRIMARY KEY,
    AreaId INT, -- Foreign key to link to the Area table
    TableName NVARCHAR(50), -- M1-M10, O1-O10, B1-B10 etc
    FOREIGN KEY (AreaId) REFERENCES Area(AreaId)
);
GO

-- Create the SittingsTable (Sitting Type) Table
CREATE TABLE SittingsTable (
    SittingID INT PRIMARY KEY,
    SType NVARCHAR(20) CHECK (SType IN ('breakfast', 'lunch', 'dinner', 'special')),
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
);
GO

-- Create the Reservation Table
CREATE TABLE Reservation (
    ReservationID INT PRIMARY KEY IDENTITY(1,1),
    UserId INT, -- Foreign key to link to the Members table
    NumGuests INT NOT NULL,
    Status NVARCHAR(20) CHECK (Status IN ('seated', 'free', 'canceled', 'pending')),
    Notes NVARCHAR(100),Sitt
    ReservationDateTime DATETIME,
    SittingID INT NOT NULL,
	ReservationSource NVARCHAR(20) CHECK (ReservationSource IN ('Website', 'Email', 'Phone', 'Person')),
	Duration TIME,

    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (SittingID) REFERENCES SittingsTable(SittingID)
);
GO

-- Add the ExpectedDepartureTime column to the Reservation table
ALTER TABLE Reservation
ADD ExpectedDepartureTime DATETIME;

-- Create a trigger to calculate and update the expected departure time for a reservation
CREATE TRIGGER UpdateExpectedDepartureTime
ON Reservation
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE Reservation
    SET ExpectedDepartureTime = DATEADD(MINUTE, Duration, ReservationDateTime)
    FROM Reservation r
    JOIN inserted i ON r.ReservationID = i.ReservationID;
END;


-- Insert test data into the Users table
INSERT INTO Users (FirstName, LastName, Email, Password, Role)
VALUES
    ('John', 'Doe', 'john.doe@example.com', 'password123', 'Member'),
    ('Jane', 'Smith', 'jane.smith@example.com', 'securepass', 'Guest'),
    ('Manager', 'Person', 'manager@example.com', 'adminpass', 'Manager');

-- Insert test data into the Area table
INSERT INTO Area (AreaID, AreaName, AreaDescription)
VALUES
    (1, 'outside', 'Outdoor seating area with a scenic view.'),
    (2, 'main', 'Main dining area for indoor seating.'),
    (3, 'balcony', 'Balcony seating overlooking the main area.');

-- Insert test data into the ResTables table
INSERT INTO ResTables (TableId, AreaId, TableName)
VALUES
    (1, 1, 'O1'),
    (2, 1, 'O2'),
    (3, 2, 'M1'),
    (4, 2, 'M2'),
    (5, 3, 'B1'),
    (6, 3, 'B2');

-- Insert test data into the SittingsTable table
INSERT INTO SittingsTable (SittingID, SType, StartTime, EndTime)
VALUES
    (1, 'breakfast', '08:00:00', '10:00:00'),
    (2, 'lunch', '12:00:00', '14:00:00'),
    (3, 'dinner', '18:00:00', '20:00:00');

-- Insert test data into the Reservation table
INSERT INTO Reservation (UserId, NumGuests, Status, Notes, ReservationDateTime, SittingID, ReservationSource, Duration)
VALUES
    (1, 4, 'pending', 'Special occasion', '2023-11-01 19:00:00', 3, 'Website', '02:00:00'),
    (2, 2, 'seated', 'Regular reservation', '2023-11-02 13:30:00', 2, 'Phone', '01:30:00');


-- Query to retrieve detailed information about reservations
SELECT
    r.ReservationID,
    u.FirstName + ' ' + u.LastName AS UserName,
    r.NumGuests,
    r.Status,
    r.Notes,
    r.ReservationDateTime,
    s.SType AS SittingType,
    s.StartTime AS SittingStartTime,
    s.EndTime AS SittingEndTime,
    t.TableName,
    a.AreaName,
    r.ReservationSource,
    r.Duration
FROM Reservation r
JOIN Users u ON r.UserId = u.UserId
JOIN SittingsTable s ON r.SittingID = s.SittingID
JOIN ResTables t ON r.TableId = t.TableId
JOIN Area a ON t.AreaId = a.AreaID;

-- Query to retrieve tables with area details
SELECT
    t.TableId,
    a.AreaName,
    t.TableName
FROM ResTables t
JOIN Area a ON t.AreaId = a.AreaID;
