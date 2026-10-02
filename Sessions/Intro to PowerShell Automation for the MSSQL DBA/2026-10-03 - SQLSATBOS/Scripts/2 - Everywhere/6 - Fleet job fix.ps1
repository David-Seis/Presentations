<#
    ACT 2: EVERYWHERE

    6 - Fleet job fix.

    The audit found drift. This fixes it -- the same correction applied to every
    server at once, from one place, so they cannot disagree afterwards.

    This script CHANGES things. Read the variables below before running it.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


<# ---------- The standard: the same values the rollout deployed ---------- #>

$Cleanuptime       = '72'                       # hours of backup files to keep
$Directory         = '\\labshare\SQLBackups'    # where every server backs up to
$SpecificDatabases = 'USER_DATABASES'

$SystemFULLBackupsEnabled   = '1' # -- 1 = System full backup jobs enabled, 0 = disabled
$UserFULLBackupsEnabled     = '1' # -- 1 = User full backup jobs enabled, 0 = disabled
$UserDIFFBackupsEnabled     = '1' # -- 1 = User diff backup jobs enabled, 0 = disabled
$UserLOGBackupsEnabled      = '1' # -- 1 = User log backup jobs enabled, 0 = disabled
                                  #    (FULL recovery with no log backups is the incident from Act 1)


<# ---------- Before ---------- #>

Invoke-DbaQuery -SqlInstance $Targets @Lab -Query "
SELECT @@SERVERNAME AS [server name], name, enabled FROM msdb.dbo.sysjobs WHERE name LIKE '%DatabaseBackup%'
" | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | Format-Table


<# ---------- Put every backup job step back on the standard ---------- #>

Write-Host "Adjust System databases full Backup Job..." -ForegroundColor Green
Invoke-DbaQuery -SqlInstance $Targets @Lab -Database msdb -Query sp_update_jobstep -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - SYSTEM_DATABASES - FULL"; subsystem="TSQL"; database_name="DB_Administration"; step_id = "1";
command = "EXECUTE [dbo].[DatabaseBackup]
@Databases = 'SYSTEM_DATABASES',
@Directory = '$Directory',
@BackupType = 'FULL',
@Verify = 'Y',
@CleanupTime = $Cleanuptime,
@CheckSum = 'Y',
@LogToTable = 'Y'"} -CommandType StoredProcedure

Write-Host "Adjust User Databases FULL backup job..." -ForegroundColor Green
Invoke-DbaQuery -SqlInstance $Targets @Lab -Database msdb -Query sp_update_jobstep -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - USER_DATABASES - FULL"; subsystem="TSQL"; database_name="DB_Administration"; step_id = "1";
command = "EXECUTE [dbo].[DatabaseBackup]
@Databases = '$SpecificDatabases',
@Directory = '$Directory',
@BackupType = 'FULL',
@Verify = 'Y',
@CleanupTime = $Cleanuptime,
@CheckSum = 'Y',
@LogToTable = 'Y'"} -CommandType StoredProcedure

Write-Host "Adjust User Databases diff backup job..." -ForegroundColor Green
Invoke-DbaQuery -SqlInstance $Targets @Lab -Database msdb -Query sp_update_jobstep -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - USER_DATABASES - DIFF"; subsystem="TSQL"; database_name="DB_Administration"; step_id = "1";
command = "EXECUTE [dbo].[DatabaseBackup]
@Databases = '$SpecificDatabases',
@Directory = '$Directory',
@BackupType = 'DIFF',
@Verify = 'Y',
@CleanupTime = $Cleanuptime,
@CheckSum = 'Y',
@LogToTable = 'Y'"} -CommandType StoredProcedure

Write-Host "Adjust User Databases log backup job..." -ForegroundColor Green
Invoke-DbaQuery -SqlInstance $Targets @Lab -Database msdb -Query sp_update_jobstep -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - USER_DATABASES - LOG"; subsystem="TSQL"; database_name="DB_Administration"; step_id = "1";
command = "EXECUTE [dbo].[DatabaseBackup]
@Databases = '$SpecificDatabases',
@Directory = '$Directory',
@BackupType = 'LOG',
@Verify = 'Y',
@CleanupTime = $Cleanuptime,
@CheckSum = 'Y',
@LogToTable = 'Y'"} -CommandType StoredProcedure


<# ---------- And every one of them on, or off, on purpose ---------- #>

Write-Host "Enabling/Disabling Backup jobs..." -ForegroundColor Green
Invoke-DbaQuery -SqlInstance $Targets @Lab -Query "
USE [msdb]

EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - SYSTEM_DATABASES - FULL', @enabled = $SystemFULLBackupsEnabled;
EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - USER_DATABASES - FULL', @enabled = $UserFULLBackupsEnabled;
EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - USER_DATABASES - DIFF', @enabled = $UserDIFFBackupsEnabled;
EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - USER_DATABASES - LOG', @enabled = $UserLOGBackupsEnabled;
"


<# ---------- A job that is gone cannot be edited back -- copy it back ---------- #>
<#
    Copy-DbaAgentJob scripts a job off one server and creates it on another,
    schedule and all. "Make this server match that one" is one command.
#>

$Reference = 'localhost,14322'      # a server we know is right

$jobsOnReference = (Get-DbaAgentJob -SqlInstance $Reference @Lab | Where-Object Name -like '_MAINT_*').Name

foreach ($t in $Targets | Where-Object { $_ -ne $Reference }) {
    $here    = (Get-DbaAgentJob -SqlInstance $t @Lab | Where-Object Name -like '_MAINT_*').Name
    $missing = $jobsOnReference | Where-Object { $_ -notin $here }

    foreach ($job in $missing) {
        Write-Host "Copying '$job' from $Reference to $t..." -ForegroundColor Green
        Copy-DbaAgentJob -Source $Reference -Destination $t -Job $job `
            -SourceSqlCredential $LabCredential -DestinationSqlCredential $LabCredential |
            Select-Object DestinationServer, Name, Status | Format-Table -AutoSize
    }
}


<# ---------- After: every server, the same answer ---------- #>

$results = Invoke-DbaQuery -SqlInstance $Targets @Lab -Query "
SELECT  @@SERVERNAME AS [Server Name],
        s.name       AS JobName,
        s.enabled    AS Enabled,
        js.command
FROM    msdb.dbo.sysjobs s
LEFT JOIN msdb.dbo.sysjobsteps js ON js.job_id = s.job_id
WHERE   s.name LIKE '%MAINT%DatabaseBackup%'
ORDER BY s.name
"

$results | Out-GridView -Title 'Backup job steps, after the fix'
$results | Format-Table
