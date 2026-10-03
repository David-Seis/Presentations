<#
    TOOLBOX  --  Security and Access

    Who has access to what.

    The audit question, and the one that takes a week by hand because the answer
    lives in three places: server roles, database roles, and explicit object
    permissions -- multiplied by every server.

    Run this before the auditor asks, not after.
#>

. "$PSScriptRoot\..\..\_Setup\Environment.ps1"

$Stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'


<# ---------- Who is a sysadmin? ---------- #>

<#
    Start here. This is the answer that makes people uncomfortable, because it is
    almost always longer than they expect and contains at least one account
    belonging to somebody who left.
#>

    Get-DbaServerRoleMember -SqlInstance $Targets @Lab -ServerRole sysadmin |
        Select-Object SqlInstance, Role, Name |
        Sort-Object SqlInstance, Name |
        Format-Table -AutoSize


<# ---------- All server-level roles ---------- #>

    Get-DbaServerRoleMember -SqlInstance $Targets @Lab |
        Select-Object SqlInstance, Role, Name |
        Sort-Object SqlInstance, Role, Name |
        Out-GridView -Title 'Server role membership'


<# ---------- Every login, and the state it is in ---------- #>

    Get-DbaLogin -SqlInstance $Targets @Lab |
        Select-Object SqlInstance, Name, LoginType, CreateDate, LastLogin,
                      IsDisabled, IsLocked, PasswordPolicyEnforced, PasswordExpirationEnabled |
        Sort-Object SqlInstance, Name |
        Format-Table -AutoSize

    # Enabled SQL logins with the password policy switched off -- a common finding,
    # because it is how people get around a password that keeps expiring.
    Get-DbaLogin -SqlInstance $Targets @Lab -Type SQL |
        Where-Object { -not $_.IsDisabled -and -not $_.PasswordPolicyEnforced } |
        Select-Object SqlInstance, Name, CreateDate, LastLogin |
        Format-Table -AutoSize

    # Enabled logins with no session open right now. A starting list, not a verdict:
    # LastLogin is read from sys.dm_exec_sessions, so it only sees CURRENT sessions --
    # a login that connected an hour ago and disconnected has no LastLogin at all.
    # For real "unused for 90 days" you need a login audit or trigger collecting
    # over time -- which is Act 3's point about keeping history.
    Get-DbaLogin -SqlInstance $Targets @Lab |
        Where-Object { -not $_.LastLogin -and -not $_.IsDisabled } |
        Select-Object SqlInstance, Name, LoginType, CreateDate |
        Sort-Object SqlInstance, Name |
        Format-Table -AutoSize


<# ---------- Database-level roles ---------- #>

    Get-DbaDbRoleMember -SqlInstance $Targets @Lab -ExcludeDatabase tempdb |
        Select-Object SqlInstance, Database, Role, UserName |
        Sort-Object SqlInstance, Database, Role |
        Out-GridView -Title 'Database role membership'

    # db_owner is the one to look at first.
    Get-DbaDbRoleMember -SqlInstance $Targets @Lab -Role db_owner |
        Select-Object SqlInstance, Database, Role, UserName |
        Format-Table -AutoSize


<# ---------- The full permission picture ---------- #>

<#
    Get-DbaUserPermission walks server roles, database roles AND explicit object
    grants and flattens the lot. It is slow on a big instance -- it is doing real
    work -- so scope it to the databases you care about.
#>

    $perms = Get-DbaUserPermission -SqlInstance $OneTarget @Lab -Database $LabDatabases

    $perms | Select-Object SqlInstance, Object, Type, Member, Permission, RoleSecurableClass, Securable |
        Out-GridView -Title 'Full permission map'

    $perms | Export-Csv (Join-Path $OutputPath "Permissions_$Stamp.csv") -NoTypeInformation


<# ---------- Who is behind that AD group? ---------- #>

<#
    A login of [DOMAIN\SQL-Admins] tells you nothing on its own. This expands the
    group so the report names actual people -- which is what an auditor wants.

    Needs a domain, so it will not run against the container lab.
#>

    # Find-DbaLoginInGroup -SqlInstance $Targets |
    #     Select-Object SqlInstance, Login, DisplayName, MemberOf, ParentADGroupLogin |
    #     Out-GridView -Title 'People behind the groups'


<# ---------- Orphaned users ---------- #>

<#
    A database user whose SID no longer matches any login. Classic after a restore
    to a different server -- the user is in the database, the login is not on the
    instance, and the application cannot connect.
#>

    Get-DbaDbOrphanUser -SqlInstance $Targets @Lab |
        Select-Object SqlInstance, DatabaseName, User |
        Format-Table -AutoSize

    # Repair-DbaDbOrphanUser -SqlInstance $OneTarget @Lab -WhatIf


<# ---------- Weak passwords ---------- #>

<#
    Tests SQL logins against a dictionary of common passwords. Extremely effective
    and extremely awkward -- get written permission first, and do not put the
    results on a projector.
#>

    # Test-DbaLoginPassword -SqlInstance $Targets @Lab |
    #     Select-Object SqlInstance, SqlLogin, Password
