
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -register  

<# Credentials and Targets#>
    $SQLInstance    =  "Seis-Work" 
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
    Invoke-DBAQuery -sqlinstance $SQLInstance  -SqlCredential $cred -query  "

    USE [master]
    RESTORE DATABASE [$RestoredDBName] 
    FROM  DISK = N'$latestBackup'       WITH  FILE = 1
    ,  MOVE N'AdventureWorks2022'       TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\$RestoredDBName.mdf'
    ,  MOVE N'AdventureWorks2022_log'   TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\$RestoredDBName`_log.ldf'
    ,  NOUNLOAD
    ,  STATS = 5

    GO
    "
