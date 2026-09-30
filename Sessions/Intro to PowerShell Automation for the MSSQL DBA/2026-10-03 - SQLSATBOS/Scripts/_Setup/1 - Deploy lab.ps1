<#
    1 - Deploy lab.ps1  --  builds the four-server demo fleet.

    Run once before the session. 2-4 minutes on a warm image cache.
    Safe to re-run: existing containers are left alone unless you pass -Force.

        .\1 - Deploy lab.ps1            # create anything missing
        .\1 - Deploy lab.ps1 -Force     # tear down and rebuild from scratch

    Requires Docker Desktop (Linux containers) and the dbatools module.
#>

[CmdletBinding()]
param(
    [switch]$Force
)

. "$PSScriptRoot\Environment.ps1"


<# ---------- Preflight ---------- #>

    Write-Host "`nPreflight..." -ForegroundColor Cyan

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "  Docker was not found on PATH. Install Docker Desktop first." -ForegroundColor Red
        return
    }

    docker info --format '{{.ServerVersion}}' 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Docker is installed but not running. Start Docker Desktop and re-run." -ForegroundColor Red
        return
    }

    if (-not (Get-Module -ListAvailable dbatools)) {
        Write-Host "  dbatools not installed. Run: Install-Module dbatools -Scope CurrentUser" -ForegroundColor Red
        return
    }
    Import-Module dbatools

    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-Host "  Created $OutputPath" -ForegroundColor DarkGray
    }

    # Shared backup volume. See the note in Environment.ps1 for why this is a named
    # volume and not a Windows folder. Creating it twice is a no-op.
    docker volume create $LabBackupVolume 2>&1 | Out-Null
    Write-Host "  Backup volume '$LabBackupVolume' ready" -ForegroundColor DarkGray

    Write-Host "  OK" -ForegroundColor Green


<# ---------- Create the containers ---------- #>

    foreach ($srv in $LabServers) {

        $exists = (docker ps -a --filter "name=^$($srv.Name)$" --format '{{.Names}}') -eq $srv.Name

        if ($exists -and $Force) {
            Write-Host "Removing existing $($srv.Name)..." -ForegroundColor Yellow
            docker rm -f $srv.Name | Out-Null
            $exists = $false
        }

        if ($exists) {
            $running = (docker ps --filter "name=^$($srv.Name)$" --format '{{.Names}}') -eq $srv.Name
            if (-not $running) {
                Write-Host "Starting existing $($srv.Name)..." -ForegroundColor Green
                docker start $srv.Name | Out-Null
            } else {
                Write-Host "$($srv.Name) already running, leaving it alone." -ForegroundColor DarkGray
            }
            continue
        }

        Write-Host "Creating $($srv.Name) (SQL $($srv.Version)) on port $($srv.Port)..." -ForegroundColor Green

        # Built as an array rather than backtick continuations: easier to read and edit live.
        $dockerArgs = @(
            'run', '-d'
            '--name',     $srv.Name
            '--hostname', $srv.Name
            '-e', 'ACCEPT_EULA=Y'
            '-e', "MSSQL_SA_PASSWORD=$LabSaPassword"
            '-e', 'MSSQL_PID=Developer'
            '-e', 'MSSQL_AGENT_ENABLED=true'
            '-e', "MSSQL_MEMORY_LIMIT_MB=$LabMemoryMB"
            '-p', "$($srv.Port):1433"
            '-v', "$($LabBackupVolume):$LabContainerBackupPath"
        )

        # See the note in Environment.ps1: lets containers read each other's backups.
        if ($srv.GroupAdd) { $dockerArgs += @('--group-add', $srv.GroupAdd) }

        $dockerArgs += $srv.Image

        docker @dockerArgs | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Failed to create $($srv.Name). Is port $($srv.Port) already in use?" -ForegroundColor Red
        }
    }


<# ---------- Wait for SQL to actually accept connections ---------- #>
<# 'docker run' returns immediately; SQL Server needs another 10-60 seconds. #>

    Write-Host "`nWaiting for SQL Server to come up..." -ForegroundColor Cyan

    $deadline = (Get-Date).AddMinutes(4)
    $pending  = [System.Collections.ArrayList]@($LabServers)

    while ($pending.Count -gt 0 -and (Get-Date) -lt $deadline) {
        foreach ($srv in @($pending)) {
            $instance = "localhost,$($srv.Port)"
            try {
                Invoke-DbaQuery -SqlInstance $instance -SqlCredential $LabCredential -Query 'SELECT 1' -EnableException | Out-Null
                Write-Host "  $($srv.Name) is ready." -ForegroundColor Green
                $pending.Remove($srv)
            } catch {
                # not up yet, keep waiting
            }
        }
        if ($pending.Count -gt 0) { Start-Sleep -Seconds 5 }
    }

    if ($pending.Count -gt 0) {
        Write-Host "  Gave up waiting for: $($pending.Name -join ', ')" -ForegroundColor Red
        Write-Host "  Check 'docker logs <name>' -- usually low memory or a port clash." -ForegroundColor Red
        return
    }


<# ---------- Make the shared volume writable ---------- #>
<#
    A brand-new Docker named volume is owned by root, but SQL Server runs as the
    'mssql' user (uid 10001) and would get 'Operating system error 5(Access is
    denied.)' on every backup. Bind mounts do not hit this because Docker Desktop
    makes them world-writable for you.

    The volume is shared, so fixing it from one container fixes it for all four.
#>

    docker exec -u root $($LabServers[0].Name) chmod 777 $LabContainerBackupPath 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Shared backup volume is writable." -ForegroundColor DarkGray
    } else {
        Write-Host "  Could not set permissions on the backup volume." -ForegroundColor Red
    }


