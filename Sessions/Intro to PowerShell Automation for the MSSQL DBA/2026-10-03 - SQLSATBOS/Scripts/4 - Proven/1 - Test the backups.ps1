<#
    ACT 4: PROVEN  --  automation you could not do slowly, because you were not
                       doing it at all.

    1 - Test the backups.

    Everything so far made you faster. This one is different: most shops do not
    do restore testing badly, they do not do it at all -- because by hand it is
    a day of work per server and nobody has the days.

    A backup you have never restored is a hope, not a backup.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


<# ---------- What it actually does ---------- #>

<#
    Test-DbaLastBackup, for each database:

        1. finds the most recent backup
        2. restores it under a new name, with a prefix so nothing is overwritten
        3. runs DBCC CHECKDB against the restored copy
        4. drops it
        5. hands you back a pass/fail object

    That is the entire manual runbook, as one command.
#>


<# ---------- One server first ---------- #>

    Test-DbaLastBackup -SqlInstance 'localhost,14322' @Lab -Prefix 'resttest_' |
        Select-Object SourceServer, Database, BackupDate, RestoreResult, DbccResult |
        Format-Table -AutoSize


<# ---------- Then the whole estate, same command ---------- #>

    $elapsed = Measure-Command {
        $script:results = Test-DbaLastBackup -SqlInstance $Targets @Lab -Prefix 'resttest_'
    }

    $results |
        Select-Object @{ n = 'Server'; e = { $_.SourceServer } },
                      Database, BackupDate, RestoreResult, DbccResult |
        Sort-Object Server, Database |
        Format-Table -AutoSize


<# ---------- Read the results out loud ---------- #>

<#
    Look at what came back. The lab was seeded to look like a real estate:

      2017   every database Skipped -- there are no backups to test.
             The server is not failing its restore test. It cannot take one.

      2019   Sales passes. Inventory and Reporting have no backup at all.

      2022   all three restore and pass CHECKDB. This is what healthy looks like.

      2025   Inventory and Reporting pass. Sales is SKIPPED -- and that is the
             interesting one.

    Sales on 2025 has a recent full backup. Every inventory query you own will
    show it as backed up. But it is COPY_ONLY, so it is not part of the chain,
    and the restore test is what tells you.

    That is the argument for this whole act: the only way to know a backup works
    is to restore it. Everything else is a checkbox.
#>


<# ---------- Just the failures ---------- #>

    $results |
        Where-Object { $_.RestoreResult -ne 'Success' -or $_.DbccResult -ne 'Success' } |
        Select-Object @{ n = 'Server'; e = { $_.SourceServer } }, Database, RestoreResult, DbccResult |
        Format-Table -AutoSize


<# ---------- Useful arguments ---------- #>

<#
    -MaxSize 1024           skip anything bigger than 1 GB. Essential on a laptop,
                            and how you keep a nightly run inside its window.

    -Destination <server>   restore onto a dedicated test box instead of the source.
                            This is what you want in production -- but the backup
                            path must be a UNC share (\\server\backups), http or s3.
                            A local path is refused with "Restore not located on
                            shared location", which is why the lab runs without it.

    -VerifyOnly             RESTORE VERIFYONLY instead of a real restore. Much
                            faster, much weaker. It checks the backup is readable,
                            not that the database inside it is sound.

    -NoDrop                 keep the restored copy so you can look at it.

    -IgnoreLogBackup        test the full only, do not roll the log chain forward.
#>

    # Bounded version, the one you would actually schedule:
    Test-DbaLastBackup -SqlInstance $Targets @Lab -MaxSize 1024 -Prefix 'resttest_' |
        Select-Object SourceServer, Database, RestoreResult, DbccResult


<# ---------- Scoreboard ---------- #>

    $tested = @($results | Where-Object RestoreResult -eq 'Success').Count

    "{0} databases restored and CHECKDB'd across {1} servers in {2:n1} seconds." -f $tested, $Targets.Count, $elapsed.TotalSeconds
    "By hand: restore, run CHECKDB, drop, write it up. Half a day per server, so most people never do it."
