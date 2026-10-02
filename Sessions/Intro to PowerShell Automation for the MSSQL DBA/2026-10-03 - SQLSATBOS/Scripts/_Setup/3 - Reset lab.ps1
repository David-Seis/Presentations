<#
    3 - Reset lab.ps1  --  put the lab back to its just-deployed state.

    Use this between rehearsals. The demos install Ola's maintenance solution,
    create jobs and alerts, build a DB_Administration database and register a
    scheduled task; this undoes all of that without rebuilding containers, then
    re-seeds the backups so their dates are fresh again -- so a second run-through
    looks like the first.

        .\3 - Reset lab.ps1             # undo what the demos did (~1 min)
        .\3 - Reset lab.ps1 -Destroy    # remove the containers entirely

    What it cannot undo is a CHECKDB on a server that was seeded as never-checked
    (2017, 2019): SQL Server keeps that date inside the database. '2 - Test lab.ps1'
    tells you if that has happened, and '1 - Deploy lab.ps1 -Force' is the cure.

    After -Destroy, run '1 - Deploy lab.ps1' to build the lab again.
#>

[CmdletBinding()]
param(
    [switch]$Destroy
)

. "$PSScriptRoot\Environment.ps1"
Import-Module dbatools


<# ---------- Destroy: remove the containers and stop ---------- #>

    if ($Destroy) {
        Write-Host "`nRemoving containers..." -ForegroundColor Yellow

        foreach ($srv in $LabServers) {
            docker rm -f $srv.Name 2>&1 | Out-Null
            Write-Host "  $($srv.Name) removed" -ForegroundColor Gray
        }

        docker volume rm $LabBackupVolume 2>&1 | Out-Null
        Write-Host "  backup volume '$LabBackupVolume' removed" -ForegroundColor Gray

        Write-Host "`nThe output folder is left in place: $OutputPath" -ForegroundColor Gray
        Write-Host "Delete it by hand if you want the disk space back.`n" -ForegroundColor Gray
        return
    }


