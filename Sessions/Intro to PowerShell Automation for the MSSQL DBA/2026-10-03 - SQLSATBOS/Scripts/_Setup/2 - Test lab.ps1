<#
    2 - Test lab.ps1  --  pre-flight harness.

    Run this on any machine before presenting (or before following along at home).
    It checks every dependency the demos rely on and tells you exactly what is
    broken, rather than letting you find out live in front of a room.

        .\2 - Test lab.ps1

    Nothing here changes state except one temporary backup file, which is removed.
#>

[CmdletBinding()]
param()

. "$PSScriptRoot\Environment.ps1"

$results = [System.Collections.Generic.List[object]]::new()

function Add-Check {
    param(
        [string]$Area,
        [string]$Check,
        [ValidateSet('PASS', 'FAIL', 'WARN')][string]$Status,
        [string]$Detail = ''
    )
    $results.Add([pscustomobject]@{ Area = $Area; Check = $Check; Status = $Status; Detail = $Detail })
}

Write-Host "`nChecking the lab..." -ForegroundColor Cyan


<# ---------- 1. Host prerequisites ---------- #>

    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Add-Check 'Host' 'Docker installed' 'PASS'

        $serverVersion = docker info --format '{{.ServerVersion}}' 2>&1
        if ($LASTEXITCODE -eq 0) {
            Add-Check 'Host' 'Docker running' 'PASS' "engine $serverVersion"

            $osArch = docker version --format '{{.Server.Os}}/{{.Server.Arch}}' 2>&1
            if ($osArch -like 'linux/*') {
                Add-Check 'Host' 'Linux containers' 'PASS' $osArch
                if ($osArch -like '*arm64*') {
                    Add-Check 'Host' 'CPU architecture' 'WARN' 'arm64: mssql images are amd64 and will run under emulation (slow)'
                }
            } else {
                Add-Check 'Host' 'Linux containers' 'FAIL' "engine reports $osArch -- switch Docker Desktop to Linux containers"
            }
        } else {
            Add-Check 'Host' 'Docker running' 'FAIL' 'Docker Desktop is installed but not started'
        }
    } else {
        Add-Check 'Host' 'Docker installed' 'FAIL' 'docker not found on PATH'
    }

    $ramGB = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    $needGB = ($LabServers.Count * $LabMemoryMB / 1024) + 2
    if ($ramGB -ge $needGB) {
        Add-Check 'Host' 'Memory' 'PASS' ("{0:n0} GB present, ~{1:n0} GB needed" -f $ramGB, $needGB)
    } else {
        Add-Check 'Host' 'Memory' 'WARN' ("{0:n0} GB present, ~{1:n0} GB needed -- lower `$LabMemoryMB in Environment.ps1" -f $ramGB, $needGB)
    }

    $dbatools = Get-Module -ListAvailable dbatools | Sort-Object Version -Descending | Select-Object -First 1
    if ($dbatools) {
        Add-Check 'Host' 'dbatools module' 'PASS' "v$($dbatools.Version)"
        Import-Module dbatools
    } else {
        Add-Check 'Host' 'dbatools module' 'FAIL' 'Install-Module dbatools -Scope CurrentUser'
    }


<# ---------- 2. Images ---------- #>

    $localImages = docker images --format '{{.Repository}}:{{.Tag}}' 2>$null
    foreach ($srv in $LabServers) {
        if ($localImages -contains $srv.Image) {
            Add-Check 'Images' "SQL $($srv.Version)" 'PASS' 'cached locally'
        } else {
            Add-Check 'Images' "SQL $($srv.Version)" 'WARN' "not cached -- first run downloads ~2 GB (do this BEFORE the venue wifi)"
        }
    }


<# ---------- 3. Containers ---------- #>

    $running = docker ps --format '{{.Names}}' 2>$null
    foreach ($srv in $LabServers) {
        if ($running -contains $srv.Name) {
            Add-Check 'Containers' $srv.Name 'PASS' "port $($srv.Port)"
        } else {
            Add-Check 'Containers' $srv.Name 'FAIL' "not running -- run '1 - Deploy lab.ps1'"
        }
    }


