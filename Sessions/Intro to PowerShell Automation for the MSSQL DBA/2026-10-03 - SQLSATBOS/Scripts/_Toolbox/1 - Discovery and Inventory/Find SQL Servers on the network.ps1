<#
    TOOLBOX  --  Discovery and Inventory

    Find SQL Servers on the network.

    "How many SQL Servers do we have?" You will be wrong. Everybody is wrong.
    Someone installed Express under a desk in 2016 and it is still holding the
    shipping department together.

    This is usually the first thing to run at a new client, and the results are
    reliably uncomfortable.
#>

. "$PSScriptRoot\..\..\_Setup\Environment.ps1"


<# ---------- PARAMETERS ---------- #>

    $Subnet = '192.168.1.0/24'      # only used by the IPRange discovery below


<# ---------- Ask Active Directory ---------- #>

<#
    The cleanest method where it works: SQL Server registers a Service Principal
    Name in AD, so the domain already knows where they are. No scanning, no noise.
    On a machine that is not joined to Active Directory (a laptop signed in with
    Entra ID, say) this warns that the domain cannot be contacted and returns nothing.
#>

    Find-DbaInstance -DiscoveryType Domain |
        Select-Object ComputerName, InstanceName, SqlInstance, Availability, Confidence |
        Sort-Object ComputerName |
        Format-Table -AutoSize


<# ---------- Ask the network ---------- #>

    # SQL Browser broadcast -- finds things on the local subnet that answer.
    # Windows PowerShell 5.1 only: the .NET class behind it does not exist in
    # PowerShell 7, where this warns and returns nothing.
    Find-DbaInstance -DiscoveryType DataSourceEnumeration |
        Select-Object ComputerName, InstanceName, SqlInstance, Availability

    # Brute force a range. Slow and noisy -- get permission before you scan anything.
    # Find-DbaInstance -DiscoveryType IPRange -IpAddress $Subnet |
    #     Where-Object Availability -eq 'Available'


<# ---------- Ask a list you already have ---------- #>

    # Most shops have this somewhere: a CMS, a spreadsheet, a monitoring config.
    # Find-DbaInstance will confirm which entries are still real.
    # Get-Content 'C:\DBA\servers.txt' | Find-DbaInstance |
    #     Select-Object ComputerName, SqlInstance, Availability


<# ---------- Registered Servers / CMS ---------- #>

<#
    If you have a Central Management Server, it is already the answer to
    "what is my $Targets list" -- and it is maintained by the team rather
    than by you remembering to update a text file.
#>

    # $Targets = (Get-DbaRegServer -SqlInstance 'YourCmsServer').ServerName


<# ---------- Once you know what exists, find out what it IS ---------- #>

    Get-DbaInstanceProperty -SqlInstance $Targets @Lab |
        Where-Object Name -in 'VersionString', 'Edition', 'ProductLevel', 'Collation',
                              'IsClustered', 'IsHadrEnabled', 'LoginMode' |
        Select-Object SqlInstance, Name, Value |
        Sort-Object SqlInstance, Name |
        Out-GridView -Title 'Instance properties'


<# ---------- And what it is running ON ---------- #>

<#
    These reach the WINDOWS side, so they need remote admin rights and will not
    work against the container lab. Against real servers they answer "is this box
    even big enough", which is half of every performance conversation.
#>

    # Get-DbaComputerSystem  -ComputerName $Targets | Select-Object ComputerName, NumberLogicalProcessors, TotalPhysicalMemory
    # Get-DbaOperatingSystem -ComputerName $Targets | Select-Object ComputerName, OSVersion, LastBootUpTime
    # Get-DbaProductKey      -ComputerName $Targets
