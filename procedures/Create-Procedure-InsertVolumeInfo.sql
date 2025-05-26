-- =============================================
-- Author:		Matt Velic
-- Create date: 07/24/2019
-- Description:	Weekly collection to monitor storage volume values
-- Change Log: 07/24/2019 - Initial procedure
-- =============================================
CREATE PROCEDURE dbo.InsertVolumeInfo
AS
BEGIN;
SET NOCOUNT ON;

DECLARE @trancount INT;
SET @trancount = @@trancount;

BEGIN TRY
IF @trancount = 0
	BEGIN TRANSACTION
ELSE
	SAVE TRANSACTION InsertVolumeInfo;

INSERT INTO dbo.VolumeInfo (
	DateCollected 
	,DatabaseName 
	,FileId 
	,VolumeMountPoint 
	,TotalSize_GB 
	,AvailableSize_GB 
	,SpaceFree_PCT 
)
SELECT 
	DateCollected = GETDATE()
	,DatabaseName = DB_NAME(f.database_id) 
	,FileId = f.file_id
	,VolumeMountPoint = vs.volume_mount_point
	,TotalSize_GB = CONVERT(DECIMAL(18,2),vs.total_bytes/1073741824.0)
	,AvailableSize_GB = CONVERT(DECIMAL(18,2),vs.available_bytes/1073741824.0)
	,SpaceFree_PCT =   CAST(CAST(vs.available_bytes AS FLOAT)/ CAST(vs.total_bytes AS FLOAT) AS DECIMAL(18,2)) * 100
FROM sys.master_files AS f WITH (NOLOCK)
INNER JOIN dbo.DatabasesToMonitor dtm
	ON DB_NAME(f.database_id) = dtm.[DatabaseName]
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) AS vs
ORDER BY f.database_id OPTION (RECOMPILE);

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
	ROLLBACK TRANSACTION InsertVolumeInfo;

INSERT INTO dbo.ErrorLog VALUES (@name, @numb, @stat, @sevr, @line, @proc, @mess, @date);
RAISERROR ('InsertVolumeInfo: %d: %s', 16, 1, @numb, @mess);

END CATCH
END;
GO
