USE MssqlMonitor;
GO

/*

SEEDING MONITORING VALUES

*/
-- dbo.KeyValue
INSERT INTO dbo.KeyValue ([Key], [Value]) VALUES
('DaysRetention', '90');

-- dbo.IgnoredWaitTypes
-- note: this was just a starting point as of a few years ago (~2016),
--       please add more unhelpful wait types as needed
INSERT INTO dbo.IgnoredWaitTypes (WaitType) VALUES
('CLR_SEMAPHORE'),
('LAZYWRITER_SLEEP'),
('RESOURCE_QUEUE'),
('SLEEP_TASK'),
('SLEEP_SYSTEMTASK'),
('SQLTRACE_BUFFER_FLUSH'),
('WAITFOR'),
('LOGMGR_QUEUE'),
('CHECKPOINT_QUEUE'),
('REQUEST_FOR_DEADLOCK_SEARCH'),
('XE_TIMER_EVENT'),
('BROKER_TO_FLUSH'),
('BROKER_TASK_STOP'),
('CLR_MANUAL_EVENT'),
('CLR_AUTO_EVENT'),
('DISPATCHER_QUEUE_SEMAPHORE'),
('FT_IFTS_SCHEDULER_IDLE_WAIT'),
('XE_DISPATCHER_WAIT'),
('XE_DISPATCHER_JOIN'),
('SQLTRACE_INCREMENTAL_FLUSH_SLEEP'),
('ONDEMAND_TASK_QUEUE'),
('BROKER_EVENTHANDLER'),
('SLEEP_BPOOL_FLUSH'),
('SLEEP_DBSTARTUP'),
('DIRTY_PAGE_POLL'),
('HADR_FILESTREAM_IOMGR_IOCOMPLETION'),
('SP_SERVER_DIAGNOSTICS_SLEEP');

-- dbo.DatabasesToMonitor
-- note: Add any/all databases that you would like to be monitored.
--       For database-level (vs server-level) monitoring queries.
--       This is helpful when on a shared server and you only need
--       stats for a some, but not all, databases on the server.
--       If you'd like all, delete the individual insertions and 
--       uncomment the query.
INSERT INTO dbo.DatabasesToMonitor (DatabaseName)
VALUES
('MssqlMonitor'),
('DatabaseOne'),
('DatabaseTwo')
('etc...');
-- SELECT d.[name]
-- FROM sys.databases d
-- ORDER BY d.[name];
GO
