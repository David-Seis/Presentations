<#
    ACT 2: EVERYWHERE

    2 - Fleet inventory.

    "What do we actually have?" is the question every DBA gets asked and almost
    nobody can answer quickly. This builds the answer for the whole estate, in
    one pass, and writes it somewhere you can keep.

    Note the versions coming back differ per server. That is the point -- this is
    what a real estate looks like, and it is why eyeballing does not scale.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"

$Stamp    = Get-Date -Format 'yyyy-MM-dd_HHmm'
$CsvPath  = Join-Path $OutputPath "FleetInventory_$Stamp.csv"


<# ---------- The instance level ---------- #>

    Write-Host "Collecting instance details..." -ForegroundColor Green

    $instances = Get-DbaInstanceProperty -SqlInstance $Targets @Lab |
        Where-Object Name -in 'VersionString', 'Edition', 'ProductLevel', 'Collation', 'IsClustered'

    # Get-DbaInstanceProperty returns one ROW PER PROPERTY. Pivot it so each server
    # is a single row -- Group-Object plus a calculated property does it neatly.
    $inventory = $instances |
        Group-Object SqlInstance |
        ForEach-Object {
            $p = @{}
            $_.Group | ForEach-Object { $p[$_.Name] = $_.Value }

            [PSCustomObject]@{
                SqlInstance  = $_.Name
                Version      = $p['VersionString']
                Edition      = $p['Edition']
                ProductLevel = $p['ProductLevel']
                Collation    = $p['Collation']
                IsClustered  = $p['IsClustered']
                Collected    = Get-Date
            }
        }

    $inventory | Format-Table -AutoSize


<# ---------- The database level ---------- #>

    Write-Host "Collecting database details..." -ForegroundColor Green

    $databases = Get-DbaDatabase -SqlInstance $Targets -ExcludeSystem @Lab |
        Select-Object SqlInstance,
                      Name,
                      RecoveryModel,
                      Compatibility,
                      Owner,
                      @{ n = 'SizeMB';  e = { [math]::Round($_.SizeMB, 0) } },
                      LastFullBackup,
                      LastLogBackup,
                      @{ n = 'Collected'; e = { Get-Date } }

    $databases | Sort-Object SqlInstance, Name | Format-Table -AutoSize


<# ---------- Keep it ---------- #>

    $databases | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host "Written to $CsvPath" -ForegroundColor Green

    # A CSV is fine for today. In Act 3 this same data goes into a table so you can
    # compare this week against last week and see what changed.


<# ---------- Now ask it a question ---------- #>

    # Anything on an unsupported compatibility level?
    $databases | Where-Object Compatibility -lt 'Version140' |
        Select-Object SqlInstance, Name, Compatibility

    # Anything owned by a person rather than sa? (the classic audit finding --
    # when that person leaves, the database goes with them)
    $databases | Where-Object Owner -ne 'sa' |
        Select-Object SqlInstance, Name, Owner

    # FULL recovery with no log backup -- the log will grow until the disk fills
    $databases | Where-Object { $_.RecoveryModel -eq 'Full' -and -not $_.LastLogBackup } |
        Select-Object SqlInstance, Name, RecoveryModel, LastFullBackup


<# ---------- Scoreboard ---------- #>

    $elapsed = Measure-Command {
        Get-DbaDatabase -SqlInstance $Targets -ExcludeSystem @Lab | Out-Null
    }
    "{0} servers inventoried in {1:n1}s" -f $Targets.Count, $elapsed.TotalSeconds
