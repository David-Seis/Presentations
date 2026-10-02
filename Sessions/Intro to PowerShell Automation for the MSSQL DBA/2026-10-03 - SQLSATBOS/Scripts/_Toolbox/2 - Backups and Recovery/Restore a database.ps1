<#
    TOOLBOX  --  Backups and Recovery

    Restore a database.

    Restore-DbaDatabase is the one command worth learning properly, because it
    handles the parts people get wrong by hand: finding the newest full, applying
    the differential, rolling the log chain forward in order, relocating files,
    and renaming the database and its files consistently.
#>

. "$PSScriptRoot\..\..\_Setup\Environment.ps1"


<# ---------- PARAMETERS ---------- #>

    $Source      = 'localhost,14322'
    $Destination = 'localhost,14325'
    $BackupPath  = $LabContainerBackupPath
    $Database    = 'Sales'

    # Dry run by default: the restore below only SAYS what it would do. Read it,
    # then set this to $false and run it again.
    $DryRun      = $true


<# ---------- What is in the backup folder? ---------- #>

<#
    Point Restore-DbaDatabase at a FOLDER, not a file, and it reads the headers,
    works out what belongs to what, and puts the chain in order for you.
    -OutputScriptOnly shows you the T-SQL without running anything. (-WithReplace is
    there because those databases already exist on the destination; without it you
    get warnings instead of a script. Nothing runs either way.)
#>

    Restore-DbaDatabase -SqlInstance $Destination @Lab -Path $BackupPath -OutputScriptOnly -WithReplace


<# ---------- Restore, renamed, to a different server ---------- #>

    Restore-DbaDatabase -SqlInstance $Destination @Lab `
        -Path                            "$BackupPath/sqlsat2022_Sales_FULL.bak" `
        -DatabaseName                    "${Database}_Restored" `
        -ReplaceDbNameInFile `
        -UseDestinationDefaultDirectories `
        -WithReplace `
        -WhatIf:$DryRun

<#
    The two arguments people miss:

      -ReplaceDbNameInFile              renames the physical .mdf/.ldf too. Without
                                        it you get Sales_Restored running on files
                                        called Sales.mdf, which is confusing at best
                                        and a collision at worst.

      -UseDestinationDefaultDirectories  puts the files where the target server
                                        keeps its files, rather than trying to
                                        recreate the source's paths. Essential when
                                        restoring between servers with different drives.
#>


<# ---------- Point in time ---------- #>

    # Restore-DbaDatabase -SqlInstance $Destination @Lab `
    #     -Path $BackupPath -DatabaseName 'Sales_PIT' `
    #     -RestoreTime (Get-Date '2026-10-03 14:30:00') `
    #     -UseDestinationDefaultDirectories


<# ---------- Restore just the newest backup from a folder of many ---------- #>

    Get-ChildItem -Path $OutputPath -Filter "*$Database*.bak" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 |
        ForEach-Object {
            Write-Host "Newest backup: $($_.FullName)" -ForegroundColor Green
            # Restore-DbaDatabase -SqlInstance $Destination @Lab -Path $_.FullName -WithReplace
        }


<# ---------- Verify without restoring ---------- #>

    # Readable and internally consistent? Fast, but it does not check the data.
    Invoke-DbaQuery -SqlInstance $Destination @Lab -Query "
        RESTORE VERIFYONLY FROM DISK = N'$BackupPath/sqlsat2022_Sales_FULL.bak';
    "

    # What is actually inside this file?
    Invoke-DbaQuery -SqlInstance $Destination @Lab -Query "
        RESTORE HEADERONLY FROM DISK = N'$BackupPath/sqlsat2022_Sales_FULL.bak';
    " | Select-Object DatabaseName, BackupStartDate, BackupFinishDate, BackupSize, IsCopyOnly, RecoveryModel

    # For real confidence, restore it and run CHECKDB -- see 4 - Proven.


<# ---------- Clean up after yourself ---------- #>

    # Remove-DbaDatabase -SqlInstance $Destination @Lab -Database "${Database}_Restored" -Confirm:$false


<# ---------- Version rule that catches everyone once ---------- #>

<#
    You can restore UP a version, never DOWN.

        2019 backup  ->  2022 server   fine
        2022 backup  ->  2019 server   impossible, at any cost

    There is no downgrade path and no flag that changes it. If you need to move a
    database to an older version you are scripting it out and moving the data, not
    restoring it. Worth knowing before the migration meeting, not during it.
#>
