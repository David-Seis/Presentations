<#
    ACT 3: FOREVER  --  fan-out multiplies by servers. Scheduling multiplies by time.

    1 - Load data to a database.

    A CSV tells you what is true right now. A table tells you what CHANGED.

    That difference is the whole point of collecting: "Sales is 40 GB" is a fact,
    "Sales grew 12 GB this month" is a decision. You cannot get the second one
    without keeping the first.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


<# ---------- PARAMETERS ---------- #>

    $RepositoryServer = 'localhost,14322'      # where the history lives
    $RepositoryDb     = 'DBA_Repository'
    $TableName        = 'InstanceInventory'


<# ---------- Somewhere to put it ---------- #>

    Invoke-DbaQuery -SqlInstance $RepositoryServer @Lab -Query "
        IF DB_ID('$RepositoryDb') IS NULL CREATE DATABASE [$RepositoryDb];
    "
    Write-Host "Repository ready: $RepositoryDb on $RepositoryServer" -ForegroundColor Green


<# ---------- Collect ---------- #>

    $snapshot = Get-DbaDatabase -SqlInstance $Targets -ExcludeSystem @Lab |
        Select-Object @{ n = 'SqlInstance';   e = { [string]$_.SqlInstance } },
                      @{ n = 'DatabaseName';  e = { $_.Name } },
                      @{ n = 'RecoveryModel'; e = { [string]$_.RecoveryModel } },
                      @{ n = 'SizeMB';        e = { [decimal][math]::Round($_.SizeMB, 2) } },
                      @{ n = 'Owner';         e = { [string]$_.Owner } },
                      # dbatools returns 1/1/0001 rather than null when a database has
                      # never been backed up. Normalise it so the report reads cleanly.
                      @{ n = 'LastFullBackup'; e = { if ($_.LastFullBackup -gt [datetime]'1900-01-01') { $_.LastFullBackup } } },
                      @{ n = 'CollectedUtc';  e = { (Get-Date).ToUniversalTime() } }

    $snapshot | Format-Table -AutoSize


<# ---------- Write it straight into SQL ---------- #>

<#
    Two routes, and it is worth knowing both:

      Write-DbaDbTableData  takes OBJECTS from the pipeline. No file involved.
                            This is the one you want for scheduled collection.

      Import-DbaCsv         takes a FILE. Use it when something else produced the
                            CSV, or when the collection and the load happen on
                            different machines.

    -AutoCreateTable builds the table from the object shape on first run. Convenient
    for a demo; in production create the table deliberately so you control the data
    types and can index it.
#>

    $snapshot |
        ConvertTo-DbaDataTable |
        Write-DbaDbTableData -SqlInstance $RepositoryServer @Lab `
                             -Database $RepositoryDb -Table $TableName -AutoCreateTable

    Write-Host "Loaded $($snapshot.Count) rows into $RepositoryDb.dbo.$TableName" -ForegroundColor Green


<# ---------- The file route, for comparison ---------- #>

    $csv = Join-Path $OutputPath "inventory_$(Get-Date -f 'yyyy-MM-dd_HHmm').csv"
    $snapshot | Export-Csv -Path $csv -NoTypeInformation

    Import-DbaCsv -Path $csv -SqlInstance $RepositoryServer @Lab `
                  -Database $RepositoryDb -Table "${TableName}_FromCsv" -AutoCreateTable


<# ---------- Now ask it something you could not ask a CSV ---------- #>

    # What is in there?
    Invoke-DbaQuery -SqlInstance $RepositoryServer @Lab -Database $RepositoryDb -Query "
        SELECT SqlInstance, DatabaseName, RecoveryModel, SizeMB, LastFullBackup, CollectedUtc
        FROM   dbo.$TableName
        ORDER  BY SqlInstance, DatabaseName;
    " | Out-GridView -Title 'Collected inventory'

    # Run this script again tomorrow and this becomes the useful query:
    Invoke-DbaQuery -SqlInstance $RepositoryServer @Lab -Database $RepositoryDb -Query "
        WITH ranked AS (
            SELECT  SqlInstance, DatabaseName, SizeMB, CollectedUtc,
                    rn = ROW_NUMBER() OVER (PARTITION BY SqlInstance, DatabaseName ORDER BY CollectedUtc DESC)
            FROM    dbo.$TableName
        )
        SELECT  n.SqlInstance,
                n.DatabaseName,
                NowMB      = n.SizeMB,
                BeforeMB   = p.SizeMB,
                GrowthMB   = n.SizeMB - p.SizeMB
        FROM    ranked n
        JOIN    ranked p ON p.SqlInstance = n.SqlInstance
                        AND p.DatabaseName = n.DatabaseName
                        AND p.rn = 2
        WHERE   n.rn = 1
        ORDER BY GrowthMB DESC;
    " | Format-Table -AutoSize

<#
    That query answers "what grew, and by how much" -- the question that lets you
    order storage before you run out, instead of after.

    It only works because something ran yesterday. Which is Act 3, part 2.
#>
