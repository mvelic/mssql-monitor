-- =============================================
-- Author:		Matt Velic
-- Create date: 07/24/2019
-- Description:	Run the monitoring collection in proper order
-- Change Log: 07/24/2019 - Initial procedure
-- =============================================
CREATE PROCEDURE dbo.ExecuteDatabaseMonitoring
AS
BEGIN;
SET NOCOUNT ON;

DECLARE @trancount INT;
SET @trancount = @@trancount;

BEGIN TRY
IF @trancount = 0
	BEGIN TRANSACTION
ELSE
	SAVE TRANSACTION ExecuteDatabaseMonitoring;

-- Run collections
EXECUTE dbo.InsertDatabaseProperties;
EXECUTE dbo.InsertDbBackups;
EXECUTE dbo.InsertFileSizeSpaceByDb;
EXECUTE dbo.InsertOSInfo;

EXECUTE dbo.InsertServerConfigurations;
EXECUTE dbo.InsertServerProperties;
EXECUTE dbo.InsertSignalWaits;
EXECUTE dbo.InsertSystemMemory;

EXECUTE dbo.InsertTransactionLogSpaceByDb;
EXECUTE dbo.InsertVolumeInfo;
EXECUTE dbo.InsertWaitStats;

-- Cleanup older data
EXECUTE dbo.DeleteOlderMonitoringData;

-- Reset Wait Statistics
DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);

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
	ROLLBACK TRANSACTION ExecuteDatabaseMonitoring;

INSERT INTO dbo.ErrorLog VALUES (@name, @numb, @stat, @sevr, @line, @proc, @mess, @date);
RAISERROR ('ExecuteDatabaseMonitoring: %d: %s', 16, 1, @numb, @mess);

END CATCH
END;
GO
