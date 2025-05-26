-- =============================================
-- Author:		Matt Velic
-- Create date: 07/24/2019
-- Description:	Weekly collection of properties (by database)
--              that can affect query performance
-- Change Log: 07/24/2019 - Initial procedure
-- =============================================
CREATE PROCEDURE dbo.InsertDatabaseProperties
AS
BEGIN;
SET NOCOUNT ON;

DECLARE @trancount INT;
SET @trancount = @@trancount;

BEGIN TRY
IF @trancount = 0
	BEGIN TRANSACTION
ELSE
	SAVE TRANSACTION InsertDatabaseProperties;

INSERT INTO dbo.DatabaseProperties (
	DateCollected 
	,DatabaseName 
	,RecoveryModel 
	,StateDescription 
	,LogReuseWaitDescription 
	,LogSize_MB 
	,LogUsed_MB 
	,LogUsed_PCT 
	,DbCompatibilityLevel 
	,PageVerifyOptionDescription 
	,IsAutoCreateStatsOn 
	,IsAutoUpdateStatsOn 
	,IsParameterizationForced 
	,SnapshotIsolationStateDescription 
	,IsReadCommittedSnapshotOn 
	,IsAutoShrinkOn 
	,IsCdcEnabled 
)
SELECT 
	DateCollected = GETDATE()
	,DatabaseName = db.[name] 
	,RecoveryModel = db.recovery_model_desc
	,StateDescription = db.state_desc
	,LogReuseWaitDescription = db.log_reuse_wait_desc 
	,LogSize_MB =  CONVERT(DECIMAL(18,2), ls.cntr_value/1024.0)
	,LogUsed_MB = CONVERT(DECIMAL(18,2), lu.cntr_value/1024.0)
	,LogUsed_PCT = CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT) AS DECIMAL(18,2)) * 100 
	,DbCompatibilityLevel =  db.[compatibility_level] 
	,PageVerifyOptionDescription = db.page_verify_option_desc 
	,IsAutoCreateStatsOn = db.is_auto_create_stats_on
	,IsAutoUpdateStatsOn = db.is_auto_update_stats_on
	,IsParameterizationForced = db.is_parameterization_forced
	,SnapshotIsolationStateDescription = db.snapshot_isolation_state_desc
	,IsReadCommittedSnapshotOn = db.is_read_committed_snapshot_on
	,IsAutoShrinkOn = db.is_auto_shrink_on
	,IsCdcEnabled = db.is_cdc_enabled
FROM sys.databases AS db WITH (NOLOCK)
INNER JOIN sys.dm_os_performance_counters AS lu WITH (NOLOCK)
	ON db.name = lu.instance_name
INNER JOIN sys.dm_os_performance_counters AS ls WITH (NOLOCK)
	ON db.name = ls.instance_name
INNER JOIN dbo.DatabasesToMonitor dtm
	ON db.[name] = dtm.[DatabaseName]
WHERE lu.counter_name LIKE N'Log File(s) Used Size (KB)%' 
	AND ls.counter_name LIKE N'Log File(s) Size (KB)%'
	AND ls.cntr_value > 0 OPTION (RECOMPILE); 

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
	ROLLBACK TRANSACTION InsertDatabaseProperties;

INSERT INTO dbo.ErrorLog VALUES (@name, @numb, @stat, @sevr, @line, @proc, @mess, @date);
RAISERROR ('InsertDatabaseProperties: %d: %s', 16, 1, @numb, @mess);

END CATCH
END;
GO
