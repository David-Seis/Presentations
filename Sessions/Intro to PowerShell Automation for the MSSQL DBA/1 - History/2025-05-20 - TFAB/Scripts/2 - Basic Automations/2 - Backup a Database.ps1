
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -register  

# Targets and other variables
    $SQLInstance =  "Seis-Work" 

    $date = Get-Date -UFormat "%Y-%m-%d (%H.%M)"

    $backuppath = "C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\"

#backup a database via DBAtools
    Invoke-DBAQuery -sqlinstance $SQLInstance  -SqlCredential $cred -query  "
    BACKUP DATABASE [AdventureWorks2022] 
    TO  DISK = N'$backuppath`AdventureWorks2022_$($date).bak' 
    WITH    NOFORMAT
        ,   NOINIT
        ,   NAME = N'AdventureWorks2022-Full Database Backup - $date'
        ,   SKIP
        ,   NOREWIND
        ,   NOUNLOAD
        ,   STATS = 10
    GO
    "
