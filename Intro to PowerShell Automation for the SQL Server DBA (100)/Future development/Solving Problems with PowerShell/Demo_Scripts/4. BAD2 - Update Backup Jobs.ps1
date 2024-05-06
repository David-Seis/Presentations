#Priming Query
$SQLInstance = 'LabSQL3' #, '', '', '', '' target SQL server(s)
$Cleanuptime = '72'
$Directory = '\\labshare\SQLBackups' 
$SpecificDatabases = 'USER_DATABASES'

$SystemFULLBackupsEnabled = '1' # -- 1 = System full backup jobs enabled, 0 = disabled
$UserFULLBackupsEnabled = '1' # -- 1 = User full backup jobs enabled, 0 = disabled 
$UserDIFFBackupsEnabled = '1' # -- 1 = User diff backup jobs enabled, 0 = disabled 
$UserLOGBackupsEnabled = '1' # -- 1 = User log backup jobs enabled, 0 = disabled 



Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true


Invoke-DbaQuery -SQLInstance $SQLInstance -query "
SELECT @@Servername as [server name], name, enabled FROM msdb.dbo.sysjobs where name like '%DatabaseBackup%'
"| Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | format-table

Write-Host "Adjust System databases full Backup Job..." -ForegroundColor Green
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_jobstep -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - SYSTEM_DATABASES - FULL"; subsystem="TSQL"; database_name="DB_Administration"; step_id = "1"; 
command = "EXECUTE [dbo].[DatabaseBackup]
@Databases = 'SYSTEM_DATABASES',
@Directory = '$Directory', 
@BackupType = 'FULL',
@Verify = 'Y',
@CleanupTime = $Cleanuptime,
@CheckSum = 'Y',
@LogToTable = 'Y'"} -CommandType StoredProcedure

Write-Host "Adjust User Databases full backup job..." -ForegroundColor Green
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_jobstep -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - USER_DATABASES - FULL"; subsystem="TSQL";database_name="DB_Administration"; step_id = "1"; command = "EXECUTE [dbo].[DatabaseBackup]
@Databases = '$SpecificDatabases',
@Directory = '$Directory',
@BackupType = 'FULL',
@Verify = 'Y',
@CleanupTime = $Cleanuptime,
@CheckSum = 'Y',
@LogToTable = 'Y'"} -CommandType StoredProcedure

Write-Host "Adjust User Databases diff backup job..." -ForegroundColor Green
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_jobstep -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - USER_DATABASES - DIFF"; subsystem="TSQL"; database_name="DB_Administration"; step_id = "1"; command = "EXECUTE [dbo].[DatabaseBackup]
@Databases = '$SpecificDatabases',
@Directory = '$Directory',
@BackupType = 'DIFF',
@Verify = 'Y',
@CleanupTime = $Cleanuptime,
@CheckSum = 'Y',
@LogToTable = 'Y'
"} -CommandType StoredProcedure

Write-Host "Adjust User Databases log backup job..." -ForegroundColor Green
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_jobstep -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - USER_DATABASES - LOG"; subsystem="TSQL";database_name="DB_Administration";step_id = "1"; command = "EXECUTE [dbo].[DatabaseBackup]
@Databases = '$SpecificDatabases',
@Directory = '$Directory',
@BackupType = 'LOG',
@Verify = 'Y',
@CleanupTime = $Cleanuptime,
@CheckSum = 'Y',
@LogToTable = 'Y'
"} -CommandType StoredProcedure


Write-Host "Enabling/Disabling Backup jobs..." -ForegroundColor Green
Invoke-DbaQuery -SQLInstance $SQLInstance -Query "
USE [msdb]
EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - USER_DATABASES - FULL', @enabled = $UserFULLBackupsEnabled;
EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - USER_DATABASES - DIFF', @enabled = $UserDIFFBackupsEnabled;
EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - USER_DATABASES - LOG', @enabled = $UserLOGBackupsEnabled;
EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - SYSTEM_DATABASES - FULL', @enabled = $SystemFULLBackupsEnabled;
GO
"
<#
Write-Host "Running System-Database backups..." -ForegroundColor Green
Invoke-DbaQuery -SQLInstance $SQLInstance -query "
EXEC msdb.dbo.sp_start_job N'_MAINT_DatabaseBackup - SYSTEM_DATABASES - FULL'
"
#>
