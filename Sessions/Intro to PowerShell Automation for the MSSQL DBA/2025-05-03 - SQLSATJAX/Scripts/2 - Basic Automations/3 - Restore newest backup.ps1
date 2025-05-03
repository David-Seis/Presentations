
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -register  

<# Credentials and Targets#>
    $SQLInstance    =  "Seis-Work" 
    $backuppath     = "C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\"


Get-ChildItem $backuppath -Filter *.bak | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1 | 
    ForEach-Object {
        $latestBackup = $_.FullName
        Write-Host "Latest backup file: $latestBackup" -ForegroundColor Green
    }

# Restore a database via DBAtools
    Invoke-DBAQuery -sqlinstance $SQLInstance  -SqlCredential $cred -query  "

    USE [master]
    RESTORE DATABASE [AdventureWorks2022] FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\AdventureWorks2022.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5

    GO
    "
