<#
    TOOLBOX  --  Migration and Refresh

    Refresh a non-production environment.

    "Can you refresh dev from prod?" -- the request every DBA gets weekly and
    nobody enjoys, because the restore is the easy part and the six steps after
    it are the ones you forget at 6pm on a Friday.

    Those steps are exactly why this belongs in a script rather than in your head.
#>

. "$PSScriptRoot\..\..\_Setup\Environment.ps1"


<# ---------- PARAMETERS ---------- #>

    $Source        = 'localhost,14322'          # production
    $Destination   = 'localhost,14325'          # the environment being refreshed
    $SourceDb      = 'Sales'
    $DestinationDb = 'Sales_Dev'
    $BackupFile    = "$LabContainerBackupPath/sqlsat2022_Sales_FULL.bak"

    # Dry run by default. Every step below only SAYS what it would do -- including
    # step 3, which copies EVERY non-system login and, with -Force, drops and
    # recreates any that already exist on the destination. Read the list, then set
    # this to $false and run it again.
    $DryRun        = $true

    if ($DryRun) {
        Write-Host "DRY RUN -- nothing below will change. Set `$DryRun = `$false to do it for real." -ForegroundColor Yellow
        Write-Host "(Steps 2, 4 and 5 will warn that $DestinationDb does not exist -- in a dry run it does not, yet.)" -ForegroundColor Yellow
    }


<# ---------- 1. Restore ---------- #>

    Write-Host "1/6  Restoring $SourceDb to $Destination as $DestinationDb..." -ForegroundColor Green

    Restore-DbaDatabase -SqlInstance $Destination @Lab `
        -Path                             $BackupFile `
        -DatabaseName                     $DestinationDb `
        -ReplaceDbNameInFile `
        -UseDestinationDefaultDirectories `
        -WithReplace -WhatIf:$DryRun | Out-Null


<# ---------- 2. Recovery model ---------- #>

<#
    A dev copy inheriting FULL recovery will grow a transaction log nobody is
    backing up until the drive fills. This single line prevents a surprising
    number of 3am pages.
#>

    Write-Host "2/6  Setting SIMPLE recovery..." -ForegroundColor Green
    Set-DbaDbRecoveryModel -SqlInstance $Destination @Lab `
        -Database $DestinationDb -RecoveryModel Simple -Confirm:$false -WhatIf:$DryRun | Out-Null


<# ---------- 3. Logins ---------- #>

<#
    The database arrived; the logins did not. Copy-DbaLogin preserves the SID,
    which is what stops the users inside the database from being orphaned.
#>

    Write-Host "3/6  Copying logins..." -ForegroundColor Green
    Copy-DbaLogin -Source $Source -Destination $Destination `
        -SourceSqlCredential $LabCredential -DestinationSqlCredential $LabCredential `
        -ExcludeSystemLogins -Force -WhatIf:$DryRun | Out-Null


<# ---------- 4. Orphaned users ---------- #>

<#
    The step everyone forgets. Even with logins copied, a mismatch leaves users
    stranded inside the database and the application cannot connect -- with an
    error that points at permissions rather than at this.
#>

    Write-Host "4/6  Repairing orphaned users..." -ForegroundColor Green
    Repair-DbaDbOrphanUser -SqlInstance $Destination @Lab -Database $DestinationDb -WhatIf:$DryRun | Out-Null


<# ---------- 5. Ownership ---------- #>

    Write-Host "5/6  Setting database owner..." -ForegroundColor Green
    Set-DbaDbOwner -SqlInstance $Destination @Lab -Database $DestinationDb -TargetLogin sa -WhatIf:$DryRun | Out-Null


<# ---------- 6. Make it obviously not production ---------- #>

<#
    Two reasons. One, somebody will connect to the wrong window. Two, jobs and
    integrations pointed at production tables will happily run against a dev copy
    and email real customers. Scrub the things that reach outside.
#>

    Write-Host "6/6  Post-refresh cleanup..." -ForegroundColor Green

    # Invoke-DbaQuery has no -WhatIf, so the dry run simply skips it.
    if (-not $DryRun) { Invoke-DbaQuery -SqlInstance $Destination @Lab -Database $DestinationDb -Query "
        -- Break anything that could contact the outside world from a dev copy.
        -- Adapt this to your schema; the principle is what matters.
        IF OBJECT_ID('dbo.EmailQueue') IS NOT NULL
            UPDATE dbo.EmailQueue SET IsEnabled = 0;

        IF OBJECT_ID('dbo.AppConfig') IS NOT NULL
            UPDATE dbo.AppConfig
            SET    ConfigValue = 'DEV'
            WHERE  ConfigKey = 'Environment';
    " }


<# ---------- Sensitive data ---------- #>

<#
    If the refresh crosses a compliance boundary -- production customer data into
    an environment developers and contractors can read -- masking is not optional.

        New-DbaDbMaskingConfig -SqlInstance $Destination -Database $DestinationDb -Path C:\masking
        # edit the generated JSON: which columns, what kind of fake data
        Invoke-DbaDbDataMasking -SqlInstance $Destination -Database $DestinationDb -FilePath C:\masking\...json

    Generating the config is the slow part and you only do it once per schema.
#>


<# ---------- Confirm ---------- #>

    Get-DbaDatabase -SqlInstance $Destination @Lab -Database $DestinationDb |
        Select-Object SqlInstance, Name, RecoveryModel, Owner, SizeMB, CreateDate |
        Format-Table -AutoSize

    Get-DbaDbOrphanUser -SqlInstance $Destination @Lab -Database $DestinationDb |
        Select-Object SqlInstance, DatabaseName, User

    if ($DryRun) {
        Write-Host "`nDry run complete -- nothing was changed." -ForegroundColor Yellow
    } else {
        Write-Host "`nRefresh complete." -ForegroundColor Green
    }


<# ---------- Worth saying out loud ---------- #>

<#
    Once this is a script, the request stops being a ninety-minute interruption
    and becomes something you can hand to the dev team behind a button -- or
    schedule for 6am every Monday so nobody has to ask at all.

    That is the actual win. Not that the restore is faster, but that the task
    stops belonging to you.
#>
