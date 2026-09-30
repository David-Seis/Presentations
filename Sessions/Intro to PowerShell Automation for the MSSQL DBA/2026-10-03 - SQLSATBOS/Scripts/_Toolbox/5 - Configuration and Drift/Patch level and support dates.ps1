<#
    TOOLBOX  --  Configuration and Drift

    Patch level and support dates.

    Two questions your manager will eventually ask, usually in the same week:

      "Are we patched?"
      "Is anything out of support?"

    Test-DbaBuild answers both, from a build reference dbatools keeps updated. No
    spreadsheet, no cross-referencing KB articles.
#>

. "$PSScriptRoot\..\..\_Setup\Environment.ps1"

$Stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'


<# ---------- Refresh the build index first ---------- #>

<#
    dbatools ships a local index of every SQL Server build, its CU level and its
    support end date. It goes stale between module updates, and a stale index
    means wrong answers to "are we patched" and "when does support end".

    It needs internet access, so do this BEFORE you travel -- not on venue wifi.
#>

    # Update-DbaBuildReference

    Write-Host "If you see a 'build reference index is stale' warning below, run Update-DbaBuildReference." -ForegroundColor DarkGray


<# ---------- Where is everything? ---------- #>

    $builds = Test-DbaBuild -SqlInstance $Targets @Lab -Latest

    $builds |
        Select-Object SqlInstance, Build, NameLevel, SPLevel, CULevel, BuildLevel,
                      SupportedUntil, Compliant, Warning |
        Sort-Object SqlInstance |
        Format-Table -AutoSize


<# ---------- What is behind? ---------- #>

    Write-Host "`nNot on the latest build:" -ForegroundColor Yellow
    $builds | Where-Object { -not $_.Compliant } |
        Select-Object SqlInstance, NameLevel, Build, BuildTarget, CULevel |
        Format-Table -AutoSize


<# ---------- What is out of support, or nearly? ---------- #>

<#
    SupportedUntil is the date Microsoft stops shipping security fixes. After it,
    a vulnerability in SQL Server is your problem permanently. This is the column
    that unlocks budget.
#>

    Write-Host "Out of support, or within a year of it:" -ForegroundColor Red
    $builds |
        Where-Object { $_.SupportedUntil -and $_.SupportedUntil -lt (Get-Date).AddYears(1) } |
        Select-Object SqlInstance, NameLevel, Build, SupportedUntil,
                      @{ n = 'DaysLeft'; e = { (New-TimeSpan -Start (Get-Date) -End $_.SupportedUntil).Days } } |
        Sort-Object DaysLeft |
        Format-Table -AutoSize


<# ---------- Look up a build without connecting to anything ---------- #>

    # "What is 15.0.4470.1?"
    Get-DbaBuildReference -Build '15.0.4470.1'

    # "What is the newest 2019 build?"
    Get-DbaBuildReference -SqlInstance $Targets @Lab | Select-Object SqlInstance, NameLevel, SPLevel, CULevel


<# ---------- Deprecated features still in use ---------- #>

<#
    The other half of upgrade planning: what will BREAK. This reads the counters
    SQL Server keeps of deprecated feature usage, so it tells you what is actually
    being used rather than what might be.

    A non-zero count means something in your application still depends on it.
#>

    Get-DbaDeprecatedFeature -SqlInstance $Targets @Lab |
        Where-Object UsageCount -gt 0 |
        Select-Object SqlInstance, DeprecatedFeature, UsageCount |
        Sort-Object UsageCount -Descending |
        Format-Table -AutoSize


<# ---------- What is even installed on the box? ---------- #>

    # Real servers only -- reaches the Windows side.
    # Get-DbaFeature -ComputerName $Targets |
    #     Select-Object ComputerName, Feature, Version, InstanceName


<# ---------- A report you can hand over ---------- #>

    $report = $builds | Select-Object SqlInstance, NameLevel, Build, CULevel, SupportedUntil, Compliant

    $report | Export-Csv (Join-Path $OutputPath "PatchLevels_$Stamp.csv") -NoTypeInformation

    $report |
        ConvertTo-Html -Title 'SQL Server patch and support status' `
                       -PreContent "<h2>Patch and support status</h2><p>Generated $(Get-Date)</p>" |
        Out-File (Join-Path $OutputPath "PatchLevels_$Stamp.html")

    Write-Host "`nWritten to $OutputPath" -ForegroundColor Green
