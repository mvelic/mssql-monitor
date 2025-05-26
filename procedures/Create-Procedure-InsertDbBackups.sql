-- =============================================
-- Author:		Matt Velic
-- Create date: 07/24/2019
-- Description: Weekly collection of backup information for each database
-- Change Log: 07/24/2019 - Initial procedure
-- =============================================
CREATE PROCEDURE dbo.InsertDbBackups 
AS
BEGIN;
SET NOCOUNT ON;

DECLARE @trancount INT;
SET @trancount = @@trancount;

BEGIN TRY
IF @trancount = 0
	BEGIN TRANSACTION
ELSE
	SAVE TRANSACTION InsertDbBackups;

DECLARE @lastCollectionDate DATETIME = (SELECT MAX(DateCollected) FROM dbo.DbBackups);

INSERT INTO dbo.DbBackups (
	DateCollected 
	,ServerName 
	,DatabaseName 
	,[Type] 
	,UncompressedBackupSize_MB 
	,CompressedBackupSize_MB 
	,CompressionRatio 
	,HasBackupChecksums 
	,BackupElapsedTime_S 
	,BackupStartDate 
	,BackupFinishDate 
)
SELECT
	DateCollected = GETDATE()
	,ServerName = bs.server_name
	,DatabaseName = bs.database_name 
	,[Type] = bs.[type]
	,UncompressedBackupSize_MB = CONVERT (BIGINT, bs.backup_size / 1048576 )
	,CompressedBackupSize_MB = CONVERT (BIGINT, bs.compressed_backup_size / 1048576 ) 
	,CompressionRatio = CONVERT (NUMERIC (20,2), (CONVERT (FLOAT, bs.backup_size) /CONVERT (FLOAT, bs.compressed_backup_size))) 
	,HasBackupChecksums = bs.has_backup_checksums
	,BackupElapsedTime_S = DATEDIFF (SECOND, bs.backup_start_date, bs.backup_finish_date)
	,BackupStartDate =  bs.backup_start_date
	,BackupFinishDate =  bs.backup_finish_date 
FROM msdb.dbo.backupset AS bs WITH (NOLOCK)
INNER JOIN dbo.DatabasesToMonitor dtm
	ON bs.database_name = dtm.[DatabaseName]
WHERE bs.backup_start_date > COALESCE(@lastCollectionDate,'1999-12-31 00:00:00.000');

LBEXIT:
IF @trancount = 0
	COMMIT TRANSACTION;
END TRY
BEGIN CATCH

DECLARE @name VARCHAR(100),
		@numb INT,
		@stat INT,
		@sevr INT,
		@line INT,
		@proc VARCHAR(MAX),
		@mess VARCHAR(MAX),
		@date DATETIME,
		@xstate INT;
		
SELECT  @name = SUSER_SNAME(),
		@numb = ERROR_NUMBER(),
		@stat = ERROR_STATE(),
		@sevr = ERROR_SEVERITY(),
		@line = ERROR_LINE(),
		@proc = ERROR_PROCEDURE(),
		@mess = ERROR_MESSAGE(),
		@date = GETDATE(),
		@xstate = XACT_STATE();
 
IF @xstate = -1
	ROLLBACK TRANSACTION;
IF @xstate = 1 AND @trancount = 0
	ROLLBACK TRANSACTION;
IF @xstate = 1 AND @trancount > 0
	ROLLBACK TRANSACTION InsertDbBackups;

INSERT INTO dbo.ErrorLog VALUES (@name, @numb, @stat, @sevr, @line, @proc, @mess, @date);
RAISERROR ('InsertDbBackups: %d: %s', 16, 1, @numb, @mess);

END CATCH
END;
GO
