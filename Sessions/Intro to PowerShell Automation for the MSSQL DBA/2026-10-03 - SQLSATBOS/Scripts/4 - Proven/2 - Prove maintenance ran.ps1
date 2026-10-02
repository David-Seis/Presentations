<#
    ACT 4: PROVEN

    2 - Prove maintenance ran.

    In Act 2 we rolled maintenance out to every server. Rolling it out is not the
    same as it working. This closes the loop.

    Deploying and verifying are two different jobs, and the second one is the one
    that gets skipped -- because by hand it means opening Agent on every server
    and squinting at job history.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


<# ---------- PARAMETERS ---------- #>

    $CheckDbMaxAgeDays = 7      # integrity checks older than this are a problem


<# ---------- Did the integrity checks actually run? ---------- #>

<#
    This is the single best corruption question you can ask, and almost nobody
    asks it. CHECKDB only helps if it ran, and you only find out it did not on
    the day you need it to have.

    Note this reads the value SQL Server itself records (dbi_dbccLastKnownGood),
    not job history -- so it is true even if the job was renamed, moved or
    replaced by something else.
#>

    $checks = Get-DbaLastGoodCheckDb -SqlInstance $Targets @Lab |
                  Where-Object Database -in $LabDatabases

    $checks |
        Select-Object SqlInstance, Database, LastGoodCheckDb, DaysSinceLastGoodCheckDb, Status |
        Sort-Object SqlInstance, Database |
        Format-Table -AutoSize

    Write-Host "`nNever checked, or checked too long ago:" -ForegroundColor Red
    $checks |
        Where-Object { -not $_.LastGoodCheckDb -or $_.DaysSinceLastGoodCheckDb -gt $CheckDbMaxAgeDays } |
        Select-Object SqlInstance, Database, LastGoodCheckDb, DaysSinceLastGoodCheckDb |
        Format-Table -AutoSize


<# ---------- Did the jobs we deployed actually succeed? ---------- #>

    # In the lab, look for the log backup job. It fires every quarter-hour at a share
    # that does not exist -- so if one has passed since the rollout it shows Failed
    # here (deployed fine, never worked), and if not, it is in the never-run list below.
    $maintJobs = Get-DbaAgentJob -SqlInstance $Targets @Lab | Where-Object Name -like '_MAINT_*'

    $maintJobs |
        Select-Object SqlInstance, Name, IsEnabled, LastRunDate, LastRunOutcome |
        Sort-Object SqlInstance, Name |
        Format-Table -AutoSize

    # Deployed but never run is its own failure mode -- a job with no schedule,
    # or one whose schedule is disabled, looks perfectly healthy in a job list.
    # ("Never" is 1 January 0001 here, not $null -- so ask about the date.)
    $maintJobs |
        Where-Object { $_.LastRunDate -lt [datetime]'1900-01-01' } |
        Select-Object SqlInstance, Name, IsEnabled |
        Sort-Object SqlInstance, Name |
        Format-Table -AutoSize


<# ---------- Is anything already corrupt? ---------- #>

<#
    Suspect pages are SQL Server's own record of pages it could not read. A row
    here is not a warning, it is damage that has already happened.

    Empty is the answer you want, and it takes a second to confirm.
#>

    $suspect = Get-DbaSuspectPage -SqlInstance $Targets @Lab

    if ($suspect) {
        Write-Host "SUSPECT PAGES FOUND -- investigate immediately:" -ForegroundColor Red
        $suspect | Format-Table -AutoSize
    } else {
        Write-Host "No suspect pages on any server." -ForegroundColor Green
    }


<# ---------- Are the alerts we deployed actually configured? ---------- #>

<#
    Severity 19-25 and errors 823/824/825 are the alerts that tell you about
    corruption and hardware trouble. The rollout creates them. An alert with no
    operator attached, or one that is disabled, is decoration.
#>

    Get-DbaAgentAlert -SqlInstance $Targets @Lab |
        Select-Object SqlInstance, Name, IsEnabled, Severity, MessageId, LastOccurrenceDate |
        Sort-Object SqlInstance, Name |
        Format-Table -AutoSize

    Get-DbaAgentOperator -SqlInstance $Targets @Lab |
        Select-Object SqlInstance, Name, EmailAddress, IsEnabled |
        Format-Table -AutoSize


<# ---------- One verdict per server ---------- #>
<#
    Group by the name each server reports, not by $Targets. You connected to
    'localhost,14317', but the server answers as 'sqlsat2017' -- compare the two and
    nothing ever matches, and every server comes out green.
#>

    $checks | Group-Object SqlInstance | Sort-Object Name | ForEach-Object {
        $server = $_.Name

        $bad = @($_.Group | Where-Object {
            -not $_.LastGoodCheckDb -or $_.DaysSinceLastGoodCheckDb -gt $CheckDbMaxAgeDays
        }).Count

        $jobs = @($maintJobs | Where-Object SqlInstance -eq $server).Count

        $colour = if ($bad -eq 0 -and $jobs -gt 0) { 'Green' } else { 'Red' }
        Write-Host ("{0,-20} maintenance jobs: {1,-3} databases needing CHECKDB: {2}" -f $server, $jobs, $bad) -ForegroundColor $colour
    }
