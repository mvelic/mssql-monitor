USE MssqlMonitor;
GO

/*

CREATE TABLES

*/
-- dbo.KeyValue
-- Stores configuration options for the monitoring solution
IF OBJECT_ID('dbo.KeyValue') IS NOT NULL
	DROP TABLE dbo.KeyValue;
GO

CREATE TABLE dbo.KeyValue (
	[Key] VARCHAR(60) NOT NULL,
	[Value] VARCHAR(256) NOT NULL
);
GO

-- dbo.DatabasesToMonitor
-- Can limit to specific databases if on a shared server
IF OBJECT_ID('dbo.DatabasesToMonitor') IS NOT NULL
	DROP TABLE dbo.DatabasesToMonitor;
GO

CREATE TABLE dbo.DatabasesToMonitor (
	DatabaseName SYSNAME NOT NULL
);
GO

-- dbo.IgnoredWaitTypes
-- Wait Types that are not useful to track
IF OBJECT_ID('dbo.IgnoredWaitTypes') IS NOT NULL
	DROP TABLE dbo.IgnoredWaitTypes;
GO

CREATE TABLE dbo.IgnoredWaitTypes (
	WaitType NVARCHAR(60) NOT NULL
);
GO

-- dbo.ErrorLog
-- To track any errors that occur while collecting information
IF OBJECT_ID('dbo.ErrorLog') IS NOT NULL
	DROP TABLE dbo.ErrorLog;
GO

CREATE TABLE dbo.ErrorLog (
	ErrorId INT IDENTITY(1,1) NOT NULL
	,UserName VARCHAR(100) NULL
	,ErrorNumber INT NULL
	,ErrorState INT NULL
	,ErrorSeverity INT NULL
	,ErrorLine INT NULL
	,ErrorProcedure VARCHAR(MAX) NULL
	,ErrorMessage VARCHAR(MAX) NULL
	,ErrorDateTime DATETIME NULL
);
GO

-- dbo.ServerProperties
-- Weekly collection to monitor SQL Server version properties 
IF OBJECT_ID('dbo.ServerProperties') IS NOT NULL
	DROP TABLE dbo.ServerProperties;
GO

CREATE TABLE dbo.ServerProperties (
	DateCollected DATETIME NOT NULL
	,ServerName SQL_VARIANT NOT NULL
	,IsClustered SQL_VARIANT NOT NULL
	,[Edition] SQL_VARIANT NOT NULL
	,ProductLevel SQL_VARIANT NOT NULL
	,ProductVersion SQL_VARIANT NOT NULL
);
GO

-- dbo.ServerConfigurations
-- Weekly collection of server configurations that can affect query performance
IF OBJECT_ID('dbo.ServerConfigurations') IS NOT NULL
	DROP TABLE dbo.ServerConfigurations;
GO

CREATE TABLE dbo.ServerConfigurations (
	DateCollected DATETIME NOT NULL
	,[Name] NVARCHAR(35) NOT NULL
	,[Value] SQL_VARIANT NOT NULL
	,ValueInUse SQL_VARIANT NOT NULL
	,[Description] NVARCHAR(255) NOT NULL
);
GO

-- dbo.VolumeInfo
-- Weekly collection to monitor storage volume values
IF OBJECT_ID('dbo.VolumeInfo') IS NOT NULL
	DROP TABLE dbo.VolumeInfo;
GO
	
CREATE TABLE dbo.VolumeInfo (
	DateCollected DATETIME NOT NULL
	,DatabaseName SYSNAME NOT NULL
	,FileId INT NOT NULL
	,VolumeMountPoint SQL_VARIANT NULL
	,TotalSize_GB DECIMAL(18,2) NOT NULL
	,AvailableSize_GB DECIMAL(18,2) NOT NULL
	,SpaceFree_PCT DECIMAL(18,2) NOT NULL
);
GO

-- dbo.DatabaseProperties
-- Weekly collection of properties (by database) that can affect query performance
IF OBJECT_ID('dbo.DatabaseProperties') IS NOT NULL
	DROP TABLE dbo.DatabaseProperties;
GO

CREATE TABLE dbo.DatabaseProperties (
	DateCollected DATETIME NOT NULL
	,DatabaseName SYSNAME NOT NULL
	,RecoveryModel NVARCHAR(60) NULL
	,StateDescription NVARCHAR(60) NULL
	,LogReuseWaitDescription NVARCHAR(60) NULL
	,LogSize_MB DECIMAL(18,2) NOT NULL
	,LogUsed_MB DECIMAL(18,2) NOT NULL
	,LogUsed_PCT DECIMAL(18,2) NOT NULL
	,DbCompatibilityLevel TINYINT NOT NULL
	,PageVerifyOptionDescription NVARCHAR(60) NULL
	,IsAutoCreateStatsOn BIT NULL
	,IsAutoUpdateStatsOn BIT NULL
	,IsParameterizationForced BIT NULL
	,SnapshotIsolationStateDescription NVARCHAR(60) NULL
	,IsReadCommittedSnapshotOn BIT NULL
	,IsAutoShrinkOn BIT NULL
	,IsCdcEnabled BIT NOT NULL
);
GO

