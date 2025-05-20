as the file locations for tha administrtaion database that will hold the 
community tools.

#>

#Change the test targets to the servers you want to prep for.
$TestTargets = 'Seis-work' #, '', '', '', '' 

Invoke-DbaQuery -SQLInstance $TestTargets -SqlCredential $cred -query "
/*~~~ Find Current Location of Data and Log File of All the Database ~~~*/
SELECT 
@@servername as [Server name]
, TYPE_DESC
, physical_name AS current_file_location 
FROM sys.master_files 
--WHERE database_id > 4
ORDER BY type_desc
"| Select-object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | format-table

Invoke-DbaQuery -SQLInstance $TestTargets -SqlCredential $cred -query "
SELECT 
@@servername as [Server name]
, SERVERPROPERTY('InstanceDefaultDataPath') as default_data_path
, SERVERPROPERTY('InstanceDefaultlogPath') as default_log_path
"| Select-object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | Format-List 


<# variables to fill in prior to every maintenance rollout to customize the targets and reuslts. #>
<# -------------------------- STEP 2  ------------------------------------#>
<# ------------------- Fill In Variables ---------------------------------#>

<## Global Parameters ##>
<#Targets#> 

$Targets = 'Seis-Work'

<#Admin Database name#> 
$DatabaseName               = 'DB_Administration' # Database that will be created and where Ola will be installed


<#Admin Database File locations - PICK DEFAULT OR CUSTOM, NOT BOTH#>
# 1 = yes, 0 = No
    $CustomDBlocation = 0
        $DBDataLoc          = 'D:\SQLDATA\' #'E:\SQLData\' #where DB admin data files will be put
        $DBLogLoc           = 'L:\SQLLogs\' #'L:\SQLLogs\' # where DB admin logs will be put
    
    $DefaultDBlocation = 1

<# Community tools install locations #>
$FirstResponderDB           = 'master'# where First Responder will be installed
$SPWhoisactiveDB            = 'master' # where Whoisactive will be installed


<#Ola Parameters#>
$olaParams = @{
    CleanupTime             = 72
    BackupLocation          = '\\labshare\SQLBackups' #Backup location for OLA jobs
    Database                = $Databasename
    InstallJobs             = $true
    LogToTable              = $true
    Verbose                 = $false # this shows ola install alerts during install
}


<#Job Enabled/Disabled Choices #> 
#1 = enabled, 0 = disabled
$SystemFULLBackups          = 1 # System full backups
$UserFULLBackups            = 1 # User full backup 
$UserDIFFBackups            = 1 # User diff backup 
$UserLOGBackups             = 1 # User log backup 
$UserIntegrity              = 1 # User DB Integrity checks 
$SystemIntegrity            = 1 # System DB integrity checks 
$indexOptimize              = 1      
$CommandLogCleanup          = 1 
$CycleErrorLog              = 1 
$OutputFileCleanup          = 1
$DeleteBackupHistory        = 1
$PurgeJobHistory            = 1
$Whoisactive                = 1


Write-Host "Target variables have been stored"

<# Rollout script, uses the variables to roll out the selected maintenance options to the target server #>

Write-Host "Admin Database: Preparing to create [$DatabaseName] Database..." -ForegroundColor Green
IF($DefaultDBlocation -eq 1 -AND $CustomDBlocation -eq 1) {
    Write-Host "Admin Database: Failed to Create $databasename, You need to pick either DEFAULT or CUSTOM location in the global variables." -ForegroundColor RED -BackgroundColor Black
    Return
} ELSEIF ($DefaultDBlocation -eq 1) {
    Write-Host "Admin Database: Create $databasename using the Server default data and log locations..." -ForegroundColor Green
    Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $cred -Query "
    CREATE DATABASE [$databasename];
    GO
    ALTER DATABASE [$databasename] MODIFY FILE (NAME = N'$databasename' , SIZE = 512 MB , FILEGROWTH = 128 MB , MAXSIZE = 10240 MB );
    GO
    ALTER DATABASE [$databasename] MODIFY FILE (NAME = N'$databasename`_log' , SIZE = 256 MB , FILEGROWTH = 32 MB , MAXSIZE = 2048 MB);
    GO
    Select name, 'Created' as Note from sys.databases where name like '%$databasename%'
    " | Out-Null
} ELSEIF ($CustomDBlocation -eq 1) {
    Write-Host "Admin Database: Create $databasename with Custom data and log locations..." -ForegroundColor Green
    Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -Query "

    CREATE DATABASE [$databasename] ON PRIMARY 
    ( NAME = N'$databasename', FILENAME = N'$($DBDataLoc+$databasename).mdf' , SIZE = 512 MB , FILEGROWTH = 128 MB , MAXSIZE = 10240 MB )
    LOG ON 
    ( NAME = N'$databasename`_log', FILENAME = N'$($DBLogLoc+$databasename)_log.ldf' , SIZE = 256 MB , FILEGROWTH = 32 MB , MAXSIZE = 2048 MB) 
    Select name, 'Created' as Note from sys.databases where name like '%$databasename%'
    
    " | Out-Null

} ELSE {
    Write-Host "Admin Database: Failed to Create $databasename, You need to pick either DEFAULT or CUSTOM location in the global variables." -ForegroundColor RED -BackgroundColor Black
    Return
}


