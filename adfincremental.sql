/*

This SQL script combines all of the different SQL commands required to build a sample pattern
for Azure Data Factory (ADF) incremental data loading patterns using Azure SQL Database
Change Tracking feature

https://docs.microsoft.com/en-us/azure/data-factory/tutorial-incremental-copy-change-tracking-feature-porta

*/

-- Create a sample database table to store some data to test with
create table data_source_table
(
    PersonID int NOT NULL,
    Name varchar(255),
    Age int
    PRIMARY KEY (PersonID)
);

-- Insert some sample data to seed the table
INSERT INTO data_source_table
    (PersonID, Name, Age)
VALUES
    (1, 'aaaa', 21),
    (2, 'bbbb', 24),
    (3, 'cccc', 20),
    (4, 'dddd', 26),
    (5, 'eeee', 22);

/* Turn on change tracking for your Azure SQL DB. If this does not work, you can always
turn Change Tracking on Azure SQL DB from SSMS under Database Properties */
ALTER DATABASE markaw
SET CHANGE_TRACKING = ON  
(CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON)  

ALTER TABLE data_source_table
ENABLE CHANGE_TRACKING  
WITH (TRACK_COLUMNS_UPDATED = ON)

-- Use this as a table that you can query and update from ADF with the latest CT version
create table table_store_ChangeTracking_version
(
    TableName varchar(255),
    SYS_CHANGE_VERSION BIGINT,
);

-- Use the next few lines to see the tracking table
DECLARE @ChangeTracking_version BIGINT
SET @ChangeTracking_version = CHANGE_TRACKING_CURRENT_VERSION();  

INSERT INTO table_store_ChangeTracking_version
VALUES ('data_source_table', @ChangeTracking_version)

-- This SPROC will update the CT version in your tracking table
CREATE PROCEDURE Update_ChangeTracking_Version @CurrentTrackingVersion BIGINT, @TableName varchar(50)
AS

BEGIN

    UPDATE table_store_ChangeTracking_version
    SET [SYS_CHANGE_VERSION] = @CurrentTrackingVersion
WHERE [TableName] = @TableName

END    

/*
Use the next few lines to insert some new data into the test table and update the
CT version for testing
*/
INSERT INTO data_source_table
(PersonID, Name, Age)
VALUES
(6, 'new','50');

UPDATE data_source_table
SET [Age] = '10', [name]='update' where [PersonID] = 1