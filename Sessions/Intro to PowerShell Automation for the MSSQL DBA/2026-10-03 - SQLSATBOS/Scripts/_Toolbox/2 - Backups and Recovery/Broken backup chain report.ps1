<#
    TOOLBOX  --  Backups and Recovery

    Broken backup chain report.

    A backup chain breaks quietly. Someone takes an ad-hoc full without COPY_ONLY
    and resets the differential base; a third-party tool starts backing the same
    database up to a different place; a log backup job gets disabled "just for the
    migration" and never re-enabled.

    Nothing alerts. Everything looks green. You find out when you try to restore
    to a point in time and the chain does not reach.

    This looks for the shapes that mean trouble.
#>

. "$PSScriptRoot\..\..\_Setup\Environment.ps1"


<# ---------- PARAMETERS ---------- #>

    $Days = 7      # how far back to examine


<# ---------- How many places are our backups going? ---------- #>

<#
    More than one destination for the same database usually means two things are
    backing it up and neither knows about the other. That is the classic way a
    chain gets broken -- and the classic way a restore fails at 2am.
#>

    $history = Get-DbaDbBackupHistory -SqlInstance $Targets @Lab -Since (Get-Date).AddDays(-$Days)

    $history |
        Group-Object SqlInstance, Database |
        ForEach-Object {
            $paths = $_.Group.Path | ForEach-Object { Split-Path $_ -Parent } | Sort-Object -Unique
            [PSCustomObject]@{
                Server        = $_.Group[0].SqlInstance
                Database      = $_.Group[0].Database
                Destinations  = $paths.Count
                Backups       = $_.Count
                Where         = $paths -join ' | '
            }
        } |
        Sort-Object Destinations -Descending |
        Format-Table -AutoSize


<# ---------- Non-copy-only ad-hoc fulls ---------- #>

<#
    A full backup that is NOT part of the scheduled job and NOT copy-only has
    reset the differential base. Every differential taken before it is now
    useless, and nobody told you.
#>

    $history |
        Where-Object { $_.Type -eq 'Full' -and -not $_.IsCopyOnly } |
        Group-Object SqlInstance, Database |
        Where-Object Count -gt $Days |     # more fulls than days = something ad-hoc happened
        ForEach-Object {
            [PSCustomObject]@{
                Server   = $_.Group[0].SqlInstance
                Database = $_.Group[0].Database
                Fulls    = $_.Count
                Note     = 'More full backups than days -- ad-hoc full likely reset the diff base'
            }
        } | Format-Table -AutoSize


<# ---------- Gaps in the log chain ---------- #>

<#
    For a database in FULL recovery, the log backups should form an unbroken line.
    A gap bigger than the schedule interval means you cannot restore across it.
#>

    $logs = $history | Where-Object Type -eq 'Log' | Sort-Object SqlInstance, Database, Start

    $logs | Group-Object SqlInstance, Database | ForEach-Object {
        $rows = @($_.Group)
        for ($i = 1; $i -lt $rows.Count; $i++) {
            $gap = New-TimeSpan -Start $rows[$i - 1].End -End $rows[$i].Start
            if ($gap.TotalMinutes -gt 60) {
                [PSCustomObject]@{
                    Server   = $rows[$i].SqlInstance
                    Database = $rows[$i].Database
                    GapStart = $rows[$i - 1].End
                    GapEnd   = $rows[$i].Start
                    GapHours = [math]::Round($gap.TotalHours, 1)
                }
            }
        }
    } | Sort-Object GapHours -Descending | Format-Table -AutoSize


<# ---------- FULL recovery, no log backups at all ---------- #>

    Get-DbaDatabase -SqlInstance $Targets -ExcludeSystem @Lab |
        Where-Object { $_.RecoveryModel -eq 'Full' -and $_.LastLogBackup -lt [datetime]'1900-01-01' } |   # "never" is 1 Jan 0001, not $null
        Select-Object SqlInstance, Name, RecoveryModel, LastFullBackup,
                      @{ n = 'Problem'; e = { 'FULL recovery with no log backups -- log will grow forever' } } |
        Format-Table -AutoSize


<# ---------- What can I actually restore to? ---------- #>

<#
    The honest answer to "what is our RPO". Not what the policy says -- what the
    backup history can actually deliver.
#>

    $history |
        Group-Object SqlInstance, Database |
        ForEach-Object {
            [PSCustomObject]@{
                Server        = $_.Group[0].SqlInstance
                Database      = $_.Group[0].Database
                EarliestPoint = ($_.Group | Sort-Object Start | Select-Object -First 1).Start
                LatestPoint   = ($_.Group | Sort-Object End -Descending | Select-Object -First 1).End
                ExposureMins  = [math]::Round((New-TimeSpan -Start ($_.Group | Sort-Object End -Descending | Select-Object -First 1).End).TotalMinutes, 0)
            }
        } |
        Sort-Object ExposureMins -Descending |
        Format-Table -AutoSize
