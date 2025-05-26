-- =============================================
-- Author:		Matt Velic
-- Create date: 07/24/2019
-- Description:	Weekly collection to monitor Transaction Log
--              usage in each database
-- Change Log: 07/24/2019 - Initial procedure
-- =============================================
CREATE PROCEDURE dbo.InsertTransactionLogSpaceByDb
AS
BEGIN;
SET NOCOUNT ON;

DECLARE @trancount INT;
SET @trancount = @@trancount;

BEGIN TRY
IF @trancount = 0
	BEGIN TRANSACTION
ELSE
	SAVE TRANSACTION InsertTransactionLogSpaceByDb;

CREATE TABLE #temp (
	DateCollected DATETIME NOT NULL
	,DatabaseName NVARCHAR(128) NULL
	,TotalLogSize_MB DECIMAL(10,1) NULL
	,UsedLogSpace_MB DECIMAL(10,1) NULL
	,UsedLogSpace_PCT DECIMAL(10,1) NULL
);

EXEC sp_MSforeachdb 'USE [?]

INSERT INTO #temp (
	DateCollected
	,DatabaseName
	,TotalLogSize_MB
	,UsedLogSpace_MB
	,UsedLogSpace_PCT
)
SELECT
	DateCollected = GETDATE()
	,DatabaseName = DB_NAME(database_id)
	,TotalLogSize_MB = CAST((total_log_size_in_bytes/1048576.0) AS DECIMAL(10,1))
	,UsedLogSpace_MB = CAST((used_log_space_in_bytes/1048576.0) AS DECIMAL(10,1))
	,UsedLogSpace_PCT = CAST(used_log_space_in_percent AS DECIMAL(10,1))
FROM sys.dm_db_log_space_usage WITH (NOLOCK) OPTION (RECOMPILE);'

INSERT INTO dbo.TransactionLogSpaceByDb (
	DateCollected
	,DatabaseName
	,TotalLogSize_MB
	,UsedLogSpace_MB
	,UsedLogSpace_PCT
)
SELECT
	DateCollected = t.DateCollected
	,DatabaseName = t.DatabaseName
	,TotalLogSize_MB = t.TotalLogSize_MB
	,UsedLogSpace_MB = t.UsedLogSpace_MB
	,UsedLogSpace_PCT = t.UsedLogSpace_PCT
FROM #temp t
JOIN dbo.DatabasesToMonitor d
	ON t.DatabaseName = d.DatabaseName
ORDER BY t.DatabaseName ASC;

DROP TABLE #temp;

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
	ROLLBACK TRANSACTION InsertTransactionLogSpaceByDb;

INSERT INTO dbo.ErrorLog VALUES (@name, @numb, @stat, @sevr, @line, @proc, @mess, @date);
RAISERROR ('InsertTransactionLogSpaceByDb: %d: %s', 16, 1, @numb, @mess);

END CATCH
END;
GO
