-- =============================================
-- Author:		Matt Velic
-- Create date: 07/24/2019
-- Description:	Weekly collection to monitor file sizes in each database
-- Change Log: 07/24/2019 - Initial procedure
-- =============================================
CREATE PROCEDURE dbo.InsertFileSizeSpaceByDb
AS
BEGIN;
SET NOCOUNT ON;

DECLARE @trancount INT;
SET @trancount = @@trancount;

BEGIN TRY
IF @trancount = 0
	BEGIN TRANSACTION
ELSE
	SAVE TRANSACTION InsertFileSizeSpaceByDb;

CREATE TABLE #temp (
	DateCollected DATETIME NOT NULL
	,DatabaseName SYSNAME NOT NULL
	,[FileName] SYSNAME NOT NULL
	,PhysicalName NVARCHAR(260) NOT NULL
	,TotalSize_MB DECIMAL(15,2) NOT NULL
	,AvailableSpace_MB DECIMAL(15,2) NOT NULL
	,FileId INT NOT NULL
	,FilegroupName SYSNAME NULL
);

EXEC sp_MSforeachdb 'USE [?]

INSERT INTO #temp (
	DateCollected
	,DatabaseName
	,[FileName]
	,PhysicalName
	,TotalSize_MB
	,AvailableSpace_MB
	,FileId
	,FilegroupName
)
SELECT 
	DateCollected = GETDATE()
	,DatabaseName = ''?''
	,[FileName] = f.name
	,PhysicalName = f.physical_name
	,TotalSize_MB = CAST((f.size/128.0) AS decimal(15,2))
	,AvailableSpace_MB = CAST(f.size/128.0 - CAST(FILEPROPERTY(f.name, ''SpaceUsed'') AS int)/128.0 AS decimal(15,2))
	,FileId = f.[file_id]
	,FilegroupName = fg.name
FROM sys.database_files AS f WITH (NOLOCK) 
LEFT OUTER JOIN sys.data_spaces AS fg WITH (NOLOCK) 
	ON f.data_space_id = fg.data_space_id OPTION (RECOMPILE);'

INSERT INTO dbo.FileSizeSpaceByDb(
	DateCollected
	,DatabaseName
	,[FileName]
	,PhysicalName
	,TotalSize_MB
	,AvailableSpace_MB
	,FileId
	,FilegroupName
)
SELECT
	DateCollected = t.DateCollected
	,DatabaseName = t.DatabaseName
	,[FileName] = t.[FileName]
	,PhysicalName = t.PhysicalName
	,TotalSize_MB = t.TotalSize_MB
	,AvailableSpace_MB = t.AvailableSpace_MB
	,FileId = t.FileId
	,FilegroupName = t.FilegroupName
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
	ROLLBACK TRANSACTION InsertFileSizeSpaceByDb;

INSERT INTO dbo.ErrorLog VALUES (@name, @numb, @stat, @sevr, @line, @proc, @mess, @date);
RAISERROR ('InsertFileSizeSpaceByDb: %d: %s', 16, 1, @numb, @mess);

END CATCH
END;
GO
