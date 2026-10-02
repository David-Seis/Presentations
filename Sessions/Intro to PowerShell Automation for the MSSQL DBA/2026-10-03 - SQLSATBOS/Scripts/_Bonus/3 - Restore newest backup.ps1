<#
    BONUS  --  a real automation that did not fit the session's argument.

    Find the newest backup file in a folder, restore it under a new name.

    Written to run ON a default SQL Server 2022 instance on Windows (MSSQL16 paths)
    with the AdventureWorks2022 sample: the folder is read from THIS machine and the
    restore runs on the server, so both must see the same path. It does NOT run
    against the container lab as-is: point $Targets at that server, check the
    paths, and delete the @Lab (Windows auth needs no credential).
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


<# Credentials and Targets#>
    $backuppath     = "C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\"
    $RestoredDBName = "AdventureWorks2022_restored"

$latestBackup = Get-ChildItem $backuppath -Filter "AdventureWorks2022*.bak" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $latestBackup) {
    Write-Host "No AdventureWorks2022*.bak found in $backuppath -- nothing to restore." -ForegroundColor Red
    return
}
Write-Host "Latest backup file: $latestBackup" -ForegroundColor Green

# Restore a database via DBAtools
    Invoke-DBAQuery -sqlinstance $Targets @Lab   -query  "

    USE [master]
    RESTORE DATABASE [$RestoredDBName]
    FROM  DISK = N'$latestBackup'       WITH  FILE = 1
    ,  MOVE N'AdventureWorks2022'       TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\$RestoredDBName.mdf'
    ,  MOVE N'AdventureWorks2022_log'   TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\$RestoredDBName`_log.ldf'
    ,  NOUNLOAD
    ,  STATS = 5

    GO
    "
