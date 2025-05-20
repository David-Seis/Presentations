

<# query to fix job comands#>
$SQLInstance = 'SEIS-Work' #, '', '', '', '' target SQL server(s)
$Cleanuptime = '336'
$Directory = '\\labshare\Backups' 
$SpecificDatabases = 'USER_DATABASES'

$SystemFULLBackupsEnabled   = '1' # -- 1 = System full backup jobs enabled, 0 = disabled
$UserFULLBackupsEnabled     = '1' # -- 1 = User full backup jobs enabled, 0 = disabled 
$UserDIFFBackupsEnabled     = '1' # -- 1 = User diff backup jobs enabled, 0 = disabled 
$UserLOGBackupsEnabled      = '0' # -- 1 = User log backup jobs enabled, 0 = disabled 

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

Write-Host "Adjust User Databases FULL backup job..." -ForegroundColor Green
Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_jobstep -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - USER_DATABASES - FULL"; subsystem="TSQL"; database_name="DB_Administration"; step_id = "1"; 
command = "EXECUTE [dbo].[DatabaseBackup]
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

EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - SYSTEM_DATABASES - FULL', @enabled = $SystemFULLBackupsEnabled;
EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - USER_DATABASES - FULL', @enabled = $UserFULLBackupsEnabled;
EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - USER_DATABASES - DIFF', @enabled = $UserDIFFBackupsEnabled;
EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - USER_DATABASES - LOG', @enabled = $UserLOGBackupsEnabled;

GO
"



<# Query to check the fixed job commands #>


$sqlinstance = 'SEIS-WORK'

Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true


$results = Invoke-dbaquery -SQlinstance $sqlinstance -query "
select 
@@servername as [Server Name]
, s.name AS JobName
, js.command 
, SERVERPROPERTY('InstanceDefaultBackupPath') AS [Default Backup Path]

from msdb.dbo.sysjobs s
left join msdb.dbo.sysjobsteps js on js.job_id = s.job_id
where s.name like '%MAINT%DatabaseBackup%'
ORDER by s.name

" 

$results | Out-GridView 
$results | Format-Table
