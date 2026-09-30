<#
    ACT 1: ONCE

    5 - Modules.

    Where did Get-DbaDatabase come from? Not from PowerShell. A module is a
    bundle of commands someone else already wrote and tested, and for SQL Server
    DBAs the relevant one is dbatools -- free, open source, and the reason this
    session is an hour instead of a semester.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


<# ---------- Getting it ---------- #>

<#
    One time, per machine:

        Install-Module dbatools -Scope CurrentUser

    -Scope CurrentUser avoids needing admin rights, which matters on a locked-down
    work laptop. On a server with no internet, use Save-Module on a machine that
    does have it and copy the folder across.
#>

    # Is it here, and which version?
    Get-Module -ListAvailable dbatools |
        Select-Object Name, Version, Path

    # Load it into this session (PowerShell usually does this for you on first use)
    Import-Module dbatools


<# ---------- How big is the toolbox, really ---------- #>

    # The number that gets people's attention:
    (Get-Command -Module dbatools).Count

    # Browse them. Verb-Noun means you can guess, and usually be right.
    Get-Command -Module dbatools |
        Sort-Object Name |
        Out-GridView -Title 'Every dbatools command'


<# ---------- Finding the command you need ---------- #>

    # "Something about backups"
    Get-Command -Module dbatools -Name '*backup*' | Sort-Object Name

    # "Something that CHECKS things" -- the Test- verb is a goldmine
    Get-Command -Module dbatools -Verb Test | Sort-Object Name

    # "Something that COPIES things to another server" -- this is the migration story
    Get-Command -Module dbatools -Verb Copy | Sort-Object Name

    # Then read how to use it
    Get-Help Get-DbaLastBackup -Examples


<# ---------- The other module you will hear about ---------- #>

<#
    Microsoft ships a module called SqlServer. It is the official one, it owns
    Invoke-Sqlcmd, and it is what you will find pre-installed in places.

    dbatools is the community one. It is broader, and it is built around the
    tasks a DBA actually performs rather than around the object model.

    They coexist fine. Most people end up using both, and nearly everything in
    this session is dbatools.

        Install-Module SqlServer -Scope CurrentUser
#>


<# ---------- A safety habit before you point this at production ---------- #>

    # Most commands that CHANGE something support -WhatIf. It tells you what would
    # happen and does nothing. Use it the first time, every time.
    Backup-DbaDatabase -SqlInstance $OneTarget -Database Sales -Type Full @Lab -WhatIf

    # And -Confirm makes it ask before each change.
    # Get in the habit now, while the blast radius is a container.