Write-Host "Admin Database: Set $databasename Defaults..." -ForegroundColor Green
Start-Sleep -Seconds 1.5 

Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -Query "
ALTER DATABASE [$databasename] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [$databasename] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [$databasename] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [$databasename] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [$databasename] SET ARITHABORT OFF 
GO
ALTER DATABASE [$databasename] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [$databasename] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [$databasename] SET AUTO_CREATE_STATISTICS ON
GO
ALTER DATABASE [$databasename] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [$databasename] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [$databasename] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [$databasename] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [$databasename] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [$databasename] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [$databasename] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [$databasename] SET DISABLE_BROKER 
GO
ALTER DATABASE [$databasename] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [$databasename] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [$databasename] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [$databasename] SET READ_COMMITTED_SNAPSHOT ON 
GO
ALTER DATABASE [$databasename] SET READ_WRITE 
GO
ALTER DATABASE [$databasename] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [$databasename] SET MULTI_USER 
GO
ALTER DATABASE [$databasename] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [$databasename] SET TARGET_RECOVERY_TIME = 60 SECONDS
GO
USE [$databasename]
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [$databasename] MODIFY FILEGROUP [PRIMARY] DEFAULT
GO
USE [$databasename]
EXEC sp_changedbowner 'sa';
" | Out-Null
Start-Sleep -Seconds 1.5


Write-Host "Ola Maintenance: Install OLA..." -ForegroundColor Green
Install-DbaMaintenanceSolution -sqlinstance $Targets -sqlcredential $Cred @olaParams | Out-Null

Start-Sleep -Seconds 1.5

Write-Host "Ola Maintenance: Rename OLA Jobs..." -ForegroundColor Green
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -Query "
USE [msdb]
EXEC msdb.dbo.sp_update_job @job_name=N'CommandLog Cleanup', @new_name=N'_MAINT_CommandLog Cleanup'
EXEC msdb.dbo.sp_update_job @job_name=N'DatabaseBackup - SYSTEM_DATABASES - FULL', @new_name=N'_MAINT_DatabaseBackup - SYSTEM_DATABASES - FULL'
EXEC msdb.dbo.sp_update_job @job_name=N'DatabaseBackup - USER_DATABASES - DIFF', @new_name=N'_MAINT_DatabaseBackup - USER_DATABASES - DIFF'
EXEC msdb.dbo.sp_update_job @job_name=N'DatabaseBackup - USER_DATABASES - FULL', @new_name=N'_MAINT_DatabaseBackup - USER_DATABASES - FULL'
EXEC msdb.dbo.sp_update_job @job_name=N'DatabaseBackup - USER_DATABASES - LOG', @new_name=N'_MAINT_DatabaseBackup - USER_DATABASES - LOG'
EXEC msdb.dbo.sp_update_job @job_name=N'DatabaseIntegrityCheck - SYSTEM_DATABASES', @new_name=N'_MAINT_DatabaseIntegrityCheck - SYSTEM_DATABASES'
EXEC msdb.dbo.sp_update_job @job_name=N'DatabaseIntegrityCheck - USER_DATABASES', @new_name=N'_MAINT_DatabaseIntegrityCheck - USER_DATABASES'
EXEC msdb.dbo.sp_update_job @job_name=N'IndexOptimize - USER_DATABASES', @new_name=N'_MAINT_IndexOptimize - USER_DATABASES'
EXEC msdb.dbo.sp_update_job @job_name=N'sp_delete_backuphistory', @new_name=N'_MAINT_sp_delete_backuphistory'
EXEC msdb.dbo.sp_update_job @job_name=N'sp_purge_jobhistory', @new_name=N'_MAINT_sp_purge_jobhistory'
EXEC msdb.dbo.sp_update_job @job_name=N'Output File Cleanup', @new_name=N'_MAINT_Output File Cleanup'
GO
" | Out-Null

Start-Sleep -Seconds 1.5

Write-Host "Ola Maintenance: Adjust OLA Job Settings, number of error logs, max jobhistory..." -ForegroundColor Green
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -Query "
-- modify to pull servername from @@servername

USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'_MAINT_CycleErrorLog', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'SA', @job_id = @jobId OUTPUT
select @jobId
GO
declare @servername1 varchar(50);
   select @servername1=@@servername
