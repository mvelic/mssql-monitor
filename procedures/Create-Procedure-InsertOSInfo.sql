-- =============================================
-- Author:		Matt Velic
-- Create date: 07/24/2019
-- Description:	Weekly collection of operating system information
-- Change Log: 07/24/2019 - Initial procedure
-- =============================================
CREATE PROCEDURE dbo.InsertOSInfo
AS
BEGIN;
SET NOCOUNT ON;

DECLARE @trancount INT;
SET @trancount = @@trancount;

BEGIN TRY
IF @trancount = 0
	BEGIN TRANSACTION
ELSE
	SAVE TRANSACTION InsertOSInfo;

INSERT INTO dbo.OSInfo (
	DateCollected
	,SQLServerStartTime
	,CPUCount
	,HyperthreadRatio
	,PhysicalMemory_MB
)
SELECT
	DateCollected = GETDATE()
	,SQLServerStartTime = i.sqlserver_start_time
	,CPUCount = i.cpu_count
	,HyperthreadRatio = i.hyperthread_ratio
	,PhysicalMemory_MB = CONVERT(BIGINT, i.physical_memory_kb / 1024 )
FROM sys.dm_os_sys_info i

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
	ROLLBACK TRANSACTION InsertOSInfo;

INSERT INTO dbo.ErrorLog VALUES (@name, @numb, @stat, @sevr, @line, @proc, @mess, @date);
RAISERROR ('InsertOSInfo: %d: %s', 16, 1, @numb, @mess);

END CATCH
END;
GO
