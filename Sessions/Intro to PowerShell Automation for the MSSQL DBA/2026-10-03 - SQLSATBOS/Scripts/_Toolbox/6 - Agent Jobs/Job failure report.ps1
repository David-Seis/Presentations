<#
    TOOLBOX  --  Agent Jobs

    Job failure report.

    The morning check, for every server at once. This is the script most people
    schedule first, because it replaces a routine that otherwise eats the first
    half hour of every day.
#>

. "$PSScriptRoot\..\..\_Setup\Environment.ps1"


<# ---------- PARAMETERS ---------- #>

    $SinceHours = 24


<# ---------- Anything fail? ---------- #>

    $failed = Get-DbaAgentJobHistory -SqlInstance $Targets @Lab `
                  -StartDate (Get-Date).AddHours(-$SinceHours) -ExcludeJobSteps |
              Where-Object Status -eq 'Failed'

    if ($failed) {
        Write-Host "`nFailed jobs in the last $SinceHours hours:" -ForegroundColor Red
        $failed |
            Select-Object SqlInstance, Job, RunDate, Duration, Status, Message |
            Sort-Object RunDate -Descending |
            Format-Table -AutoSize -Wrap
    } else {
        Write-Host "`nNo job failures in the last $SinceHours hours." -ForegroundColor Green
    }


<# ---------- Which STEP failed, and why ---------- #>

<#
    Job-level history says "it failed". Step-level history says which command and
    with what error, which is what you actually need. Drop -ExcludeJobSteps.
#>

    Get-DbaAgentJobHistory -SqlInstance $Targets @Lab `
        -StartDate (Get-Date).AddHours(-$SinceHours) |
        Where-Object Status -eq 'Failed' |
        Select-Object SqlInstance, Job, StepName, RunDate, Message |
        Format-Table -AutoSize -Wrap


<# ---------- The current state of every job ---------- #>

    Get-DbaAgentJob -SqlInstance $Targets @Lab |
        Select-Object SqlInstance, Name, Category, IsEnabled, LastRunDate, LastRunOutcome,
                      @{ n = 'NextRun'; e = { $_.NextRunDate } },
                      @{ n = 'HoursSinceRun'; e = {
                            if ($_.LastRunDate -gt [datetime]'1900-01-01') {
                                [math]::Round((New-TimeSpan -Start $_.LastRunDate).TotalHours, 1)
                            } } } |
        Sort-Object SqlInstance, Name |
        Out-GridView -Title 'Agent jobs'


<# ---------- The failure modes that do not show as failures ---------- #>

    # Enabled, scheduled, and has never run
    Write-Host "`nEnabled but never run:" -ForegroundColor Yellow
    Get-DbaAgentJob -SqlInstance $Targets @Lab |
        Where-Object { $_.IsEnabled -and $_.LastRunDate -lt [datetime]'1900-01-01' } |
        Select-Object SqlInstance, Name, IsEnabled |
        Format-Table -AutoSize

    # Enabled but with no schedule -- it will only ever run if somebody starts it
    Write-Host "Enabled with no schedule:" -ForegroundColor Yellow
    Get-DbaAgentJob -SqlInstance $Targets @Lab |
        Where-Object { $_.IsEnabled -and -not $_.JobSchedules.Count } |
        Select-Object SqlInstance, Name |
        Format-Table -AutoSize

    # Disabled jobs that used to run -- somebody turned it off "temporarily"
    Write-Host "Disabled, but has run before:" -ForegroundColor Yellow
    Get-DbaAgentJob -SqlInstance $Targets @Lab |
        Where-Object { -not $_.IsEnabled -and $_.LastRunDate -gt [datetime]'1900-01-01' } |
        Select-Object SqlInstance, Name, LastRunDate, LastRunOutcome |
        Format-Table -AutoSize


<# ---------- Jobs that are taking longer than they used to ---------- #>

<#
    A backup job that has crept from 20 minutes to 3 hours is a capacity warning
    you get weeks before anything actually breaks.
#>

    Get-DbaAgentJobHistory -SqlInstance $Targets @Lab -StartDate (Get-Date).AddDays(-30) -ExcludeJobSteps |
        Where-Object Status -eq 'Succeeded' |
        Group-Object SqlInstance, Job |
        ForEach-Object {
            $runs = $_.Group | Sort-Object RunDate
            $recent = $runs | Select-Object -Last 5
            $older  = $runs | Select-Object -First 5
            $rAvg = ($recent | Measure-Object { $_.Duration.TotalSeconds } -Average).Average
            $oAvg = ($older  | Measure-Object { $_.Duration.TotalSeconds } -Average).Average
            if ($oAvg -gt 0 -and $rAvg -gt ($oAvg * 1.5)) {
                [PSCustomObject]@{
                    Server     = $runs[0].SqlInstance
                    Job        = $runs[0].Job
                    WasSeconds = [math]::Round($oAvg, 0)
                    NowSeconds = [math]::Round($rAvg, 0)
                    Increase   = '{0:n0}%' -f ((($rAvg - $oAvg) / $oAvg) * 100)
                }
            }
        } | Format-Table -AutoSize


<# ---------- Schedules, so you can see the collisions ---------- #>

    Get-DbaAgentSchedule -SqlInstance $Targets @Lab |
        Select-Object SqlInstance, ScheduleName, IsEnabled, Description |
        Sort-Object SqlInstance, ScheduleName |
        Format-Table -AutoSize -Wrap
