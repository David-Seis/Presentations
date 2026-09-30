<#
    3 - Reset lab.ps1  --  put the lab back to its just-deployed state.

    Use this between rehearsals. The demos install Ola's maintenance solution,
    create jobs and build a DB_Administration database; this undoes all of that
    without rebuilding containers, so a second run-through looks like the first.

        .\3 - Reset lab.ps1             # undo what the demos did (fast, ~20s)
        .\3 - Reset lab.ps1 -Destroy    # remove the containers entirely

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

    Write-Host "`nResetting demo artifacts on $($LabServers.Count) servers..." -ForegroundColor Cyan

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

    Write-Host "`nReset complete. Run '2 - Test lab.ps1' to confirm.`n" -ForegroundColor Cyan
