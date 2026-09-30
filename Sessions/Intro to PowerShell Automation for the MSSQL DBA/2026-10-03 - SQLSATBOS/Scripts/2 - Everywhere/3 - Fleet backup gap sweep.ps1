<#
    ACT 2: EVERYWHERE

    3 - Fleet backup gap sweep.

    The question you never want to answer with "I think so": is everything
    backed up?

    One command, every server, every database, in a couple of seconds. And the
    answers here are genuinely uneven, because the lab was built that way --
    see _Setup\1 - Deploy lab.ps1 if you want to know what was seeded.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


<# ---------- PARAMETERS ---------- #>

    $FullBackupMaxAgeDays = 1     # a full older than this is a problem
    $LogBackupMaxAgeHours = 4     # for databases in FULL recovery


<# ---------- Everything, everywhere ---------- #>

    $backups = Get-DbaLastBackup -SqlInstance $Targets @Lab |
        Where-Object Database -in $LabDatabases      # user databases only, for the demo

    $backups |
        Select-Object SqlInstance, Database, LastFullBackup, LastDiffBackup, LastLogBackup, LastFullBackupIsCopyOnly |
        Sort-Object SqlInstance, Database |
        Format-Table -AutoSize


<# ---------- Now just the problems ---------- #>

    Write-Host "`nDatabases with no full backup at all:" -ForegroundColor Red
    $backups | Where-Object { -not $_.LastFullBackup } |
        Select-Object SqlInstance, Database | Format-Table -AutoSize

    Write-Host "Full backup older than $FullBackupMaxAgeDays day(s):" -ForegroundColor Yellow
    $backups | Where-Object { $_.LastFullBackup -and $_.LastFullBackup -lt (Get-Date).AddDays(-$FullBackupMaxAgeDays) } |
        Select-Object SqlInstance, Database, LastFullBackup | Format-Table -AutoSize


<# ---------- The one that catches people out ---------- #>

<#
    A COPY_ONLY backup is a perfectly good backup -- but it deliberately does not
    take part in the backup chain. It does not reset the differential base.

    So a server can look backed up in every dashboard you own, and still not be
    recoverable the way you think it is. Somebody took an ad-hoc copy for a dev
    refresh, ticked the copy-only box, and the real schedule quietly stopped.

    This column is how you find it.
#>

    Write-Host "Last full backup was COPY_ONLY (looks fine, is not what you think):" -ForegroundColor Magenta
    $backups | Where-Object LastFullBackupIsCopyOnly |
        Select-Object SqlInstance, Database, LastFullBackup | Format-Table -AutoSize


<# ---------- FULL recovery without log backups ---------- #>

    # This is the one that pages you at 3am when the log drive fills.
    Get-DbaDatabase -SqlInstance $Targets -ExcludeSystem @Lab |
        Where-Object RecoveryModel -eq 'Full' |
        Where-Object { -not $_.LastLogBackup -or $_.LastLogBackup -lt (Get-Date).AddHours(-$LogBackupMaxAgeHours) } |
        Select-Object SqlInstance, Name, RecoveryModel, LastFullBackup, LastLogBackup |
        Format-Table -AutoSize


<# ---------- One tidy action list ---------- #>

    $findings = foreach ($b in $backups) {
        $issue = switch ($true) {
            { -not $b.LastFullBackup }                                                   { 'NO FULL BACKUP'; break }
            { $b.LastFullBackupIsCopyOnly }                                              { 'Last full is COPY_ONLY'; break }
            { $b.LastFullBackup -lt (Get-Date).AddDays(-$FullBackupMaxAgeDays) }          { 'Full backup is stale'; break }
            default                                                                      { $null }
        }
        if ($issue) {
            [PSCustomObject]@{
                SqlInstance = $b.SqlInstance
                Database    = $b.Database
                Issue       = $issue
                LastFull    = $b.LastFullBackup
            }
        }
    }

    $findings | Sort-Object Issue, SqlInstance | Format-Table -AutoSize
    $findings | Export-Csv (Join-Path $OutputPath "BackupGaps_$(Get-Date -f 'yyyy-MM-dd_HHmm').csv") -NoTypeInformation


<# ---------- Scoreboard ---------- #>

    $elapsed = Measure-Command { Get-DbaLastBackup -SqlInstance $Targets @Lab | Out-Null }
    "{0} servers checked in {1:n1}s -- {2} finding(s)" -f $Targets.Count, $elapsed.TotalSeconds, @($findings).Count
