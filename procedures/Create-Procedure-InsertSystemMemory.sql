-- =============================================
-- Author:		Matt Velic
-- Create date: 07/24/2019
-- Description: Weekly collection to verify system memory usage
-- Change Log: 07/24/2019 - Initial procedure
-- =============================================
CREATE PROCEDURE dbo.InsertSystemMemory
AS
BEGIN;
SET NOCOUNT ON;

DECLARE @trancount INT;
SET @trancount = @@trancount;

BEGIN TRY
IF @trancount = 0
	BEGIN TRANSACTION
ELSE
	SAVE TRANSACTION InsertSystemMemory;

INSERT INTO dbo.SystemMemory (
	DateCollected 
	,PhysicalMemory_MB 
	,AvailableMemory_MB 
	,TotalPageFile_MB 
	,AvailablePageFile_MB 
	,SystemCache_MB 
	,SystemMemoryStateDescription 
)
SELECT
	DateCollected = GETDATE()
	,PhysicalMemory_MB = total_physical_memory_kb/1024 
	,AvailableMemory_MB = available_physical_memory_kb/1024 
	,TotalPageFile_MB =  total_page_file_kb/1024 
	,AvailablePageFile_MB = available_page_file_kb/1024 
	,SystemCache_MB = system_cache_kb/1024 
	,SystemMemoryStateDescription = system_memory_state_desc 
FROM sys.dm_os_sys_memory WITH (NOLOCK) OPTION (RECOMPILE);

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
	ROLLBACK TRANSACTION InsertSystemMemory;

INSERT INTO dbo.ErrorLog VALUES (@name, @numb, @stat, @sevr, @line, @proc, @mess, @date);
RAISERROR ('InsertSystemMemory: %d: %s', 16, 1, @numb, @mess);

END CATCH
END;
GO
