###########################################################################
#						Created by David Seis							  #
#							  11/1/2022									  #
#																		  #
#					Straight Path IT Solutions, LLC.					  #
###########################################################################

<#---
Dependencies
-- Requires a current version of DBATools
-- Requires suffiecient privileges on each host and sql server

Changes:
2/15/2024 DS - Added Admin DB switches, full job choices, Whoisactive and First Responder switches

#>

<#-- Step 1 -- Check Connectivity  
#Priming Query check for connectivity to all the target servers - change the test targets to the servers you want to prep for.
$TestTargets = 'Lbsql1','Labsql2','Labsql3' #, '', '', '', '' target SQL server

Invoke-DbaQuery -SQLInstance $TestTargets -query "
/*~~~ Find Current Location of Data and Log File of All the Database ~~~*/
	SELECT @@servername as [Server name], TYPE_DESC, physical_name AS current_file_location 
	FROM sys.master_files 
    WHERE database_id > 4
    ORDER BY type_desc
"| Select * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | format-table
--#>

<#-- Step 2 -- Fill these variables and then run --#>


#The server where maintenance will be installed:
$SQLInstance = 'Labsql3'

#Create a management database? # 1 = yes, 0 = No . PICK DEFAULT OR CUSTOM for the database fiel locations, NOT BOTH#>

    $AdminDatabase = 'Admin'
    
        $YesWithCUSTOMlocation = 0
            $DBDataLoc = 'D:\SQLDATA\' #'E:\SQLData\' #where DB admin data files will be put
            $DBLogLoc = 'L:\SQLLogs\' #'L:\SQLLogs\' # where DB admin logs will be put
    
        $YesWithDEFAULTlocation = 0

    <# USE THIS TO CHECK CURRENT DEFAULT data and log LOCATIONS
        $SQLInstance = 'LabSQL3'
        Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true
        Invoke-DbaQuery -SQLInstance $SQLInstance -query "SELECT @@servername as [Server name] , SERVERPROPERTY('InstanceDefaultDataPath') as [Default DATA] , SERVERPROPERTY('InstanceDefaultLogPath') as [Default LOG]
        " | format-table
    #>


#Ola Parameters
$olaParams = @{
    CleanupTime = 336 #number of hours backups will be retained
    BackupLocation = '\\labshare\SQLBackups' #Backup location for OLA jobs
    SqlInstance = $SqlInstance
    Database = ''
    InstallJobs = $true
    LogToTable = $true
    Verbose = $false # this shows ola install alerts during install
}


<#FirstResponder and WhoIsActive#>
$FirstResponderDB = 'master'# Where First Responder stored procedures will be installed
$SPWhoisactiveDB = 'master' # Where Whoisactive stored procedures will be installed


<#Job Enabled/Disabled Choices #> 
#1 = enabled, 0 = disabled
$SystemFULLBackups = 1 # System full backups
$UserFULLBackups = 1   # User full backup 
$UserDIFFBackups = 1   # User diff backup 
$UserLOGBackups = 1    # User log backup 
$UserIntegrity = 1     # User DB Integrity checks 
$SystemIntegrity = 1   # System DB integrity checks 
$indexOptimize = 1      
$CommandLogCleanup = 1 
$CycleErrorLog = 1 
$OutputFileCleanup = 1
$DeleteBackupHistory = 1
$PurgeJobHistory = 1
$Whoisactive = 1





<#====================================================================================================#>
<#====================================================================================================#>
<#==========                        Nothing more needs to be done. F5                        =========#>
<#====================================================================================================#>
<#====================================================================================================#>