<# ---------- Sample databases ---------- #>
<# Built locally rather than downloaded, so the lab works on conference wifi. #>

    Write-Host "`nCreating sample databases..." -ForegroundColor Cyan

    foreach ($srv in $LabServers) {
        $instance = "localhost,$($srv.Port)"

        foreach ($db in $LabDatabases) {
            Invoke-DbaQuery -SqlInstance $instance -SqlCredential $LabCredential -Query "IF DB_ID('$db') IS NULL CREATE DATABASE [$db];"

            Invoke-DbaQuery -SqlInstance $instance -SqlCredential $LabCredential -Database $db -Query "
                IF OBJECT_ID('dbo.Widget') IS NULL
                BEGIN
                    CREATE TABLE dbo.Widget (
                        WidgetId   INT IDENTITY(1,1) PRIMARY KEY,
                        WidgetName NVARCHAR(100) NOT NULL,
                        Price      DECIMAL(10,2) NOT NULL,
                        CreatedUtc DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
                    );

                    INSERT dbo.Widget (WidgetName, Price)
                    SELECT TOP (2000)
                        CONCAT('Widget-', ROW_NUMBER() OVER (ORDER BY (SELECT NULL))),
                        ABS(CHECKSUM(NEWID())) % 1000 / 10.0
                    FROM sys.all_objects a CROSS JOIN sys.all_objects b;
                END
            "
        }
        Write-Host "  $($srv.Name): $($LabDatabases -join ', ')" -ForegroundColor Green
    }


<# ---------- Seed UNEVEN backup history on purpose ---------- #>
<#
    The Act 2 gap sweep is only interesting if the servers disagree.
    Four identical healthy servers make for a very boring slide, so:

        2017 -> no backups at all   (worst case, shows up bright red)
        2019 -> Sales only          (partial coverage)
        2022 -> everything          (healthy)
        2025 -> everything, but Sales is COPY_ONLY, which reads as a real full
                backup until you look at the LastFullBackupIsCopyOnly column
#>

    Write-Host "`nSeeding backup history (deliberately uneven)..." -ForegroundColor Cyan

    $plan = @{
        'sqlsat2017' = @{ Databases = @();           CopyOnly = @() }
        'sqlsat2019' = @{ Databases = @('Sales');    CopyOnly = @() }
        'sqlsat2022' = @{ Databases = $LabDatabases; CopyOnly = @() }
        'sqlsat2025' = @{ Databases = $LabDatabases; CopyOnly = @('Sales') }
    }

    $seedFailed = $false

    foreach ($srv in $LabServers) {
        $instance = "localhost,$($srv.Port)"
        $spec     = $plan[$srv.Name]
        $done     = @()

        foreach ($db in $spec.Databases) {
            $file     = "$LabContainerBackupPath/$($srv.Name)_$($db)_FULL.bak"
            $withCopy = ''
            if ($db -in $spec.CopyOnly) { $withCopy = ', COPY_ONLY' }

            try {
                Invoke-DbaQuery -SqlInstance $instance -SqlCredential $LabCredential -EnableException -Query "
                    BACKUP DATABASE [$db] TO DISK = N'$file'
                    WITH INIT, CHECKSUM, COMPRESSION$withCopy;
                "
                $done += $db
            } catch {
                $seedFailed = $true
                Write-Host "  $($srv.Name): FAILED backing up $db -- $($_.Exception.Message.Split("`n")[0])" -ForegroundColor Red
            }
        }

        # Report what actually happened, not what was planned.
        $summary = 'no backups (intentional gap)'
        if ($done.Count -gt 0) { $summary = $done -join ', ' }
        Write-Host "  $($srv.Name): $summary" -ForegroundColor Green
    }


<# ---------- Done ---------- #>

<# ---------- Seed integrity-check history, also unevenly ---------- #>
<#
    Act 4 asks "did the maintenance actually run?". That question is only
    interesting if the answer differs per server, so:

        2017, 2019  never checked  -- these are the ones that should worry you
        2022, 2025  checked just now
#>

    Write-Host "`nSeeding integrity check history..." -ForegroundColor Cyan

    foreach ($srv in $LabServers) {
        if ($srv.Version -in '2017', '2019') {
            Write-Host "  $($srv.Name): no CHECKDB (intentional gap)" -ForegroundColor Green
            continue
        }

        foreach ($db in $LabDatabases) {
            Invoke-DbaQuery -SqlInstance "localhost,$($srv.Port)" -SqlCredential $LabCredential -Database $db -Query "
                DBCC CHECKDB([$db]) WITH NO_INFOMSGS, ALL_ERRORMSGS;
            "
        }
        Write-Host "  $($srv.Name): CHECKDB run on $($LabDatabases -join ', ')" -ForegroundColor Green
    }


    if ($seedFailed) {
        Write-Host "`nLab is up, but some seed backups failed (see red lines above)." -ForegroundColor Yellow
        Write-Host "The Act 2 gap sweep and Act 4 backup tests will not behave as designed." -ForegroundColor Yellow
    } else {
        Write-Host "`nLab is up." -ForegroundColor Green
    }

    Write-Host "  Servers : $($Targets -join '  ')" -ForegroundColor Gray
    Write-Host "  Login   : $LabSaUser / $LabSaPassword" -ForegroundColor Gray
    Write-Host "  Backups : volume '$LabBackupVolume' at $LabContainerBackupPath (shared by all containers)" -ForegroundColor Gray
    Write-Host "`nNow run '2 - Test lab.ps1' to verify before you present.`n" -ForegroundColor Cyan
