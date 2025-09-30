
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -register  

# Targets and other variables
    $SQLInstance =  "Seis-Work" 

    $date = Get-Date -UFormat "%Y-%m-%d (%H.%M)"

    $backuppath = "C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\"


    $database = "DB_Administration"
#backup a database via DBAtools
    Invoke-DBAQuery -sqlinstance $SQLInstance  -query  "
    BACKUP DATABASE [$database] 
    TO  DISK = N'$($backuppath+$database)`_$($date).bak' 
    WITH    NOFORMAT
        ,   NOINIT
        ,   NAME = N'$database-Full Database Backup - $date'
        ,   SKIP
        ,   NOREWIND
        ,   NOUNLOAD
        ,   STATS = 10
    GO
    "
