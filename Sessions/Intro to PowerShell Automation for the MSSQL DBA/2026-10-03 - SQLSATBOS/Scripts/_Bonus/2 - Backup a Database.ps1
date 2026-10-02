<#
    BONUS  --  a real automation that did not fit the session's argument.

    Plain T-SQL, run through dbatools: the "I already have a script" case.

    Written for a default SQL Server 2022 instance on Windows (MSSQL16 paths). It
    does NOT run against the container lab as-is: point $Targets at that server,
    check the path, and delete the @Lab (Windows auth needs no credential).
    DB_Administration is the admin database the Act 2 rollout creates.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


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
