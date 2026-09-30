<#
    TOOLBOX  --  Performance

    What is running right now.

    The phone rings and someone says "the database is slow". This is what you run
    in the next thirty seconds -- and being able to run it against every server at
    once matters, because "the database" is rarely the one they think it is.
#>

. "$PSScriptRoot\..\..\_Setup\Environment.ps1"


<# ---------- Who is connected, and what are they doing? ---------- #>

    Get-DbaProcess -SqlInstance $OneTarget @Lab -ExcludeSystemSpids |
        Select-Object SqlInstance, Spid, Login, Host, Program, Database, Status,
                      BlockingSpid, Command, LastQuery |
        Sort-Object BlockingSpid -Descending |
        Out-GridView -Title 'Current activity'


<# ---------- Blocking ---------- #>

<#
    The first question in any "it is slow" call: is something blocking?
    A non-zero BlockingSpid means somebody is waiting on somebody else.
#>

    Get-DbaProcess -SqlInstance $Targets @Lab -ExcludeSystemSpids |
        Where-Object BlockingSpid -ne 0 |
        Select-Object SqlInstance, Spid, BlockingSpid, Login, Program, Database, Command, LastQuery |
        Format-Table -AutoSize -Wrap


<# ---------- sp_WhoIsActive ---------- #>

<#
    Adam Machanic's procedure, and still the best single answer to "what is
    happening". Install it once, then it is a command like any other.
#>

    # Install-DbaWhoIsActive -SqlInstance $Targets @Lab -Database master

    Invoke-DbaWhoIsActive -SqlInstance $OneTarget @Lab -ShowOwnSpid |
        Select-Object SqlInstance, Session_id, Login_name, Database_name,
                      Status, Wait_info, CPU, Reads, Writes, Used_memory |
        Format-Table -AutoSize


<# ---------- What is the server waiting ON? ---------- #>

<#
    Wait statistics tell you the bottleneck category: CPU, disk, memory, locking,
    network. dbatools filters out the dozens of benign background waits for you,
    which is the part that makes raw sys.dm_os_wait_stats hard to read.
#>

    Get-DbaWaitStatistic -SqlInstance $OneTarget @Lab -Threshold 95 |
        Select-Object SqlInstance, WaitType, WaitSeconds, ResourceSeconds, SignalSeconds,
                      WaitCount, Percentage, Category |
        Sort-Object Percentage -Descending |
        Select-Object -First 15 |
        Format-Table -AutoSize

<#
    Rough translation of the common ones:

      CXPACKET / CXCONSUMER     parallelism -- look at MAXDOP and cost threshold
      PAGEIOLATCH_*             reading data from disk -- memory pressure or slow storage
      WRITELOG                  transaction log writes -- log disk latency
      LCK_M_*                   blocking -- go back to the blocking query above
      SOS_SCHEDULER_YIELD       CPU pressure
      RESOURCE_SEMAPHORE        queries waiting for memory grants
      ASYNC_NETWORK_IO          the APPLICATION is slow to read results, not SQL
#>


<# ---------- The expensive queries ---------- #>

    Get-DbaTopResourceUsage -SqlInstance $OneTarget @Lab -Type Duration |
        Select-Object SqlInstance, Database, ObjectName, executioncount,
                      totalduration_s, avgduration_s, querytext |
        Sort-Object totalduration_s -Descending |
        Select-Object -First 10 |
        Format-Table -AutoSize -Wrap

    # Also available: -Type Frequency, CPU, IO
    # Get-DbaTopResourceUsage -SqlInstance $OneTarget @Lab -Type CPU


<# ---------- Storage latency ---------- #>

<#
    Rule of thumb: data files under 20 ms, log files under 5 ms. Consistently
    worse than that and the storage is the conversation, not the query.
#>

    Get-DbaIoLatency -SqlInstance $OneTarget @Lab |
        Select-Object SqlInstance, Database, FileName,
                      ReadLatency, WriteLatency, Latency, SizeGB |
        Sort-Object Latency -Descending |
        Select-Object -First 15 |
        Format-Table -AutoSize


<# ---------- Memory ---------- #>

    Get-DbaMemoryUsage -ComputerName 'localhost' -ErrorAction SilentlyContinue |
        Select-Object ComputerName, CounterName, Memory |
        Format-Table -AutoSize

    Invoke-DbaQuery -SqlInstance $Targets @Lab -Query "
        SELECT  ServerName          = @@SERVERNAME,
                PageLifeExpectancy  = cntr_value
        FROM    sys.dm_os_performance_counters
        WHERE   counter_name = 'Page life expectancy'
                AND object_name LIKE '%Buffer Manager%';
    " | Format-Table -AutoSize


<# ---------- Killing something (last resort) ---------- #>

    # Get-DbaProcess -SqlInstance $OneTarget @Lab -Spid 54 | Stop-DbaProcess -WhatIf
