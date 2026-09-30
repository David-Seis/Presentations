<#
    BONUS  --  a real automation that did not fit the session's argument.

    Runs against the demo lab. Build it first with _Setup\1 - Deploy lab.ps1,
    or edit $Targets in _Setup\Environment.ps1 to point at your own servers
    (and delete the @Lab from each command -- Windows auth needs no credential).
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -register  

# Targets and other variables

    $date = Get-Date -UFormat "%Y-%m-%d (%H.%M)"

    $backuppath = "C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\"

    $database = "DB_Administration"
#backup a database via DBAtools
    Invoke-DBAQuery -sqlinstance $Targets @Lab   -query  "
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
