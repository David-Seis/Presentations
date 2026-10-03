<#
    TOOLBOX  --  Configuration and Drift

    Best practice sweep.

    dbatools ships a family of Test- commands that each encode one well-known
    configuration recommendation. Individually they are one-liners. Together they
    are a health check you can run on a new client, or on your own estate, in
    about fifteen seconds.

    Everything here is READ ONLY. The Set- equivalents are noted but commented out.
#>

. "$PSScriptRoot\..\..\_Setup\Environment.ps1"

$Stamp    = Get-Date -Format 'yyyy-MM-dd_HHmm'
$findings = [System.Collections.Generic.List[object]]::new()

function Add-Finding {
    param([string]$Server, [string]$Check, [string]$Current, [string]$Recommended, [string]$Note = '')
    $findings.Add([PSCustomObject]@{
        Server = $Server; Check = $Check; Current = $Current; Recommended = $Recommended; Note = $Note
    })
}


<# ---------- Max memory ---------- #>

<#
    Left at the default, SQL Server will take everything and starve Windows.
    Test-DbaMaxMemory recommends a value based on the RAM actually present.
#>

    Test-DbaMaxMemory -SqlInstance $Targets @Lab | ForEach-Object {
        if ($_.MaxValue -ne $_.RecommendedValue) {
            Add-Finding $_.SqlInstance 'Max memory' "$($_.MaxValue) MB" "$($_.RecommendedValue) MB"
        }
    }
    # Set-DbaMaxMemory -SqlInstance $Targets @Lab -WhatIf


<# ---------- MAXDOP ---------- #>

<#
    Test-DbaMaxDop returns one row PER DATABASE, each carrying the same
    instance-level value. Group by instance first or you get the identical
    finding repeated once per database.
#>

    Test-DbaMaxDop -SqlInstance $Targets @Lab |
        Group-Object SqlInstance |
        ForEach-Object {
            $row = $_.Group[0]
            if ($row.CurrentInstanceMaxDop -ne $row.RecommendedMaxDop) {
                Add-Finding $row.SqlInstance 'MAXDOP' $row.CurrentInstanceMaxDop $row.RecommendedMaxDop $row.Notes
            }
        }
    # Set-DbaMaxDop -SqlInstance $Targets @Lab -WhatIf


<# ---------- TempDB ---------- #>

<#
    One data file per core up to eight, all the same size, all the same autogrowth.
    Still one of the highest-value fixes on a busy server.
#>

    Test-DbaTempDbConfig -SqlInstance $Targets @Lab | ForEach-Object {
        if (-not $_.IsBestPractice) {
            Add-Finding $_.SqlInstance "TempDB: $($_.Rule)" $_.CurrentSetting $_.Recommended $_.Notes
        }
    }


<# ---------- Instant File Initialization ---------- #>

<#
    Without it, every data file growth zeroes the new space first -- so a big
    autogrowth stalls the database while it writes gigabytes of zeroes. Turning
    it on is a two-minute change that people notice immediately.
#>

<#
    Note this one takes -ComputerName, not -SqlInstance: it is reading a Windows
    user-rights assignment, not a SQL setting. So it needs remote admin rights and
    will not run against the container lab.
#>

    # Get-DbaPrivilege lists every account holding these rights. '*MSSQL*' matches the
    # default NT SERVICE\MSSQLSERVER account -- swap in your own service account name.
    # Get-DbaPrivilege -ComputerName 'SQLPROD01', 'SQLPROD02' |
    #     Where-Object { $_.User -like '*MSSQL*' -and -not $_.InstantFileInitialization } | ForEach-Object {
    #         Add-Finding $_.ComputerName 'Instant File Initialization' 'Disabled' 'Enabled' 'Grant "Perform volume maintenance tasks" to the SQL service account'
    #     }

    # SQL-side equivalent that DOES work anywhere you can connect:
    Invoke-DbaQuery -SqlInstance $Targets @Lab -Query "
        SELECT ServerName = @@SERVERNAME, instant_file_initialization_enabled
        FROM   sys.dm_server_services
        WHERE  servicename LIKE 'SQL Server (%'
    " -EnableException:$false -WarningAction SilentlyContinue | ForEach-Object {
        if ($_.instant_file_initialization_enabled -eq 'N') {
            Add-Finding $_.ServerName 'Instant File Initialization' 'Disabled' 'Enabled' 'Grant "Perform volume maintenance tasks" to the SQL service account'
        }
    }


<# ---------- Database and job owners ---------- #>

    Test-DbaDbOwner -SqlInstance $Targets @Lab | Where-Object { -not $_.OwnerMatch } | ForEach-Object {
        Add-Finding $_.SqlInstance "Database owner: $($_.Database)" $_.CurrentOwner $_.TargetOwner
    }

    Test-DbaAgentJobOwner -SqlInstance $Targets @Lab | Where-Object { -not $_.OwnerMatch } | ForEach-Object {
        # This one reports the server as Server, and the owner as CurrentOwner
        Add-Finding $_.Server "Job owner: $($_.Job)" $_.CurrentOwner $_.TargetOwner
    }


<# ---------- Optimize for ad hoc workloads ---------- #>

    Test-DbaOptimizeForAdHoc -SqlInstance $Targets @Lab | ForEach-Object {
        if ($_.CurrentOptimizeAdHoc -ne $_.RecommendedOptimizeAdHoc) {
            Add-Finding $_.SqlInstance 'Optimize for ad hoc workloads' $_.CurrentOptimizeAdHoc $_.RecommendedOptimizeAdHoc
        }
    }


<# ---------- Compatibility level ---------- #>

<#
    A database still on an old compatibility level after an upgrade is not getting
    the new optimizer. Very common, because the upgrade moved the database but
    nobody wanted to risk the plan changes afterwards.
#>

    Test-DbaDbCompatibility -SqlInstance $Targets @Lab | Where-Object { -not $_.IsEqual } | ForEach-Object {
        Add-Finding $_.SqlInstance "Compatibility: $($_.Database)" $_.DatabaseCompatibility $_.ServerLevel
    }


<# ---------- Collation mismatches ---------- #>

    Test-DbaDbCollation -SqlInstance $Targets @Lab | Where-Object { -not $_.IsEqual } | ForEach-Object {
        Add-Finding $_.SqlInstance "Collation: $($_.Database)" $_.DatabaseCollation $_.ServerCollation 'Mismatch causes tempdb join errors'
    }


<# ---------- Windows-side checks (real servers only) ---------- #>

    # Test-DbaPowerPlan     -ComputerName $Targets   # Balanced throttles the CPU
    # Test-DbaDiskAlignment -ComputerName $Targets
    # Test-DbaSpn           -ComputerName $Targets   # Kerberos / double-hop problems


<# ---------- The report ---------- #>

    Write-Host "`n$($findings.Count) finding(s):`n" -ForegroundColor Cyan
    $findings | Sort-Object Server, Check | Format-Table -AutoSize

    $findings | Export-Csv (Join-Path $OutputPath "BestPractice_$Stamp.csv") -NoTypeInformation

    # A shareable version
    $findings | Sort-Object Server, Check |
        ConvertTo-Html -Title 'SQL Server best practice sweep' `
                       -PreContent "<h2>Best practice sweep</h2><p>Generated $(Get-Date)</p>" |
        Out-File (Join-Path $OutputPath "BestPractice_$Stamp.html")

    Write-Host "Report written to $OutputPath" -ForegroundColor Green
