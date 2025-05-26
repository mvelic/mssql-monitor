-- =============================================
-- Author:		Matt Velic
-- Create date: 07/24/2019
-- Description:	Weekly collection of the top Wait Stats
--              affecting the server as a whole
-- Change Log: 07/24/2019 - Initial procedure
-- =============================================
CREATE PROCEDURE dbo.InsertWaitStats
AS
BEGIN;
SET NOCOUNT ON;

DECLARE @trancount INT;
SET @trancount = @@trancount;

BEGIN TRY
IF @trancount = 0
	BEGIN TRANSACTION
ELSE
	SAVE TRANSACTION InsertWaitStats;

;WITH Waits AS (
	SELECT
		DateCollected = GETDATE()
		,WaitType = wait_type
		,WaitTime_S = CAST(wait_time_ms / 1000.0 AS DECIMAL(12, 2))
		,PCT = CAST(100.0 * wait_time_ms / SUM(wait_time_ms) OVER () AS DECIMAL(12,2))
		,Running_PCT=ROW_NUMBER() OVER (ORDER BY wait_time_ms DESC)
	FROM sys.dm_os_wait_stats WITH (NOLOCK)
	WHERE wait_type NOT IN (SELECT WaitType FROM dbo.IgnoredWaitTypes)
), Running_Waits AS (
	SELECT
		DateCollected = w.DateCollected
		,WaitType = w.WaitType
		,WaitTime_S = w.WaitTime_S
		,PCT = w.PCT
		,Running_PCT = SUM(w.PCT) OVER (ORDER BY w.PCT DESC ROWS UNBOUNDED PRECEDING)
	FROM Waits w
)
INSERT INTO dbo.WaitStats (
	DateCollected
	,WaitType 
	,WaitTime_S 
	,PCT 
	,Running_PCT
)
SELECT
	DateCollected = r.DateCollected
	,WaitType = r.WaitType
	,WaitTime_S = r.WaitTime_S
	,PCT = r.PCT
	,Running_PCT = r.Running_PCT
FROM Running_Waits r
WHERE r.Running_PCT - r.PCT <= 99
ORDER BY Running_PCT OPTION (RECOMPILE);

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
	ROLLBACK TRANSACTION InsertWaitStats;

INSERT INTO dbo.ErrorLog VALUES (@name, @numb, @stat, @sevr, @line, @proc, @mess, @date);
RAISERROR ('InsertWaitStats: %d: %s', 16, 1, @numb, @mess);

END CATCH
END;
GO
