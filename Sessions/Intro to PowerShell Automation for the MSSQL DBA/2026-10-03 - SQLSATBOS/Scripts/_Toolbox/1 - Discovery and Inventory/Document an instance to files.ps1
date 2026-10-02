<#
    TOOLBOX  --  Discovery and Inventory

    Document an instance to files.

    Export-DbaInstance scripts out everything that is NOT in a backup: logins and
    their SIDs, Agent jobs, linked servers, credentials, proxies, operators,
    alerts, sp_configure settings, resource governor, endpoints, database mail.

    Two reasons to run it:

      1. DR. A database backup restores the data. It does not restore the login
         that the application connects with, or the job that backs it up. This is
         the other half, and people discover that during the outage.

      2. Source control. Commit the output weekly and every configuration change
         on your estate shows up as a diff, with a date and an author.
#>

. "$PSScriptRoot\..\..\_Setup\Environment.ps1"


<# ---------- PARAMETERS ---------- #>

    $ExportRoot = Join-Path $OutputPath 'InstanceExport'


<# ---------- Everything ---------- #>

    # Slow by nature: about four and a half minutes for the four lab servers.
    Export-DbaInstance -SqlInstance $Targets @Lab -Path $ExportRoot

    Write-Host "`nExported to $ExportRoot" -ForegroundColor Green
    Get-ChildItem $ExportRoot -Recurse -File |
        Select-Object @{ n = 'File'; e = { $_.FullName.Replace($ExportRoot, '') } },
                      @{ n = 'KB';   e = { [math]::Round($_.Length / 1KB, 1) } } |
        Format-Table -AutoSize


<# ---------- Or just the pieces you need ---------- #>

<#
    The full export is slow on a big instance. -Exclude trims it, and often you
    only want one thing anyway.
#>

    # Export-DbaInstance -SqlInstance $Targets @Lab -Path $ExportRoot -Exclude Databases, ExtendedEvents

    # Logins only, with passwords preserved as hashes so they restore identically
    Export-DbaLogin -SqlInstance $OneTarget @Lab -FilePath (Join-Path $ExportRoot 'logins.sql')

    # Agent jobs only
    Get-DbaAgentJob -SqlInstance $OneTarget @Lab |
        Export-DbaScript -FilePath (Join-Path $ExportRoot 'agentjobs.sql')


<# ---------- Script out any object at all ---------- #>

<#
    Export-DbaScript takes whatever dbatools object you pipe into it. That means
    "script this out" is the same command whether it is a job, a table, a login
    or a linked server.
#>

    Get-DbaDbTable -SqlInstance $OneTarget -Database Sales @Lab |
        Export-DbaScript -FilePath (Join-Path $ExportRoot 'sales_tables.sql')


<# ---------- The habit worth building ---------- #>

<#
    Schedule this weekly into a folder that is a git repository, and add three
    lines to the end:

        git -C $ExportRoot add -A
        git -C $ExportRoot commit -m "Instance export $(Get-Date -f yyyy-MM-dd)"
        git -C $ExportRoot push

    Now "when did that job change, and to what?" is a question with an answer.
    It costs you about ten minutes to set up once.
#>
