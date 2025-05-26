-- =============================================
-- Author:		Matt Velic
-- Create date: 07/24/2019
-- Description: Weekly collection to verify CPU pressure
-- Change Log: 07/24/2019 - Initial procedure
-- =============================================
CREATE PROCEDURE dbo.InsertSignalWaits
AS
BEGIN;
SET NOCOUNT ON;

DECLARE @trancount INT;
SET @trancount = @@trancount;

BEGIN TRY
IF @trancount = 0
	BEGIN TRANSACTION
ELSE
	SAVE TRANSACTION InsertSignalWaits;

INSERT INTO dbo.SignalWaits (
	DateCollected 
	,SignalCpuWaits 
	,ResourceWaits 
)
SELECT
	  DateCollected = GETDATE()
	 ,SignalCpuWaits = CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) 
	 ,ResourceWaits =  CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) 
FROM sys.dm_os_wait_stats WITH (NOLOCK) OPTION (RECOMPILE);

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
	ROLLBACK TRANSACTION InsertSignalWaits;

INSERT INTO dbo.ErrorLog VALUES (@name, @numb, @stat, @sevr, @line, @proc, @mess, @date);
RAISERROR ('InsertSignalWaits: %d: %s', 16, 1, @numb, @mess);

END CATCH
END;
GO
