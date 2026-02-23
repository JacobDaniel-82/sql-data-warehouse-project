/*
===============================================================================
Script Purpose: 
    This script initializes the 'DataWareHouse' database. It creates the 
    foundation for the data warehouse by setting up the core schemas: 
    Bronze, Silver, and Gold.

WARNING:
    RUN THIS SCRIPT WITH EXTREME CAUTION. 
    Executing this script will PERMANENTLY DELETE the existing 'DataWareHouse' 
    database if it already exists. This will result in the total loss of all 
    contained data and objects. Ensure you have backups before running.
===============================================================================
*/

USE master;
GO

-- Check if database exists and drop it to start fresh
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWareHouse')
BEGIN
    ALTER DATABASE DataWareHouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWareHouse;
END;
GO

-- Create the Data Warehouse database
CREATE DATABASE DataWareHouse;
GO

USE DataWareHouse;
GO

-- Initialize Schemas for Medallion Architecture
CREATE SCHEMA bronze;
GO

CREATE SCHEMA Silver;
GO

CREATE SCHEMA gold;
GO
