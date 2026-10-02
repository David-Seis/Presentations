<#
    TOOLBOX  --  Windows and Server

    Service and server health.

    Half of what a DBA gets blamed for lives on the Windows side: a service set to
    Manual that never came back after a reboot, a service account about to expire,
    a power plan throttling the CPU to half speed.

    NOTE: most of this reaches Windows, not SQL, so it needs remote admin rights
    and will NOT work against the container lab. The SQL-side equivalents that DO
    work are included where they exist.
#>

. "$PSScriptRoot\..\..\_Setup\Environment.ps1"

# For real servers, set this to your machine names (not instance names):
$Computers = 'localhost'


<# ---------- Services: running, and set to start automatically ---------- #>

    # Get-DbaService -ComputerName $Computers |
    #     Select-Object ComputerName, ServiceName, ServiceType, State, StartMode, StartName |
    #     Sort-Object ComputerName, ServiceType |
    #     Format-Table -AutoSize

    # The finding that bites after an unplanned reboot: running now, but set to
    # Manual, so it will not come back on its own.
    # Get-DbaService -ComputerName $Computers |
    #     Where-Object { $_.State -eq 'Running' -and $_.StartMode -ne 'Auto' } |
    #     Select-Object ComputerName, ServiceName, State, StartMode

    # SQL-side version -- works anywhere you can connect, including the lab.
    Invoke-DbaQuery -SqlInstance $Targets @Lab -Query "
        SELECT  ServerName   = @@SERVERNAME,
                ServiceName  = servicename,
                StartupType  = startup_type_desc,
                Status       = status_desc,
                Account      = service_account,
                LastStartup  = last_startup_time
        FROM    sys.dm_server_services;
    " | Format-Table -AutoSize


<# ---------- Service accounts ---------- #>

<#
    Two findings worth chasing:

      - SQL running as LocalSystem or NetworkService. It works, but it cannot be
        granted rights to a file share, so backups to UNC paths will fail.

      - SQL running as a domain account whose password expires. It runs happily
        for ninety days and then does not restart.
#>

    Invoke-DbaQuery -SqlInstance $Targets @Lab -Query "
        SELECT  ServerName = @@SERVERNAME,
                servicename,
                service_account,
                Note = CASE
                         WHEN service_account LIKE 'NT AUTHORITY%' OR service_account LIKE 'NT SERVICE%'
                           THEN 'Built-in account -- cannot be granted share permissions'
                         WHEN service_account NOT LIKE '%\%'
                           THEN 'Local account'
                         ELSE 'Domain account -- check password expiry policy'
                       END
        FROM    sys.dm_server_services
        WHERE   servicename LIKE 'SQL Server%';
    " | Format-Table -AutoSize -Wrap


<# ---------- Uptime ---------- #>

<#
    Useful in both directions. Very short uptime means something restarted and
    you may not know why. Very long uptime means the server has missed a lot of
    Windows patches.
#>

    Invoke-DbaQuery -SqlInstance $Targets @Lab -Query "
        SELECT  ServerName  = @@SERVERNAME,
                SqlStarted  = sqlserver_start_time,
                UptimeDays  = DATEDIFF(DAY, sqlserver_start_time, GETDATE())
        FROM    sys.dm_os_sys_info;
    " | Sort-Object UptimeDays -Descending | Format-Table -AutoSize

    # Get-DbaUptime -SqlInstance $Targets


<# ---------- Power plan ---------- #>

<#
    Windows defaults to "Balanced", which downclocks the CPU. On a database server
    that is a measurable and completely unnecessary performance loss, and it is a
    two-minute fix that nobody ever checks.
#>

    # Test-DbaPowerPlan -ComputerName $Computers |
    #     Select-Object ComputerName, PowerPlan, RecommendedPowerPlan, IsBestPractice
    # Set-DbaPowerPlan -ComputerName $Computers -WhatIf


<# ---------- Certificates about to expire ---------- #>

    # Get-DbaComputerCertificate -ComputerName $Computers |
    #     Select-Object ComputerName, Name, Subject, NotAfter,
    #                   @{ n='DaysLeft'; e={ (New-TimeSpan -End $_.NotAfter).Days } } |
    #     Where-Object DaysLeft -lt 90 | Sort-Object DaysLeft

    # Test-DbaComputerCertificateExpiration -ComputerName $Computers -Threshold 90


<# ---------- Error log ---------- #>

<#
    Reading the error log across the estate for the words that matter, rather than
    opening it server by server.
#>

    # The second filter drops the good news: a clean CHECKDB logs "found 0 errors",
    # which matches 'error' and would otherwise bury the lines you are looking for.
    Get-DbaErrorLog -SqlInstance $Targets @Lab -After (Get-Date).AddDays(-2) |
        Where-Object { $_.Text -match 'error|fail|corrupt|cannot|denied|severity' } |
        Where-Object { $_.Text -notmatch 'found 0 errors|without errors|0 allocation errors and 0 consistency errors|informational message only' } |
        Select-Object SqlInstance, LogDate, Source, Text |
        Sort-Object LogDate -Descending |
        Select-Object -First 40 |
        Format-Table -AutoSize -Wrap


<# ---------- Housekeeping: clear out old files ---------- #>

<#
    Backup folders, log folders and report folders fill up. This is the kind of
    thing worth scheduling once and never thinking about again.

    -WhatIf is on deliberately. Take it off only once you have read the list.
#>

    $FolderToClean = $OutputPath
    $KeepDays      = 30

    Get-ChildItem -Path $FolderToClean -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object LastWriteTime -lt (Get-Date).AddDays(-$KeepDays) |
        Remove-Item -WhatIf