<# ---------- Soft reset: undo the demos ---------- #>

    # After a reboot the containers are stopped (they have no restart policy), so
    # start any that are down and wait for SQL before trying to clean them.
    $running = docker ps --format '{{.Names}}' 2>$null
    $stopped = $LabServers | Where-Object { $running -notcontains $_.Name }
    if ($stopped) {
        Write-Host "`nStarting $($stopped.Name -join ', ')..." -ForegroundColor Yellow
        $stopped | ForEach-Object { docker start $_.Name 2>&1 | Out-Null }

        $deadline = (Get-Date).AddMinutes(4)
        foreach ($srv in $stopped) {
            do {
                $up = $true
                try { Invoke-DbaQuery -SqlInstance "localhost,$($srv.Port)" -SqlCredential $LabCredential -Query 'SELECT 1' -EnableException | Out-Null }
                catch { $up = $false; Start-Sleep -Seconds 5 }
            } until ($up -or (Get-Date) -gt $deadline)
        }
    }

    Write-Host "`nResetting demo artifacts on $($LabServers.Count) servers..." -ForegroundColor Cyan

    $RolloutAlerts = @('Error 823', 'Error 824', 'Error 825') + (16..25 | ForEach-Object { "Severity $_ Error" })

    foreach ($srv in $LabServers) {
        $instance = "localhost,$($srv.Port)"

        try {
            # Agent jobs the rollout created. Named _MAINT_* by the rollout script.
            $jobs = Get-DbaAgentJob -SqlInstance $instance -SqlCredential $LabCredential -EnableException |
                        Where-Object Name -Like '_MAINT_*'

            if ($jobs) {
                $jobs | Remove-DbaAgentJob -Confirm:$false | Out-Null
                Write-Host "  $($srv.Name): removed $($jobs.Count) _MAINT_ job(s)" -ForegroundColor Green
            }

            # The admin database Ola and WhoIsActive get installed into.
            $admin = Get-DbaDatabase -SqlInstance $instance -SqlCredential $LabCredential -Database 'DB_Administration' -EnableException
            if ($admin) {
                Remove-DbaDatabase -SqlInstance $instance -SqlCredential $LabCredential -Database 'DB_Administration' -Confirm:$false | Out-Null
                Write-Host "  $($srv.Name): dropped DB_Administration" -ForegroundColor Green
            }

            # The alerts the rollout adds. Left in place, the next rollout fails on
            # "alert already exists" for every one of them.
            $alerts = Get-DbaAgentAlert -SqlInstance $instance -SqlCredential $LabCredential -EnableException |
                          Where-Object Name -In $RolloutAlerts
            if ($alerts) {
                $alerts | Remove-DbaAgentAlert -Confirm:$false | Out-Null
                Write-Host "  $($srv.Name): removed $(@($alerts).Count) alert(s)" -ForegroundColor Green
            }

            # First Responder Kit / WhoIsActive land in master.
            Invoke-DbaQuery -SqlInstance $instance -SqlCredential $LabCredential -Database master -EnableException -Query "
                DROP PROCEDURE IF EXISTS
                    dbo.sp_Blitz, dbo.sp_BlitzFirst, dbo.sp_BlitzIndex, dbo.sp_BlitzCache,
                    dbo.sp_BlitzWho, dbo.sp_BlitzLock, dbo.sp_BlitzBackups, dbo.sp_BlitzAnalysis,
                    dbo.sp_BlitzQueryStore, dbo.sp_AllNightLog, dbo.sp_AllNightLog_Setup,
                    dbo.sp_WhoIsActive, dbo.CommandExecute, dbo.DatabaseBackup,
                    dbo.DatabaseIntegrityCheck, dbo.IndexOptimize;
            "

            # Databases restored by the refresh / backup-testing demos.
            $strays = Get-DbaDatabase -SqlInstance $instance -SqlCredential $LabCredential -ExcludeSystem -EnableException |
                        Where-Object { $_.Name -notin $LabDatabases }

            if ($strays) {
                $strays | Remove-DbaDatabase -Confirm:$false | Out-Null
                Write-Host "  $($srv.Name): dropped $($strays.Count) leftover database(s): $($strays.Name -join ', ')" -ForegroundColor Green
            }

        } catch {
            Write-Host "  $($srv.Name): $($_.Exception.Message.Split("`n")[0])" -ForegroundColor Red
        }
    }


<# ---------- Clear generated output, keep the seeded backups ---------- #>

    if (Test-Path $OutputPath) {
        Get-ChildItem $OutputPath -File | Remove-Item -Force
        Write-Host "  Cleared $OutputPath" -ForegroundColor Green
    }

    # Backups live in a Docker volume, so reach into a container to tidy them. Anything
    # the deploy script seeded is named <container>_<db>_FULL.bak and must survive;
    # everything else was created by a demo and goes.
    $alive = ($LabServers | Where-Object { (docker ps --format '{{.Names}}') -contains $_.Name } | Select-Object -First 1).Name

    if ($alive) {
        $files = docker exec $alive sh -c "ls -1 $LabContainerBackupPath 2>/dev/null"
        $seeded = foreach ($srv in $LabServers) { foreach ($db in $LabDatabases) { "$($srv.Name)_$($db)_FULL.bak" } }
        $extra = @($files | Where-Object { $_ -and $_ -notin $seeded })

        foreach ($f in $extra) {
            docker exec $alive sh -c "rm -f '$LabContainerBackupPath/$f'" 2>&1 | Out-Null
        }
        if ($extra.Count -gt 0) {
            Write-Host "  Removed $($extra.Count) backup file(s) created by the demos" -ForegroundColor Green
        }
    }


<# ---------- The Act 3 scheduled task, and what it wrote ---------- #>

    $task = Get-ScheduledTask -TaskName '_REPORT_*' -ErrorAction SilentlyContinue
    if ($task) {
        $task | Unregister-ScheduledTask -Confirm:$false
        Write-Host "  Unregistered scheduled task(s): $($task.TaskName -join ', ')" -ForegroundColor Green
    }

    $reports = Join-Path $LabRoot 'Reports'
    if (Test-Path $reports) {
        Get-ChildItem $reports -File | Remove-Item -Force
        Write-Host "  Cleared $reports" -ForegroundColor Green
    }


<# ---------- Re-seed, so the backup dates are fresh again ---------- #>
<#
    The deploy script leaves running containers alone and only re-creates what is
    missing, then re-takes the seeded backups. That is exactly a refresh.
#>

    Write-Host "`nRe-seeding..." -ForegroundColor Cyan
    & "$PSScriptRoot\1 - Deploy lab.ps1"