Write-Host "Admin Database: Preparing to create [$AdminDatabase] Database..." -ForegroundColor Green
IF($YesWithCUSTOMlocation -eq 1 -AND $YesWithDEFAULTlocation -eq 1) {
    Write-Host "Admin Database: Failed to Create $AdminDatabase, You need to pick either DEFAULT or CUSTOM location in the global variables." -ForegroundColor RED -BackgroundColor Black
    Return
} ELSEIF ($YesWithDEFAULTlocation -eq 1) {
    Write-Host "Admin Database: Create $AdminDatabase using the Server default data and log locations..." -ForegroundColor Green
    Invoke-DbaQuery -SQLInstance $SQLInstance -Query "
    CREATE DATABASE [$AdminDatabase];
    GO
    ALTER DATABASE [$AdminDatabase] MODIFY FILE (NAME = N'$AdminDatabase' , SIZE = 512 MB , FILEGROWTH = 128 MB , MAXSIZE = 10240 MB );
    GO
    ALTER DATABASE [$AdminDatabase] MODIFY FILE (NAME = N'$AdminDatabase`_log' , SIZE = 256 MB , FILEGROWTH = 32 MB , MAXSIZE = 2048 MB);
    GO
    Select name, 'Created' as Note from sys.databases where name like '%$AdminDatabase%'
    "
} ELSEIF ($YesWithCUSTOMlocation -eq 1) {
    Write-Host "Admin Database: Create $AdminDatabase with Custom data and log locations..." -ForegroundColor Green
    Invoke-DbaQuery -SQLInstance $SQLInstance -Query "

    CREATE DATABASE [$AdminDatabase] ON PRIMARY 
    ( NAME = N'$AdminDatabase', FILENAME = N'$($DBDataLoc+$AdminDatabase).mdf' , SIZE = 512 MB , FILEGROWTH = 128 MB , MAXSIZE = 10240 MB )
    LOG ON 
    ( NAME = N'$AdminDatabase`_log', FILENAME = N'$($DBLogLoc+$AdminDatabase)_log.ldf' , SIZE = 256 MB , FILEGROWTH = 32 MB , MAXSIZE = 2048 MB) 
    Select name, 'Created' as Note from sys.databases where name like '%$AdminDatabase%'
    "

} ELSE {
    Write-Host "Admin Database: Flags were not chosen, no database will be created" -ForegroundColor DarkYellow
    Return
}

Write-Host "Community Tools: Installing First Responder..." -ForegroundColor Green
Install-DbaFirstResponderKit -SqlInstance $SQLInstance -Database $FirstResponderDB
Write-Host "Community Tools: Installing WhoIsActive (with $AdminDatabase as host DB unless you changed this above)..." -ForegroundColor Green
Install-DbaWhoIsActive -SqlInstance $SqlInstance -Database $SPWhoisactiveDB


Write-Host "Ola Maintenance: Install OLA..." -ForegroundColor Green
Install-DbaMaintenanceSolution @olaParams

Write-Host "Ola Maintenance: Add Recommended OLA Schedules..." -ForegroundColor Green
Invoke-DbaQuery -SQLInstance $SQLInstance -Query "

USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DatabaseIntegrityCheck - USER_DATABASES', @name=N'Weekly - User Integrity Check', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=64, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20181229, 
		@active_end_date=99991231, 
		@active_start_time=200000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'CommandLog Cleanup', @name=N'Weekly - Command Log Cleanup', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=32, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20181229, 
		@active_end_date=99991231, 
		@active_start_time=120000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DatabaseBackup - SYSTEM_DATABASES - FULL', @name=N'Daily - System Full Backups', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20190103, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DatabaseBackup - USER_DATABASES - DIFF', @name=N'Weekday DIFFS', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=126, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20190103, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DatabaseBackup - USER_DATABASES - FULL', @name=N'Weekly User Full Backups', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20190103, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DatabaseBackup - USER_DATABASES - LOG', @name=N'15 Minute User Log Backups', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=127, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20190103, 
		@active_end_date=99991231, 
		@active_start_time=00000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DatabaseIntegrityCheck - SYSTEM_DATABASES', @name=N'Daily System Integrity Check', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20190103, 
		@active_end_date=99991231, 
		@active_start_time=03000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'IndexOptimize - USER_DATABASES', @name=N'Weekly Index Optimize ', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20190103, 
		@active_end_date=99991231, 
		@active_start_time=40000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'Output File Cleanup', @name=N'Weekly Output File Cleanup', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=32, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20190103, 
		@active_end_date=99991231, 
		@active_start_time=230000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'sp_delete_backuphistory', @name=N'Weekly Delete BackupHistory', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=32, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20190103, 
		@active_end_date=99991231, 
		@active_start_time=230500, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'sp_purge_jobhistory', @name=N'Weekly Purge jobHistory', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=32, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20190103, 
		@active_end_date=99991231, 
		@active_start_time=230000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
"

Write-Host "Community Tools: Add WhoIsActive Job..." -ForegroundColor Green
Invoke-DbaQuery -SQLInstance $SQLInstance -Query "
/************************ This creates a job that runs sp_whoisactive every minute and logs to $AdminDatabase.dbo.WhoIsActive table and retains the data for 3 days. *************************
************************* If using this be sure to cap the size of $AdminDatabase so that it doesn't fill a drive. **************************************************************************/

USE [msdb]
GO