EXEC msdb.dbo.sp_add_jobserver @job_name=N'_MAINT_CycleErrorLog', @server_name = @servername1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'_MAINT_CycleErrorLog', @step_name=N'Cycle SQL Server Error Log', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Exec sys.sp_cycle_errorlog ', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'_MAINT_CycleErrorLog', @step_name=N'Cycle SQL Agent LogExec dbo.sp_cycle_agent_errorlog', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Exec msdb.dbo.sp_cycle_agent_errorlog', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_CycleErrorLog', 
		@enabled=0, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'SA', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
GO

USE [master]
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', REG_DWORD, 52
GO

USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=10000
GO
" | Out-Null
Start-Sleep -Seconds 1.5

Write-Host "Ola Maintenance: Add Straight Path and Ola Job Schedules..." -ForegroundColor Green
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -Query "
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'_MAINT_CycleErrorLog', @name=N'Weekly - Cycle Error Log', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=64, 
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
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'_MAINT_DatabaseIntegrityCheck - USER_DATABASES', @name=N'Weekly - User Integrity Check', 
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
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'_MAINT_CommandLog Cleanup', @name=N'Weekly - Command Log Cleanup', 
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
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'_MAINT_DatabaseBackup - SYSTEM_DATABASES - FULL', @name=N'Daily - System Full Backups', 
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
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'_MAINT_DatabaseBackup - USER_DATABASES - DIFF', @name=N'Weekday DIFFS', 
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
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'_MAINT_DatabaseBackup - USER_DATABASES - FULL', @name=N'Weekly User Full Backups', 
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
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'_MAINT_DatabaseBackup - USER_DATABASES - LOG', @name=N'15 Minute User Log Backups', 
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
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'_MAINT_DatabaseIntegrityCheck - SYSTEM_DATABASES', @name=N'Daily System Integrity Check', 
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
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'_MAINT_IndexOptimize - USER_DATABASES', @name=N'Weekly Index Optimize ', 
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
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'_MAINT_Output File Cleanup', @name=N'Weekly Output File Cleanup', 
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
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'_MAINT_sp_delete_backuphistory', @name=N'Weekly Delete BackupHistory', 
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
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'_MAINT_sp_purge_jobhistory', @name=N'Weekly Purge jobHistory', 
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
" | Out-Null

Start-Sleep -Seconds 1.5

Write-Host "Ola Maintenance: Adjust Indexoptimize Job Step to Straight Path Standard..." -ForegroundColor Green
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -Query "
USE [msdb]
EXEC msdb.dbo.sp_update_jobstep @job_name=N'_MAINT_IndexOptimize - USER_DATABASES', @step_id=1 , @subsystem=N'TSQL', 
		@command=N'EXECUTE dbo.IndexOptimize
