<#
    TOOLBOX  --  Integrity and Corruption

    Integrity check report.

    Corruption is rare and catastrophic. The only two things that save you are a
    backup you have tested and a CHECKDB that ran recently enough that the
    corruption is still inside your retention window.

    If CHECKDB last ran four months ago and your backups keep five weeks, then by
    the time you find the corruption every backup you hold already contains it.
    That is how a recoverable incident becomes data loss.
#>

. "$PSScriptRoot\..\..\_Setup\Environment.ps1"


<# ---------- PARAMETERS ---------- #>

    $MaxAgeDays = 7


<# ---------- When did CHECKDB last pass? ---------- #>

<#
    This reads dbi_dbccLastKnownGood, which SQL Server itself stamps on the
    database when a clean CHECKDB completes. It is the truth regardless of what
    your job history says -- which matters, because job history gets purged and
    jobs get renamed.
#>

    $checks = Get-DbaLastGoodCheckDb -SqlInstance $Targets @Lab -ExcludeDatabase tempdb

    $checks |
        Select-Object SqlInstance, Database, LastGoodCheckDb, DaysSinceLastGoodCheckDb,
                      DaysSinceDbCreated, Status |
        Sort-Object DaysSinceLastGoodCheckDb -Descending |
        Format-Table -AutoSize


<# ---------- The ones that should worry you ---------- #>

    Write-Host "`nNever checked:" -ForegroundColor Red
    $checks | Where-Object { -not $_.LastGoodCheckDb } |
        Select-Object SqlInstance, Database, DaysSinceDbCreated, Status |
        Format-Table -AutoSize

    Write-Host "Checked more than $MaxAgeDays days ago:" -ForegroundColor Yellow
    $checks | Where-Object { $_.DaysSinceLastGoodCheckDb -gt $MaxAgeDays } |
        Select-Object SqlInstance, Database, LastGoodCheckDb, DaysSinceLastGoodCheckDb |
        Sort-Object DaysSinceLastGoodCheckDb -Descending |
        Format-Table -AutoSize


<# ---------- Damage already recorded ---------- #>

<#
    The suspect_pages table in msdb is SQL Server's record of pages it could not
    read correctly. A row in here is not a risk -- it is damage that has already
    occurred. Empty is the only good answer.
#>

    $suspect = Get-DbaSuspectPage -SqlInstance $Targets @Lab

    if ($suspect) {
        Write-Host "`nSUSPECT PAGES -- act on these now:" -ForegroundColor Red
        $suspect | Select-Object SqlInstance, Database, FileId, PageId, EventType, ErrorCount, LastUpdateDate |
            Format-Table -AutoSize
    } else {
        Write-Host "`nNo suspect pages recorded on any server." -ForegroundColor Green
    }


<# ---------- Run a check now ---------- #>

<#
    CHECKDB is expensive. On a large database run it against a restored copy on
    another server instead -- which is exactly what Test-DbaLastBackup does, so
    you get backup testing and integrity checking from the same operation.
#>

    # Commented out so the report stays read-only: CHECKDB is heavy on a busy server.
    # (In the lab it would also stamp 2017 -- seeded as never-checked -- as checked.)

    # Everything, on one database
    # Invoke-DbaQuery -SqlInstance $OneTarget @Lab -Database Sales -Query "
    #     DBCC CHECKDB([Sales]) WITH NO_INFOMSGS, ALL_ERRORMSGS;
    # "

    # PHYSICAL_ONLY: much faster, catches the storage-level corruption that is by
    # far the most common kind. A reasonable daily compromise on a big database,
    # with a full CHECKDB weekly.
    # Invoke-DbaQuery -SqlInstance $OneTarget @Lab -Database Sales -Query "
    #     DBCC CHECKDB([Sales]) WITH PHYSICAL_ONLY, NO_INFOMSGS;
    # "


<# ---------- Are the alerts that tell you about this even configured? ---------- #>

<#
    Errors 823, 824 and 825 are SQL Server telling you the storage returned bad
    data. Severity 19-25 covers the rest of the serious failures.

    Most instances have none of these configured, which means the first person to
    notice corruption is a user. Ola Hallengren's solution -- deployed in Act 2 --
    sets them up.
#>

    Get-DbaAgentAlert -SqlInstance $Targets @Lab |
        Select-Object SqlInstance, Name, IsEnabled, MessageId, Severity, HasNotification, LastOccurrenceDate |
        Sort-Object SqlInstance, Name |
        Format-Table -AutoSize

    # Servers with no alerts at all
    foreach ($t in $Targets) {
        $n = @(Get-DbaAgentAlert -SqlInstance $t @Lab).Count
        if ($n -eq 0) { Write-Host "$t has NO Agent alerts configured." -ForegroundColor Red }
    }


<# ---------- If you ever do find corruption ---------- #>

<#
    In order:

      1. Do not panic and do not immediately run REPAIR_ALLOW_DATA_LOSS.
         The name is accurate. It is a last resort, not a first response.

      2. Work out the scope: which database, which pages, which objects.
         DBCC CHECKDB output names them.

      3. Restore. A good backup plus the log chain is almost always a better
         outcome than repair, and it is why the backup testing in Act 4 matters.

      4. If it is a nonclustered index, you can often just rebuild it -- the data
         is still intact in the base table.

      5. Find the cause. Corruption is a symptom, and the storage that did it
         once will do it again.
#>
