<#
    ACT 2: EVERYWHERE

    4 - Fleet job audit.

    Agent jobs drift. Somebody fixes a backup path on one server during an
    incident and never applies it anywhere else; six months later you have four
    servers doing four different things under the same job name.

    Finding that by hand means opening Agent on every server. Here it is a sweep.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


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