@Databases = ''USER_DATABASES'', 
@FragmentationLow = NULL,
@FragmentationMedium = ''INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'',
@FragmentationHigh = ''INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE,INDEX_REORGANIZE'',
@FragmentationLevel1 = 50, @FragmentationLevel2 = 80,
@UpdateStatistics = ''ALL'',
@OnlyModifiedStatistics = ''Y'', 
@LogToTable = ''Y'''
GO
" | Out-Null

Start-Sleep -Seconds 1.5

Write-Host "Ola Maintenance: Add Alerts..." -ForegroundColor Green
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -Query "
EXEC msdb.dbo.sp_add_alert @name=N'Severity 16 Error', 
		@message_id=0, 
		@severity=16, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_alert @name=N'Severity 17 Error', 
		@message_id=0, 
		@severity=17, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_alert @name=N'Severity 18 Error', 
		@message_id=0, 
		@severity=18, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_alert @name=N'Severity 19 Error', 
		@message_id=0, 
		@severity=19, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_alert @name=N'Severity 20 Error', 
		@message_id=0, 
		@severity=20, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_alert @name=N'Severity 21 Error', 
		@message_id=0, 

		@severity=21, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_alert @name=N'Severity 22 Error', 
		@message_id=0, 
		@severity=22, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_alert @name=N'Severity 23 Error', 
		@message_id=0, 
		@severity=23, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_alert @name=N'Severity 24 Error', 
		@message_id=0, 
		@severity=24, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_alert @name=N'Severity 25 Error', 
		@message_id=0, 
		@severity=25, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_alert @name=N'Error 823', 
		@message_id=823, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_alert @name=N'Error 824', 
		@message_id=824, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_alert @name=N'Error 825', 
		@message_id=825, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000';
GO
" | Out-Null
Start-Sleep -Seconds 1.5


Write-Host "Community Tools: Installing First Responder..." -ForegroundColor Green
Install-DbaFirstResponderKit -sqlinstance $Targets -sqlcredential $Cred -Database $FirstResponderDB | Out-Null
Write-Host "Community Tools: Installing WhoIsActive (with $databasename as host DB unless you changed this above)..." -ForegroundColor Green
Install-DbaWhoIsActive -SqlInstance $SqlInstance -SqlCredential $cred -Database $SPWhoisactiveDB | Out-Null

Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -query "
Select @@SERVERNAME, 'Whosiactive Table Dropped'
USE master
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[$databasename].[dbo].[WhoIsActive]') AND type in (N'U'))
DROP TABLE [$databasename].[dbo].[WhoIsActive];
GO
" | Format-Table -AutoSize

Start-Sleep -Seconds 1.5
Write-Host "Community Tools: Add WhoIsActive Job..." -ForegroundColor Green
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -Query "
/************************ This creates a job that runs sp_whoisactive every minute and logs to $databasename.dbo.WhoIsActive table and retains the data for 3 days. *************************
************************* If using this be sure to cap the size of $databasename so that it doesn't fill a drive. **************************************************************************/

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
        @destination_database sysname = ''$databasename'',
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
		@database_name=N'$databasename', 
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
" | Out-Null
Start-Sleep -Seconds 1.5


Write-Host "Ola Maintenance: Enabling/ Disabling jobs..." -ForegroundColor Green
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -database msdb -Query sp_update_job -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - USER_DATABASES - FULL"; enabled = $UserFULLBackups} -CommandType StoredProcedure
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -database msdb -Query sp_update_job -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - USER_DATABASES - DIFF"; enabled = $UserDIFFBackups} -CommandType StoredProcedure
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -database msdb -Query sp_update_job -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - USER_DATABASES - LOG"; enabled = $UserLOGBackups} -CommandType StoredProcedure
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -database msdb -Query sp_update_job -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - SYSTEM_DATABASES - FULL"; enabled = $SystemFULLBackups} -CommandType StoredProcedure
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -database msdb -Query sp_update_job -SqlParameter @{ job_name = "_MAINT_DatabaseIntegritycheck - SYSTEM_DATABASES"; enabled = $SystemIntegrity} -CommandType StoredProcedure
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -database msdb -Query sp_update_job -SqlParameter @{ job_name = "_MAINT_DatabaseIntegritycheck - USER_DATABASES"; enabled = $UserIntegrity} -CommandType StoredProcedure
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -database msdb -Query sp_update_job -SqlParameter @{ job_name = "_MAINT_IndexOptimize - USER_DATABASES"; enabled = $indexOptimize} -CommandType StoredProcedure
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -database msdb -Query sp_update_job -SqlParameter @{ job_name = "_MAINT_CommandLog Cleanup"; enabled = $CommandLogCleanup} -CommandType StoredProcedure
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -database msdb -Query sp_update_job -SqlParameter @{ job_name = "_MAINT_CycleErrorLog"; enabled = $CycleErrorLog} -CommandType StoredProcedure
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -database msdb -Query sp_update_job -SqlParameter @{ job_name = "_MAINT_Output File Cleanup"; enabled = $OutputFileCleanup} -CommandType StoredProcedure
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -database msdb -Query sp_update_job -SqlParameter @{ job_name = "_MAINT_sp_delete_backuphistory"; enabled = $DeleteBackupHistory} -CommandType StoredProcedure
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -database msdb -Query sp_update_job -SqlParameter @{ job_name = "_MAINT_sp_purge_jobhistory"; enabled = $PurgeJobHistory} -CommandType StoredProcedure
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -database msdb -Query sp_update_job -SqlParameter @{ job_name = "_MAINT_sp_whoisactive data collection monitoring"; enabled = $Whoisactive} -CommandType StoredProcedure




Write-Host "Maintenance: Changing the job category of _MAINT_jobs to `"Database Maintenance`"..." -ForegroundColor Green
Invoke-DbaQuery -sqlinstance $Targets -sqlcredential $Cred -Query "
SELECT s.name as JobName
, c.name as [CurrentCategory]
, 'Fixed' as [Note]
FROM msdb.dbo.sysjobs s
INNER JOIN msdb.dbo.syscategories c on c.category_id = s.category_id 
WHERE s.category_id <> 3 AND s.name LIKE '%_Maint_%'


Declare @script nVarchar(2000)

SET @script = 'USE [msdb];'
SELECT @script = @script + ' 
EXEC msdb.dbo.sp_update_job @job_name=N'''+ s.name +''', @category_name=N''Database Maintenance''
' 
FROM msdb.dbo.sysjobs s
INNER JOIN msdb.dbo.syscategories c ON c.category_id = s.category_id 
WHERE s.category_id <> 3 AND s.name LIKE '%_Maint_%'
EXEC (@script)

"

start-sleep -Milliseconds 250

Write-Host "Maintenance Rollout: Complete." -ForegroundColor Green
