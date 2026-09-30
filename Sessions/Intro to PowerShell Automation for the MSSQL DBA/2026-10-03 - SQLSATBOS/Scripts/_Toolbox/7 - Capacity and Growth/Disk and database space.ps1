<#
    TOOLBOX  --  Capacity and Growth

    Disk and database space.

    "Are we going to run out of disk?" answered in seconds instead of by clicking
    through four RDP sessions at 11pm because an alert fired.
#>

. "$PSScriptRoot\..\..\_Setup\Environment.ps1"


<# ---------- PARAMETERS ---------- #>

    $LowSpacePercent = 15      # flag volumes below this much free


<# ---------- Database files: used, allocated, free ---------- #>

<#
    The distinction that matters: a 500 GB data file that is 20% used is not
    500 GB of data, it is 100 GB of data and 400 GB you could reclaim -- or, more
    usefully, 400 GB you do not need to buy again.
#>

    $space = Get-DbaDbFile -SqlInstance $Targets @Lab

    $space |
        Select-Object SqlInstance, Database, LogicalName, TypeDescription,
                      @{ n = 'SizeMB';     e = { [math]::Round($_.Size.Megabyte, 0) } },
                      @{ n = 'UsedMB';     e = { [math]::Round($_.UsedSpace.Megabyte, 0) } },
                      @{ n = 'FreeMB';     e = { [math]::Round($_.Size.Megabyte - $_.UsedSpace.Megabyte, 0) } },
                      @{ n = 'PctUsed';    e = { if ($_.Size.Megabyte) { [math]::Round(100 * $_.UsedSpace.Megabyte / $_.Size.Megabyte, 1) } } },
                      Growth, GrowthType, PhysicalName |
        Sort-Object SqlInstance, Database |
        Out-GridView -Title 'Database file space'


<# ---------- Files that are nearly full ---------- #>

    Write-Host "`nFiles over 90% used -- these will autogrow soon:" -ForegroundColor Yellow
    $space |
        Where-Object { $_.Size.Megabyte -gt 0 -and (100 * $_.UsedSpace.Megabyte / $_.Size.Megabyte) -gt 90 } |
        Select-Object SqlInstance, Database, LogicalName,
                      @{ n = 'SizeMB'; e = { [math]::Round($_.Size.Megabyte, 0) } },
                      @{ n = 'PctUsed'; e = { [math]::Round(100 * $_.UsedSpace.Megabyte / $_.Size.Megabyte, 1) } } |
        Format-Table -AutoSize


<# ---------- Autogrowth settings that will hurt ---------- #>

<#
    Percentage growth on a large file is the classic trap: 10% of 500 GB is a
    50 GB growth event, which takes the database offline for the duration unless
    Instant File Initialization is on. Fixed-size growth in MB is what you want.
#>

    $space |
        Where-Object { $_.GrowthType -eq 'Percent' -or ($_.GrowthType -eq 'KB' -and $_.Growth -lt 65536) } |
        Select-Object SqlInstance, Database, LogicalName, TypeDescription, Growth, GrowthType,
                      @{ n = 'Problem'; e = {
                            if ($_.GrowthType -eq 'Percent') { 'Percentage growth -- grows larger as the file does' }
                            else { 'Growth increment under 64 MB -- causes frequent small growths and fragmentation' } } } |
        Format-Table -AutoSize -Wrap


<# ---------- Volumes (real servers -- needs Windows access) ---------- #>

    # Get-DbaDiskSpace -ComputerName $Targets |
    #     Select-Object ComputerName, Name, Label,
    #                   @{ n = 'CapacityGB'; e = { [math]::Round($_.Capacity.Gigabyte, 1) } },
    #                   @{ n = 'FreeGB';     e = { [math]::Round($_.Free.Gigabyte, 1) } },
    #                   PercentFree |
    #     Where-Object PercentFree -lt $LowSpacePercent |
    #     Sort-Object PercentFree

    # SQL Server's own view of its volumes -- works without Windows rights,
    # because it only sees the drives it has files on.
    Invoke-DbaQuery -SqlInstance $Targets @Lab -Query "
        SELECT DISTINCT
                ServerName    = @@SERVERNAME,
                Volume        = vs.volume_mount_point,
                TotalGB       = CONVERT(DECIMAL(10,1), vs.total_bytes     / 1073741824.0),
                FreeGB        = CONVERT(DECIMAL(10,1), vs.available_bytes / 1073741824.0),
                PercentFree   = CONVERT(DECIMAL(5,1), 100.0 * vs.available_bytes / vs.total_bytes)
        FROM    sys.master_files AS f
        CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) AS vs
        ORDER BY PercentFree;
    " | Format-Table -AutoSize


<# ---------- What is growing? ---------- #>

<#
    Autogrowth events are recorded in the default trace. This is history you
    already have and probably have never looked at -- and it tells you which
    database is the one actually consuming the drive.
#>

    Find-DbaDbGrowthEvent -SqlInstance $Targets @Lab |
        Select-Object SqlInstance, Database, LogicalFileName, StartTime, Duration_ms,
                      @{ n = 'GrowthMB'; e = { [math]::Round($_.ChangeInSize, 1) } } |
        Sort-Object StartTime -Descending |
        Select-Object -First 30 |
        Format-Table -AutoSize


<# ---------- TempDB ---------- #>

    Get-DbaTempdbUsage -SqlInstance $OneTarget @Lab |
        Select-Object SqlInstance, Spid, LoginName, DatabaseName, CurrentDbName,
                      UserObjectAllocated, InternalObjectAllocated |
        Sort-Object UserObjectAllocated -Descending |
        Select-Object -First 15 |
        Format-Table -AutoSize
