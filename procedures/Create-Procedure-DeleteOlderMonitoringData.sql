-- =============================================
-- Author:		Matt Velic
-- Create date: 07/24/2019
-- Description:	Does cleanup across the monitoring tables
-- Change Log: 07/24/2019 - Initial procedure
-- =============================================
CREATE PROCEDURE dbo.DeleteOlderMonitoringData
AS
BEGIN;
SET NOCOUNT ON;

DECLARE @trancount INT;
SET @trancount = @@trancount;

BEGIN TRY
IF @trancount = 0
	BEGIN TRANSACTION
ELSE
	SAVE TRANSACTION DeleteOlderMonitoringData;

DECLARE @key VARCHAR(60) = 'DaysRetention';
DECLARE @days INT = (SELECT CAST([Value] AS INT) FROM dbo.KeyValue WHERE [Key] = @key)

DELETE FROM dbo.DatabaseProperties
WHERE DATEDIFF(DAY, DateCollected, GETDATE()) > @days;

DELETE FROM dbo.DbBackups
WHERE DATEDIFF(DAY, DateCollected, GETDATE()) > @days;

DELETE FROM dbo.FileSizeSpaceByDb
WHERE DATEDIFF(DAY, DateCollected, GETDATE()) > @days;

DELETE FROM dbo.OSInfo
WHERE DATEDIFF(DAY, DateCollected, GETDATE()) > @days;

DELETE FROM dbo.ServerConfigurations
WHERE DATEDIFF(DAY, DateCollected, GETDATE()) > @days;

DELETE FROM dbo.ServerProperties
WHERE DATEDIFF(DAY, DateCollected, GETDATE()) > @days;

DELETE FROM dbo.SignalWaits
WHERE DATEDIFF(DAY, DateCollected, GETDATE()) > @days;

DELETE FROM dbo.SystemMemory
WHERE DATEDIFF(DAY, DateCollected, GETDATE()) > @days;

DELETE FROM dbo.TransactionLogSpaceByDb
WHERE DATEDIFF(DAY, DateCollected, GETDATE()) > @days;

DELETE FROM dbo.VolumeInfo
WHERE DATEDIFF(DAY, DateCollected, GETDATE()) > @days;

DELETE FROM dbo.WaitStats
WHERE DATEDIFF(DAY, DateCollected, GETDATE()) > @days;

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
	ROLLBACK TRANSACTION DeleteOlderMonitoringData;

INSERT INTO dbo.ErrorLog VALUES (@name, @numb, @stat, @sevr, @line, @proc, @mess, @date);
RAISERROR ('DeleteOlderMonitoringData: %d: %s', 16, 1, @numb, @mess);

END CATCH
END;
GO
