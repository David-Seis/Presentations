<#
    ACT 2: EVERYWHERE

    5 - Fleet job audit.

    Agent jobs drift. Somebody fixes a backup path on one server during an
    incident and never applies it anywhere else; six months later you have four
    servers doing four different things under the same job name.

    Finding that by hand means opening Agent on every server. Here it is a sweep.

    Run 4 - Fleet maintenance rollout.ps1 first -- this audits the jobs it creates.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


<# ---------- LAB ONLY: let six months go by ---------- #>
<#
    The rollout just made all four servers identical. Real estates do not stay that
    way, so this block plays four colleagues on four bad days. On your own servers,
    delete it -- the drift will already be there.

        2017  deleted IndexOptimize because it was "slowing things down"
        2019  pointed the user full backups at a different share during an incident
        2022  set backup retention to 9999 hours "just for now"
        2025  disabled the log backups "just for the migration"
#>

    if (-not (Get-DbaAgentJob -SqlInstance $Targets @Lab | Where-Object Name -like '_MAINT_*')) {
        Write-Host "No _MAINT_ jobs found. Run '4 - Fleet maintenance rollout.ps1' first." -ForegroundColor Red
        return
    }

    Invoke-DbaQuery -SqlInstance 'localhost,14317' @Lab -Database msdb -Query "
        IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = N'_MAINT_IndexOptimize - USER_DATABASES')
            EXEC dbo.sp_delete_job @job_name = N'_MAINT_IndexOptimize - USER_DATABASES';
    "

    Invoke-DbaQuery -SqlInstance 'localhost,14319' @Lab -Database msdb -Query "
        EXEC dbo.sp_update_jobstep @job_name = N'_MAINT_DatabaseBackup - USER_DATABASES - FULL', @step_id = 1,
             @command = N'EXECUTE [dbo].[DatabaseBackup] @Databases = ''USER_DATABASES'', @Directory = N''\\oldfileserver\SQLBackups'', @BackupType = ''FULL'', @Verify = ''Y'', @CleanupTime = 72, @CheckSum = ''Y'', @LogToTable = ''Y''';
    "

    Invoke-DbaQuery -SqlInstance 'localhost,14322' @Lab -Database msdb -Query "
        EXEC dbo.sp_update_jobstep @job_name = N'_MAINT_DatabaseBackup - USER_DATABASES - FULL', @step_id = 1,
             @command = N'EXECUTE [dbo].[DatabaseBackup] @Databases = ''USER_DATABASES'', @Directory = N''\\labshare\SQLBackups'', @BackupType = ''FULL'', @Verify = ''Y'', @CleanupTime = 9999, @CheckSum = ''Y'', @LogToTable = ''Y''';
    "

    Invoke-DbaQuery -SqlInstance 'localhost,14325' @Lab -Database msdb -Query "
        EXEC dbo.sp_update_job @job_name = N'_MAINT_DatabaseBackup - USER_DATABASES - LOG', @enabled = 0;
    "

    Write-Host "Six months have passed." -ForegroundColor DarkGray


<# ---------- What jobs exist, and are they even on? ---------- #>

    Get-DbaAgentJob -SqlInstance $Targets @Lab |
        Select-Object SqlInstance, Name, IsEnabled, LastRunDate, LastRunOutcome |
        Sort-Object SqlInstance, Name |
        Format-Table -AutoSize


<# ---------- Jobs that failed last time they ran ---------- #>

    Get-DbaAgentJob -SqlInstance $Targets @Lab |
        Where-Object LastRunOutcome -eq 'Failed' |
        Select-Object SqlInstance, Name, LastRunDate, LastRunOutcome |
        Format-Table -AutoSize


<# ---------- Jobs that are disabled and probably should not be ---------- #>

    Get-DbaAgentJob -SqlInstance $Targets @Lab |
        Where-Object { -not $_.IsEnabled } |
        Select-Object SqlInstance, Name, LastRunDate |
        Format-Table -AutoSize


<# ---------- Jobs that exist HERE but not THERE ---------- #>
<#
    This is the drift question. Group by job name, count how many servers have it,
    and anything not on all of them is worth a look.
#>

    $jobs = Get-DbaAgentJob -SqlInstance $Targets @Lab

    $jobs | Group-Object Name |
        Where-Object Count -lt $Targets.Count |
        Select-Object @{ n = 'JobName';   e = { $_.Name } },
                      @{ n = 'OnServers'; e = { $_.Count } },
                      @{ n = 'PresentOn'; e = { ($_.Group.SqlInstance | Sort-Object) -join ', ' } } |
        Format-Table -AutoSize


<# ---------- The actual command text, side by side ---------- #>
<#
    The same job NAME on four servers does not mean the same JOB. Compare the step
    commands and the differences jump out -- different backup paths, different
    retention, somebody's one-off @CleanupTime of 9999.
#>

    Invoke-DbaQuery -SqlInstance $Targets @Lab -Query "
        SELECT  ServerName        = @@SERVERNAME,
                JobName           = j.name,
                StepName          = s.step_name,
                s.command,
                DefaultBackupPath = CONVERT(sysname, SERVERPROPERTY('InstanceDefaultBackupPath'))
        FROM    msdb.dbo.sysjobs      j
        JOIN    msdb.dbo.sysjobsteps  s ON s.job_id = j.job_id
        WHERE   j.name LIKE '%Backup%'
        ORDER BY j.name, s.step_id;
    " | Select-Object ServerName, JobName, StepName, command |
        Out-GridView -Title 'Job step commands across the fleet'


<# ---------- Owners ---------- #>
<#
    A job owned by a departed employee's account stops running the day IT disables
    that account. Test-DbaAgentJobOwner finds them; Set-DbaAgentJobOwner fixes them.
#>

    Test-DbaAgentJobOwner -SqlInstance $Targets @Lab |
        Where-Object { -not $_.OwnerMatch } |
        Select-Object SqlInstance, Job, OwnerName |
        Format-Table -AutoSize

    # To fix -- this CHANGES things, so run it with -WhatIf first:
    # Set-DbaAgentJobOwner -SqlInstance $Targets @Lab -Login sa -WhatIf
