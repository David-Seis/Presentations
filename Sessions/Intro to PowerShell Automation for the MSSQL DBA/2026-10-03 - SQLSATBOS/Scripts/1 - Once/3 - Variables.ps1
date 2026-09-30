<#
    ACT 1: ONCE

    3 - Variables.

    A variable is just a named box. The reason it matters for this session is
    narrower than "programming 101": a variable is the seam where ONE server
    later becomes FORTY without touching anything else.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


<# ---------- Hoist the thing that changes ---------- #>

    # Before: the server name is buried in every line.
    Get-DbaDatabase -SqlInstance 'localhost,14322' -ExcludeSystem @Lab
    Get-DbaAgentJob  -SqlInstance 'localhost,14322' @Lab

    # After: named once, at the top, where you can find it.
    $Target = 'localhost,14322'

    Get-DbaDatabase -SqlInstance $Target -ExcludeSystem @Lab
    Get-DbaAgentJob  -SqlInstance $Target @Lab

    # Remember this shape. In Act 2 that single line becomes a list,
    # and nothing else in the script changes.


<# ---------- Variables hold objects, not just text ---------- #>

    $databases = Get-DbaDatabase -SqlInstance $Target -ExcludeSystem @Lab

    $databases.Count                                 # how many came back
    $databases[0].Name                               # reach into one
    $databases.Name                                  # or every name at once
    ($databases | Measure-Object SizeMB -Sum).Sum     # total size


<# ---------- Strings, and the gotcha that bites everyone ---------- #>

    $ServerLabel = 'Boston demo'
    $DbCount     = $databases.Count

    # Double quotes expand variables. Single quotes do not.
    Write-Host "There are $DbCount user databases on the $ServerLabel server."
    Write-Host 'There are $DbCount user databases on the $ServerLabel server.'

    # To reach a property from inside a string, wrap it in $( )
    Write-Host "First one is $($databases[0].Name), in $($databases[0].RecoveryModel) recovery."


<# ---------- Build values you will reuse ---------- #>

    # A timestamp safe for filenames: no colons, no slashes
    $Stamp      = Get-Date -Format 'yyyy-MM-dd_HHmm'
    $ReportFile = Join-Path $OutputPath "DatabaseReport_$Stamp.csv"

    $ReportFile

<#
    Two habits worth taking home:

      1. Anything you might change -- server names, paths, thresholds, retention --
         belongs in a variable at the top, not scattered through the script.

      2. Use Join-Path instead of gluing strings together with a backslash. It gets
         the separators right and survives being run from a different folder.
#>
