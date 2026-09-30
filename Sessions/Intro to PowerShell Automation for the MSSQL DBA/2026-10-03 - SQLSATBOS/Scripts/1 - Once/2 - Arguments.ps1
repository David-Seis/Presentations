<#
    ACT 1: ONCE

    2 - Arguments.

    Arguments narrow and shape a command, exactly like parameters on a stored
    procedure. If you are comfortable with @Database = 'Sales', you already
    understand -Database Sales.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


<# ---------- Narrowing ---------- #>

    # Everything
    Get-DbaDatabase -SqlInstance $OneTarget @Lab

    # Just the user databases -- no master/model/msdb/tempdb noise
    Get-DbaDatabase -SqlInstance $OneTarget -ExcludeSystem @Lab

    # Just one
    Get-DbaDatabase -SqlInstance $OneTarget -Database Sales @Lab

    # Several
    Get-DbaDatabase -SqlInstance $OneTarget -Database Sales, Inventory @Lab


<# ---------- Shaping ---------- #>

    # Only databases in FULL recovery
    Get-DbaDatabase -SqlInstance $OneTarget -RecoveryModel Full @Lab

    # Only ones that are not online -- the kind of thing you want to know about
    Get-DbaDatabase -SqlInstance $OneTarget -Status Offline, Restoring, Suspect @Lab


<# ---------- Discovering arguments without leaving the editor ---------- #>

    # What can this command take?
    Get-Help Get-DbaDatabase -Parameter *  | Select-Object name, description -First 10

    # Worked examples, written by the people who built it
    Get-Help Get-DbaDatabase -Examples

    # Or just tab-complete after the dash. That is usually faster.


<# ---------- The same idea, running your own T-SQL ---------- #>

    # -Query takes the statement inline
    Invoke-DbaQuery -SqlInstance $OneTarget @Lab -Query "
        SELECT ServerName = @@SERVERNAME, Version = @@VERSION
    "

    # -File runs a .sql file you already have in source control.
    # $PSScriptRoot is the folder this script lives in, so the path works on any
    # machine -- never hard-code C:\Users\YourName\... in a demo you have to travel with.
    Invoke-DbaQuery -SqlInstance $OneTarget @Lab -File (Join-Path $PSScriptRoot 'basics.sql')


<# ---------- Splatting: the argument trick worth stealing today ---------- #>

<#
    When a command needs the same six arguments every time, put them in a hashtable
    and splat it with @. That is what @Lab has been doing this whole time:

        $Lab = @{ SqlCredential = $LabCredential }

    It keeps long commands readable, and it means you change a setting in one place
    instead of on forty lines.
#>

    $BackupArgs = @{
        SqlInstance  = $OneTarget
        Database     = 'Sales'
        Type         = 'Full'
        CompressBackup = $true
    }

    Backup-DbaDatabase @BackupArgs @Lab |
        Select-Object SqlInstance, Database, Type, TotalSize, Duration
