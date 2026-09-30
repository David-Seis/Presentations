<#
    BONUS  --  a real automation that did not fit the session's argument.

    Runs against the demo lab. Build it first with _Setup\1 - Deploy lab.ps1,
    or edit $Targets in _Setup\Environment.ps1 to point at your own servers
    (and delete the @Lab from each command -- Windows auth needs no credential).
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -register  

<# Credentials and Targets#>
    $backuppath     = "C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\"
    $RestoredDBName = "AdventureWorks2022_restored"

Get-ChildItem $backuppath -Filter "AdventureWorks2022*.bak" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1 | 
    ForEach-Object {
        $latestBackup = $_.FullName
        Write-Host "Latest backup file: $latestBackup" -ForegroundColor Green
    }

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
