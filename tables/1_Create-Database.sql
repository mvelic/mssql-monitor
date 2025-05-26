/*

CREATE DATABASE

*/
USE master;
GO

CREATE DATABASE MssqlMonitor
ON (
	NAME = MssqlMonitor_dat,
	FILENAME = '<your_path>\Data\MssqlMonitor_dat.mdf', -- Update with your path
	SIZE = 512MB,
	FILEGROWTH = 256MB
)
LOG ON (
	NAME = MssqlMonitor_log,
	FILENAME = '<your_path>\Tranlogs\MssqlMonitor_log.ldf', -- Update with your path
	SIZE = 256MB,
	FILEGROWTH = 256MB
);
GO

ALTER DATABASE MssqlMonitor
SET RECOVERY SIMPLE 
GO

ALTER DATABASE MssqlMonitor
SET PAGE_VERIFY CHECKSUM;
GO
