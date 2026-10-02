<#
    ACT 4: PROVEN

    3 - The scoreboard.

    The closing slide, generated live rather than asserted.

    Run this at the end of the session. Every number is measured in the room, on
    the servers the audience just watched you build. The "by hand" column is the
    honest part: it is an estimate, and you should say so -- but every DBA
    watching will recognise the shape of it.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


<# ---------- PARAMETERS: your honest manual estimates, in MINUTES per server ---------- #>

    $ManualMinutes = @{
        'Inventory the estate'      = 6      # RDP in, open SSMS, read it off, type it up
        'Check every backup'        = 10     # per server, and you will not do it daily
        'Verify maintenance ran'    = 15
        'Restore-test the backups'  = 0      # see note below
    }


<# ---------- Measure the real thing ---------- #>

    Write-Host "`nRunning the session's work again, with a clock on it...`n" -ForegroundColor Cyan

    $scores = [System.Collections.Generic.List[object]]::new()

    function Add-Score {
        param([string]$Task, [scriptblock]$Work)
        Write-Host "  $Task..." -ForegroundColor DarkGray
        $t = Measure-Command { & $Work | Out-Null }
        $scores.Add([PSCustomObject]@{
            Task          = $Task
            Servers       = $Targets.Count
            ScriptSeconds = [math]::Round($t.TotalSeconds, 1)
            ManualMinutes = $ManualMinutes[$Task] * $Targets.Count
        })
    }

    Add-Score 'Inventory the estate'     { Get-DbaDatabase       -SqlInstance $Targets -ExcludeSystem @Lab }
    Add-Score 'Check every backup'       { Get-DbaLastBackup     -SqlInstance $Targets @Lab }
    Add-Score 'Verify maintenance ran'   { Get-DbaLastGoodCheckDb -SqlInstance $Targets @Lab }
    Add-Score 'Restore-test the backups' { Test-DbaLastBackup    -SqlInstance $Targets @Lab -Database $LabDatabases -MaxSize 1024 -Prefix 'score_' }


<# ---------- The slide ---------- #>

    Write-Host "`n"
    $scores |
        Select-Object Task,
                      Servers,
                      @{ n = 'Script';   e = { '{0,6:n1} s'   -f $_.ScriptSeconds } },
                      @{ n = 'By hand';  e = { if ($_.ManualMinutes -eq 0) { '   never' } else { '{0,5} min' -f $_.ManualMinutes } } },
                      @{ n = 'Faster by'; e = {
                            if ($_.ManualMinutes -eq 0) { 'n/a -- it was not happening' }
                            else { '{0,5:n0}x' -f (($_.ManualMinutes * 60) / [math]::Max($_.ScriptSeconds, 0.1)) }
                         } } |
        Format-Table -AutoSize

    $totalScript = ($scores | Measure-Object ScriptSeconds -Sum).Sum
    $totalManual = ($scores | Measure-Object ManualMinutes -Sum).Sum

    Write-Host ("  Total: {0:n0} seconds of script against roughly {1:n1} hours of hand work." -f $totalScript, ($totalManual / 60)) -ForegroundColor Green


<# ---------- The line to end on ---------- #>

<#
    Point at the last row.

    Restore testing has no "by hand" number, because half a day per server per
    week is not a thing anyone sustains -- so it does not get done, and nobody
    finds out until the day they need the backup.

    That is the real argument. The first three rows are about doing your job
    faster. The last one is about doing a part of your job that, without this,
    you were never going to do at all.

    Everything here is free, open source, and installable in the next ten minutes:

        Install-Module dbatools -Scope CurrentUser
#>
