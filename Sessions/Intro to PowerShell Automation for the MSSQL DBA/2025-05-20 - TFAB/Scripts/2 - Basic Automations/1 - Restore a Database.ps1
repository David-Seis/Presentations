
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -register  

<# Credentials and Targets#>
    $SQLInstance =  "Seis-Work" 


# Restore a database via DBAtools
    Invoke-DBAQuery -sqlinstance $SQLInstance   -query  "

    USE [master]
    RESTORE DATABASE [AdventureWorks2022] FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\AdventureWorks2022.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5

    GO
    "
