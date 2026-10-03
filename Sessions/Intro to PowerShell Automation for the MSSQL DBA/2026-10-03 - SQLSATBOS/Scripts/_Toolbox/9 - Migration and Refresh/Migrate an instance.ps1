<#
    TOOLBOX  --  Migration and Refresh

    Migrate an instance.

    Moving to new hardware is where dbatools stops being convenient and starts
    being the reason the project finished on time.

    The databases are the easy part. What catches people out is everything else:
    logins with their original SIDs, Agent jobs, linked servers, credentials,
    proxies, operators, alerts, database mail, sp_configure settings, custom error
    messages. Miss one and something breaks a week later with no obvious cause.
#>

. "$PSScriptRoot\..\..\_Setup\Environment.ps1"


<# ---------- PARAMETERS ---------- #>

    $Source      = 'localhost,14322'
    $Destination = 'localhost,14325'

    # Credentials for both ends. On a domain with Windows auth you delete these.
    $Cred = @{
        SourceSqlCredential      = $LabCredential
        DestinationSqlCredential = $LabCredential
    }


<# ---------- Can it even be migrated? ---------- #>

    Test-DbaMigrationConstraint -Source $Source -Destination $Destination @Cred |
        Select-Object SourceInstance, DestinationInstance, Database, FeaturesInUse, IsMigratable, Notes |
        Format-Table -AutoSize -Wrap

<#
    Catches the things that stop a migration dead:
      - Enterprise features on the source, Standard on the destination
      - destination on an older version than the source
#>


<# ---------- The whole thing, one command ---------- #>

<#
    Start-DbaMigration does everything below in the right order. Run it with
    -WhatIf first, always -- it will list exactly what it intends to move.

    -BackupRestore with -SharedPath is the usual method. Both servers need to
    reach that path, and the service accounts need rights to it.
#>

    # Start-DbaMigration -Source $Source -Destination $Destination @Cred `
    #     -BackupRestore -SharedPath '\\fileserver\sqlmigration' `
    #     -Exclude BackupDevices, ExtendedEvents `
    #     -WhatIf


<# ---------- Or piece by piece, which is what most real migrations do ---------- #>

<#
    Big-bang migrations are rare. Usually you move the supporting objects days
    ahead, test, and cut the databases over in the window. Each of these is
    independently re-runnable.
#>

    # 1. Logins FIRST -- SIDs preserved, so database users are not orphaned.
    Copy-DbaLogin -Source $Source -Destination $Destination @Cred -ExcludeSystemLogins -WhatIf

    # 2. Instance configuration
    # Copy-DbaSpConfigure   -Source $Source -Destination $Destination @Cred
    # Copy-DbaCredential    -Source $Source -Destination $Destination @Cred
    # Copy-DbaLinkedServer  -Source $Source -Destination $Destination @Cred

    # 3. Agent
    # Copy-DbaAgentJobCategory -Source $Source -Destination $Destination @Cred
    # Copy-DbaAgentJob         -Source $Source -Destination $Destination @Cred
    # Copy-DbaAgentOperator    -Source $Source -Destination $Destination @Cred
    # Copy-DbaAgentAlert       -Source $Source -Destination $Destination @Cred
    # Copy-DbaAgentProxy       -Source $Source -Destination $Destination @Cred
    # Copy-DbaAgentSchedule    -Source $Source -Destination $Destination @Cred

    # 4. Mail
    # Copy-DbaDbMail -Source $Source -Destination $Destination @Cred

    # 5. Databases, last
    # Copy-DbaDatabase -Source $Source -Destination $Destination @Cred `
    #     -BackupRestore -SharedPath '\\fileserver\sqlmigration' -AllDatabases


<# ---------- After the move ---------- #>

    # Orphans -- should be none if logins went first, but check anyway
    Get-DbaDbOrphanUser -SqlInstance $Destination @Lab |
        Select-Object SqlInstance, DatabaseName, User | Format-Table -AutoSize

    # Compatibility level does NOT change on restore. A database moved from 2017
    # to 2025 still runs at 140 until you raise it -- deliberately, after testing.
    Test-DbaDbCompatibility -SqlInstance $Destination @Lab |
        Select-Object SqlInstance, Database, DatabaseCompatibility, ServerLevel, IsEqual |
        Format-Table -AutoSize

    # Owners often end up as whoever ran the restore
    Test-DbaDbOwner -SqlInstance $Destination @Lab |
        Where-Object { -not $_.OwnerMatch } |
        Select-Object SqlInstance, Database, CurrentOwner, TargetOwner |
        Format-Table -AutoSize

    # Update statistics -- plans on the new server are built from whatever
    # statistics came across, which may be stale.
    # Get-DbaDatabase -SqlInstance $Destination -ExcludeSystem |
    #     ForEach-Object { Invoke-DbaQuery -SqlInstance $Destination -Database $_.Name -Query "EXEC sp_updatestats" }


<# ---------- Before you switch anything off ---------- #>

<#
    Keep the old server powered on but with SQL Server disabled for a couple of
    weeks. Every migration turns up one forgotten connection string, and being
    able to switch the old instance back on for ten minutes is much better than
    discovering the hard way that it has been decommissioned.

    Take a full Export-DbaInstance of the source before you start -- see
    _Toolbox\1 - Discovery and Inventory. It costs a minute and it is the record
    of what the old server actually looked like.
#>
