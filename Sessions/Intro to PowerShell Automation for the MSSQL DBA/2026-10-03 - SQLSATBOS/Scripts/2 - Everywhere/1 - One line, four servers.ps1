<#
    ACT 2: EVERYWHERE  --  the same work, against the whole estate.

    1 - One line, four servers.

    This is the whole session in one script.

    Nothing below is new. Every command was in Act 1. The only difference is that
    $Target held one server and $Targets holds four -- and dbatools does the rest,
    because -SqlInstance takes an array.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


<# ---------- Act 1 ended here ---------- #>

    $Target = 'localhost,14322'

    Get-DbaDatabase -SqlInstance $Target -ExcludeSystem @Lab |
        Select-Object SqlInstance, Name, RecoveryModel, SizeMB, LastFullBackup


<# ---------- Change one line ---------- #>

    $Targets = 'localhost,14317', 'localhost,14319', 'localhost,14322', 'localhost,14325'

    Get-DbaDatabase -SqlInstance $Targets -ExcludeSystem @Lab |
        Select-Object SqlInstance, Name, RecoveryModel, SizeMB, LastFullBackup |
        Sort-Object SqlInstance, Name


<# ---------- That is it. That is the trick. ---------- #>

<#
    No loop. No ForEach. No rewrite.

    Look at the parameter type and you can see why:

        (Get-Command Get-DbaDatabase).Parameters['SqlInstance'].ParameterType

    It is DbaInstanceParameter[] -- an ARRAY. Most of dbatools is built this way,
    so most of what you learned on one server already works on all of them.
#>

    (Get-Command Get-DbaDatabase).Parameters['SqlInstance'].ParameterType.Name


<# ---------- Where the list of servers really comes from ---------- #>

<#
    Typing four server names is fine for a demo. In real life the list lives
    somewhere already, and you read it from there:

        # Registered Servers / CMS -- the one most shops already have
        $Targets = (Get-DbaRegServer -SqlInstance 'YourCmsServer').ServerName

        # A text file, one server per line
        $Targets = Get-Content 'C:\DBA\servers.txt'

        # A table in your admin database
        $Targets = (Invoke-DbaQuery -SqlInstance 'YourAdminServer' -Query "
                        SELECT ServerName FROM dbo.Instances WHERE IsActive = 1
                    ").ServerName

        # Or find them by scanning the network -- see _Toolbox\1 - Discovery
        $Targets = (Find-DbaInstance -DiscoveryType Domain).SqlInstance

    Once $Targets is populated, nothing downstream changes.
#>


<# ---------- How long did that take ---------- #>

    # We are going to keep score all session. Here is the first number.
    $elapsed = Measure-Command {
        Get-DbaDatabase -SqlInstance $Targets -ExcludeSystem @Lab | Out-Null
    }

    "{0} servers inventoried in {1:n1} seconds." -f $Targets.Count, $elapsed.TotalSeconds
    "By hand -- RDP, SSMS, expand the tree, read it off, type it up -- call it 6 minutes each: {0} minutes." -f ($Targets.Count * 6)
