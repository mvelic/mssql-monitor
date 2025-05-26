# Create and Test Database Monitor SQL Agent Job

## Add a Processing Job to SQL Agent

1. Go to SSMS --> SQL Server Agent.
2. Right click on the Jobs folder, choose "New Job..."
3. Name the job "Database Monitor Processing"
4. Set the Owner to "sa"

5. Click on the Steps tab.
6. Create a new step.
7. Name the step "Run Monitoring"
8. Set the type to "Transact-SQL script (T-SQL)"
9. Set the database to "MssqlMonitor"
10. Type in the following command "EXECUTE dbo.ExecuteDatabaseMonitoring"
11. Click OK.

12. Click on the Schedules tab.
13. Create a new schedule.
14. Name the schedule "Weekly"
15. Set the schedule type to "Recurring" and "Enabled"
16. Set the frequency to "Weekly" and every "1" weeks on "Sunday"
17. Set Occurs once at "11:30:00 PM"
18. Click OK.

19. Click OK to create the job.

## Test the new Agent Job
1. Open the Job Activity Monitor in SSMS.
2. Find the Database Monitor Processing job.
3. Right click it, choose "Start Job at Step..."
4. Click Close once it finishes running.
5. Query the tables to ensure data was collected.
