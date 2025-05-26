-- =============================================
-- Author:		Matt Velic
-- Create date: 07/24/2019
-- Description:	Weekly collection of server configurations 
--              that can affect query performance
-- Change Log: 07/24/2019 - Initial procedure
-- =============================================
CREATE PROCEDURE dbo.InsertServerConfigurations
AS
BEGIN;
SET NOCOUNT ON;

DECLARE @trancount INT;
SET @trancount = @@trancount;

BEGIN TRY
IF @trancount = 0
	BEGIN TRANSACTION
ELSE
	SAVE TRANSACTION InsertServerConfigurations;

INSERT INTO dbo.ServerConfigurations (
	DateCollected
	,Name
	,Value
	,ValueInUse
	,[Description]
)
SELECT 
	DateCollected = GETDATE()
	,Name = c.name
	,Value =  c.value
	,ValueInUse = c.value_in_use
	,[Description] = c.[description]
FROM sys.configurations c WITH (NOLOCK)
WHERE name IN (
	'Ad Hoc Distributed Queries'
	,'backup compression default'
	,'cost threshold for parallelism'
	,'default trace enabled'
	,'fill factor (%)'
	,'max degree of parallelism'
	,'max server memory (MB)'
	,'lightweight pooling'
	,'optimize for ad hoc workloads'
	,'priority boost'
	)
ORDER BY name OPTION (RECOMPILE);

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
	ROLLBACK TRANSACTION InsertServerConfigurations;

INSERT INTO dbo.ErrorLog VALUES (@name, @numb, @stat, @sevr, @line, @proc, @mess, @date);
RAISERROR ('InsertServerConfigurations: %d: %s', 16, 1, @numb, @mess);

END CATCH
END;
GO