<# ---------- 4. SQL connectivity, version, Agent, databases ---------- #>

    foreach ($srv in $LabServers) {
        $instance = "localhost,$($srv.Port)"

        try {
            $info = Invoke-DbaQuery -SqlInstance $instance -SqlCredential $LabCredential -EnableException -Query "
                SELECT  ProductVersion = CONVERT(sysname, SERVERPROPERTY('ProductVersion')),
                        Edition        = CONVERT(sysname, SERVERPROPERTY('Edition'))
            "
            Add-Check 'SQL' "$($srv.Name) reachable" 'PASS' "$($info.ProductVersion) / $($info.Edition)"

            # SQL Agent has to be up or the maintenance-rollout demos create jobs that never run.
            try {
                $agent = Invoke-DbaQuery -SqlInstance $instance -SqlCredential $LabCredential -EnableException -Query "
                    SELECT status_desc FROM sys.dm_server_services WHERE servicename LIKE 'SQL Server Agent%'
                "
                if ($agent.status_desc -eq 'Running') {
                    Add-Check 'SQL' "$($srv.Name) Agent" 'PASS' 'running'
                } else {
                    Add-Check 'SQL' "$($srv.Name) Agent" 'FAIL' "state: $($agent.status_desc) -- recreate with MSSQL_AGENT_ENABLED=true"
                }
            } catch {
                Add-Check 'SQL' "$($srv.Name) Agent" 'WARN' 'could not read sys.dm_server_services'
            }

            $dbs = (Get-DbaDatabase -SqlInstance $instance -SqlCredential $LabCredential -Database $LabDatabases).Name
            $missing = $LabDatabases | Where-Object { $_ -notin $dbs }
            if ($missing) {
                Add-Check 'SQL' "$($srv.Name) sample DBs" 'FAIL' "missing: $($missing -join ', ')"
            } else {
                Add-Check 'SQL' "$($srv.Name) sample DBs" 'PASS' ($LabDatabases -join ', ')
            }

        } catch {
            Add-Check 'SQL' "$($srv.Name) reachable" 'FAIL' $_.Exception.Message.Split("`n")[0]
        }
    }


<# ---------- 5. The shared backup folder ---------- #>
<#
    This is the check that matters most and the one people skip.

    Act 4 backs up on one server and restores on another. That only works if all
    four containers see the SAME folder. Here we back up on the OLDEST instance
    and read the header on the NEWEST -- which also proves the version direction
    the demo depends on (you can restore up, never down).
#>

    $volumes = docker volume ls --format '{{.Name}}' 2>$null
    if ($volumes -contains $LabBackupVolume) {
        Add-Check 'Backups' 'Shared volume exists' 'PASS' $LabBackupVolume
    } else {
        Add-Check 'Backups' 'Shared volume exists' 'FAIL' "'$LabBackupVolume' not found -- run '1 - Deploy lab.ps1'"
    }

    # Every version must be able to WRITE to the volume. This is the check that catches
    # the SQL 2025 bind-mount failure, so run it against all four rather than just one.
    #
    # Probing with master + COPY_ONLY on purpose: backing up a demo database here would
    # overwrite the deliberately uneven backup history the deploy script seeded, and the
    # Act 2 gap sweep would then show four healthy servers.
    foreach ($srv in $LabServers) {
        $probeBak = "$LabContainerBackupPath/_probe_$($srv.Name).bak"
        try {
            Invoke-DbaQuery -SqlInstance "localhost,$($srv.Port)" -SqlCredential $LabCredential -EnableException -Query "
                BACKUP DATABASE [master] TO DISK = N'$probeBak' WITH INIT, COPY_ONLY, COMPRESSION;
            "
            Add-Check 'Backups' "$($srv.Name) can write" 'PASS'
        } catch {
            Add-Check 'Backups' "$($srv.Name) can write" 'FAIL' $_.Exception.Message.Split("`n")[0]
        }
    }

    # And the containers must see each other's files. Write on the OLDEST, read on the
    # NEWEST -- which also proves the version direction the demos rely on, since you can
    # restore a backup up a version but never down.
    $oldest = $LabServers[0]
    $newest = $LabServers[-1]

    try {
        $header = Invoke-DbaQuery -SqlInstance "localhost,$($newest.Port)" -SqlCredential $LabCredential -EnableException -Query "
            RESTORE HEADERONLY FROM DISK = N'$LabContainerBackupPath/_probe_$($oldest.Name).bak';
        "
        if ($header) {
            Add-Check 'Backups' 'Containers share the volume' 'PASS' "$($newest.Name) read a backup written by $($oldest.Name)"
        } else {
            Add-Check 'Backups' 'Containers share the volume' 'FAIL' 'header came back empty'
        }
    } catch {
        Add-Check 'Backups' 'Containers share the volume' 'FAIL' $_.Exception.Message.Split("`n")[0]
    }

    # Tidy up the probe files.
    docker exec $($LabServers[0].Name) sh -c "rm -f $LabContainerBackupPath/_probe_*.bak" 2>&1 | Out-Null


<# ---------- Report ---------- #>

    Write-Host ""
    $pad = ($results.Check | Measure-Object -Property Length -Maximum).Maximum

    foreach ($r in $results) {
        $color = switch ($r.Status) {
            'PASS' { 'Green' }
            'WARN' { 'Yellow' }
            'FAIL' { 'Red' }
        }
        $line = "  [{0}]  {1,-10} {2}" -f $r.Status, $r.Area, $r.Check.PadRight($pad)
        if ($r.Detail) { $line += "  $($r.Detail)" }
        Write-Host $line -ForegroundColor $color
    }

    $fails = @($results | Where-Object Status -EQ 'FAIL').Count
    $warns = @($results | Where-Object Status -EQ 'WARN').Count

    Write-Host ""
    if ($fails -gt 0) {
        Write-Host "  $fails check(s) FAILED. Fix these before presenting." -ForegroundColor Red
    } elseif ($warns -gt 0) {
        Write-Host "  All checks passed with $warns warning(s). You are good to present." -ForegroundColor Yellow
    } else {
        Write-Host "  All checks passed. Lab is ready." -ForegroundColor Green
    }
    Write-Host ""