-- dbo.WaitStats
-- Weekly collection of the top Wait Stats affecting the server as a whole
IF OBJECT_ID('dbo.WaitStats') IS NOT NULL
	DROP TABLE dbo.WaitStats;
GO

CREATE TABLE dbo.WaitStats (
	DateCollected DATETIME NOT NULL
	,WaitType NVARCHAR(60) NOT NULL
	,WaitTime_S DECIMAL(12,2) NOT NULL
	,PCT DECIMAL(12,2) NOT NULL
	,Running_PCT DECIMAL(12,2) NOT NULL
);

-- dbo.SignalWaits
-- Weekly collection to verify CPU pressure
IF OBJECT_ID('dbo.SignalWaits') IS NOT NULL
	DROP TABLE dbo.SignalWaits;
GO

CREATE TABLE dbo.SignalWaits (
	DateCollected DATETIME NOT NULL
	,SignalCpuWaits NUMERIC(20,2) NOT NULL
	,ResourceWaits NUMERIC(20,2) NOT NULL
);
GO

-- dbo.SystemMemory
-- Weekly collection to verify system memory usage
IF OBJECT_ID('dbo.SystemMemory') IS NOT NULL
	DROP TABLE dbo.SystemMemory;
GO

CREATE TABLE dbo.SystemMemory (
	DateCollected DATETIME NOT NULL
	,PhysicalMemory_MB BIGINT NOT NULL
	,AvailableMemory_MB BIGINT NOT NULL
	,TotalPageFile_MB BIGINT NOT NULL
	,AvailablePageFile_MB BIGINT NOT NULL
	,SystemCache_MB BIGINT NOT NULL
	,SystemMemoryStateDescription NVARCHAR(256) NOT NULL
);
GO

-- dbo.FileSizeSpaceByDb
-- Weekly collection to monitor file sizes in each database
IF OBJECT_ID('dbo.FileSizeSpaceByDb') IS NOT NULL
	DROP TABLE dbo.FileSizeSpaceByDb;
GO

CREATE TABLE dbo.FileSizeSpaceByDb (
	DateCollected DATETIME NOT NULL
	,DatabaseName SYSNAME NOT NULL
	,[FileName] SYSNAME NOT NULL
	,PhysicalName NVARCHAR(260) NOT NULL
	,TotalSize_MB DECIMAL(15,2) NOT NULL
	,AvailableSpace_MB DECIMAL(15,2) NOT NULL
	,FileId INT NOT NULL
	,FilegroupName SYSNAME NULL
);
GO

-- dbo.TransactionLogSpaceByDb
-- Weekly collection to monitor Transaction Log usage in each database
IF OBJECT_ID('dbo.TransactionLogSpaceByDb') IS NOT NULL
	DROP TABLE dbo.TransactionLogSpaceByDb;
GO

CREATE TABLE dbo.TransactionLogSpaceByDb (
	DateCollected DATETIME NOT NULL
	,DatabaseName NVARCHAR(128) NULL
	,TotalLogSize_MB DECIMAL(10,1) NULL
	,UsedLogSpace_MB DECIMAL(10,1) NULL
	,UsedLogSpace_PCT DECIMAL(10,1) NULL
);
GO

-- dbo.OSInfo
-- Weekly collection of operating system information
IF OBJECT_ID('dbo.OSInfo') IS NOT NULL
	DROP TABLE dbo.OSInfo;
GO

CREATE TABLE dbo.OSInfo (
	DateCollected DATETIME NOT NULL
	,SQLServerStartTime DATETIME NOT NULL
	,CPUCount INT NOT NULL
	,HyperthreadRatio INT NOT NULL
	,PhysicalMemory_MB BIGINT NOT NULL
);
GO

-- dbo.DbBackups
-- Weekly colection of backup information for each database
IF OBJECT_ID('dbo.DbBackups') IS NOT NULL
	DROP TABLE dbo.DbBackups;
GO

CREATE TABLE dbo.DbBackups (
	DateCollected DATETIME NOT NULL
	,ServerName NVARCHAR(128) NULL
	,DatabaseName NVARCHAR(128) NULL
	,[Type] CHAR(1) NULL
	,UncompressedBackupSize_MB BIGINT NULL
	,CompressedBackupSize_MB BIGINT NULL
	,CompressionRatio NUMERIC(20,2) NULL
	,HasBackupChecksums BIT NULL
	,BackupElapsedTime_S INT NULL
	,BackupStartDate DATETIME NULL
	,BackupFinishDate DATETIME NULL
);
GO