/****** Object:  Job [sp_whoisactive data collection monitoring]    Script Date: 8/20/2019 9:52:13 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Data Collector]    Script Date: 8/20/2019 9:52:13 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Data Collector' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Data Collector'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'_MAINT_sp_whoisactive data collection monitoring', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Data Collector', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Step1]    Script Date: 8/20/2019 9:52:13 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Step1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET NOCOUNT ON;

DECLARE @retention INT = 3,
        @destination_table VARCHAR(500) = ''WhoIsActive'',
        @destination_database sysname = ''$AdminDatabase'',
        @schema VARCHAR(MAX),
        @SQL NVARCHAR(4000),
        @parameters NVARCHAR(500),
        @exists BIT;

SET @destination_table = @destination_database + ''.dbo.'' + @destination_table;

--create the logging table
IF OBJECT_ID(@destination_table) IS NULL
    BEGIN;
        EXEC dbo.sp_WhoIsActive @get_transaction_info = 1,
                                @get_outer_command = 1,
                                @get_plans = 1,
                                @return_schema = 1,
                                @schema = @schema OUTPUT;
        SET @schema = REPLACE(@schema, ''<table_name>'', @destination_table);
        EXEC ( @schema );
    END;

--create index on collection_time
SET @SQL
    = ''USE '' + QUOTENAME(@destination_database)
      + ''; IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(@destination_table) AND name = N''''cx_collection_time'''') SET @exists = 0'';
SET @parameters = N''@destination_table varchar(500), @exists bit OUTPUT'';
EXEC sys.sp_executesql @SQL, @parameters, @destination_table = @destination_table, @exists = @exists OUTPUT;

IF @exists = 0
    BEGIN;
        SET @SQL = ''CREATE CLUSTERED INDEX cx_collection_time ON '' + @destination_table + ''(collection_time ASC)'';
        EXEC ( @SQL );
    END;

--collect activity into logging table
EXEC dbo.sp_WhoIsActive @get_transaction_info = 1,
                        @get_outer_command = 1,
                        @get_plans = 1,
                        @destination_table = @destination_table;

--purge older data
SET @SQL
    = ''DELETE FROM '' + @destination_table + '' WHERE collection_time < DATEADD(day, -'' + CAST(@retention AS VARCHAR(10))
      + '', GETDATE());'';
EXEC ( @SQL );', 
		@database_name=N'$AdminDatabase', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'sp_whoisactive data collection monitoring', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20190806, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'fbe616c1-ac5c-4ada-8189-05e6a06ab438'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
"

Write-Host "Ola Maintenance: Enabling/ Disabling jobs..." -ForegroundColor Green
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_job -SqlParameter @{ job_name = "DatabaseBackup - USER_DATABASES - FULL"; enabled = $UserFULLBackups} -CommandType StoredProcedure
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_job -SqlParameter @{ job_name = "DatabaseBackup - USER_DATABASES - DIFF"; enabled = $UserDIFFBackups} -CommandType StoredProcedure
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_job -SqlParameter @{ job_name = "DatabaseBackup - USER_DATABASES - LOG"; enabled = $UserLOGBackups} -CommandType StoredProcedure
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_job -SqlParameter @{ job_name = "DatabaseBackup - SYSTEM_DATABASES - FULL"; enabled = $SystemFULLBackups} -CommandType StoredProcedure
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_job -SqlParameter @{ job_name = "DatabaseIntegritycheck - SYSTEM_DATABASES"; enabled = $SystemIntegrity} -CommandType StoredProcedure
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_job -SqlParameter @{ job_name = "DatabaseIntegritycheck - USER_DATABASES"; enabled = $UserIntegrity} -CommandType StoredProcedure
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_job -SqlParameter @{ job_name = "IndexOptimize - USER_DATABASES"; enabled = $indexOptimize} -CommandType StoredProcedure
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_job -SqlParameter @{ job_name = "CommandLog Cleanup"; enabled = $CommandLogCleanup} -CommandType StoredProcedure
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_job -SqlParameter @{ job_name = "CycleErrorLog"; enabled = $CycleErrorLog} -CommandType StoredProcedure
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_job -SqlParameter @{ job_name = "Output File Cleanup"; enabled = $OutputFileCleanup} -CommandType StoredProcedure
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_job -SqlParameter @{ job_name = "sp_delete_backuphistory"; enabled = $DeleteBackupHistory} -CommandType StoredProcedure
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_job -SqlParameter @{ job_name = "sp_purge_jobhistory"; enabled = $PurgeJobHistory} -CommandType StoredProcedure
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_job -SqlParameter @{ job_name = "sp_whoisactive data collection monitoring"; enabled = $Whoisactive} -CommandType StoredProcedure

Write-Host "Complete." -ForegroundColor Green