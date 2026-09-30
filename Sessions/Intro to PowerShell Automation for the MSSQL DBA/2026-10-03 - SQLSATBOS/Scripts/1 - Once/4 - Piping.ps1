<#
    ACT 1: ONCE

    4 - Piping.

    The pipe hands the objects from one command to the next. It is the single
    highest-leverage thing in PowerShell, so we learn it on silly data first --
    then point it at SQL Server, where the shapes are identical.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


<# ---------- Learn the verbs on data you do not have to think about ---------- #>

    $Actors = 'Viggo Mortensen', 'Elijah Wood', 'Ian McKellen', 'Orlando Bloom', 'Sean Bean', 'Liv Tyler'

    # Where-Object  = WHERE
    $Actors | Where-Object { $_ -match 'o' }

    # Sort-Object   = ORDER BY
    $Actors | Sort-Object

    # Select-Object = SELECT / TOP
    $Actors | Sort-Object | Select-Object -First 3

    # ForEach-Object = do this to each row. $_ is "the current one".
    $Actors | ForEach-Object { $_.ToUpper() }

    # Chain them and you have written a query.
    $Actors |
        Where-Object { $_ -like '*o*' } |
        Sort-Object |
        Select-Object -First 3


<# ---------- Now exactly the same verbs, against SQL Server ---------- #>

    $Target = $OneTarget

    # "Which user databases are over 50 MB, biggest first?"
    Get-DbaDatabase -SqlInstance $Target -ExcludeSystem @Lab |
        Where-Object SizeMB -gt 50 |
        Sort-Object SizeMB -Descending |
        Select-Object Name, RecoveryModel, SizeMB, LastFullBackup

    # "Which databases are in FULL recovery but have never had a log backup?"
    # That is a production incident waiting to happen, and it is one line.
    Get-DbaDatabase -SqlInstance $Target -ExcludeSystem @Lab |
        Where-Object { $_.RecoveryModel -eq 'Full' -and -not $_.LastLogBackup } |
        Select-Object Name, RecoveryModel, LastFullBackup, LastLogBackup


<# ---------- Shaping the output: build the columns you want ---------- #>

    # Select-Object can compute new columns. n = name, e = expression.
    Get-DbaDatabase -SqlInstance $Target -ExcludeSystem @Lab |
        Select-Object Name,
                      RecoveryModel,
                      @{ n = 'SizeGB';      e = { [math]::Round($_.SizeMB / 1024, 2) } },
                      @{ n = 'DaysSinceFull'; e = { if ($_.LastFullBackup) { (New-TimeSpan -Start $_.LastFullBackup).Days } } } |
        Sort-Object DaysSinceFull -Descending


<# ---------- The pipe is also how results leave PowerShell ---------- #>

    $Stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'

    # To a grid you can click around in
    Get-DbaDatabase -SqlInstance $Target -ExcludeSystem @Lab |
        Select-Object Name, RecoveryModel, SizeMB, LastFullBackup |
        Out-GridView -Title 'Databases'

    # To CSV
    Get-DbaDatabase -SqlInstance $Target -ExcludeSystem @Lab |
        Select-Object Name, RecoveryModel, SizeMB, LastFullBackup |
        Export-Csv -Path (Join-Path $OutputPath "Databases_$Stamp.csv") -NoTypeInformation

    # To JSON, HTML, the clipboard, a database table... same pipe, different ending.


<# ---------- One thing worth knowing before you get bitten ---------- #>

<#
    Filter as early in the pipe as you can.

        Get-DbaDatabase -SqlInstance $Target -Database Sales        # asks for one
        Get-DbaDatabase -SqlInstance $Target | Where Name -eq 'Sales'  # fetches all, throws most away

    Against one server nobody notices. Against forty, the first is the one that
    finishes while you are still talking.
#>
