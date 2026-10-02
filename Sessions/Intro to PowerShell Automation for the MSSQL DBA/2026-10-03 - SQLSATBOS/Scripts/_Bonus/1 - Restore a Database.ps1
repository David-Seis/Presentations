<#
    BONUS  --  a real automation that did not fit the session's argument.

    Plain T-SQL, run through dbatools: the "I already have a script" case.

    Written for a default SQL Server 2022 instance on Windows (MSSQL16 paths) and
    the AdventureWorks2022 sample. It does NOT run against the container lab as-is:
    point $Targets at that server, check the path, and delete the @Lab (Windows
    auth needs no credential).
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


# Restore a database via DBAtools
    Invoke-DBAQuery -sqlinstance $Targets @Lab -query  "

    USE [master]
    RESTORE DATABASE [AdventureWorks2022]
    FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\AdventureWorks2022.bak'
    WITH  FILE = 1,  NOUNLOAD,  STATS = 5

    GO
    "
