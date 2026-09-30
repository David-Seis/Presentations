<#
    BONUS  --  a real automation that did not fit the session's argument.

    Runs against the demo lab. Build it first with _Setup\1 - Deploy lab.ps1,
    or edit $Targets in _Setup\Environment.ps1 to point at your own servers
    (and delete the @Lab from each command -- Windows auth needs no credential).
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -register  

<# Credentials and Targets#>


# Restore a database via DBAtools
    Invoke-DBAQuery -sqlinstance $Targets @Lab -query  "

    USE [master]
    RESTORE DATABASE [AdventureWorks2022] 
    FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\AdventureWorks2022.bak' 
    WITH  FILE = 1,  NOUNLOAD,  STATS = 5

    GO
    "
