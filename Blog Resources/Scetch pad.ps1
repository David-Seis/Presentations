$sw = [system.diagnostics.stopwatch]::startNew()

$SPLAT = @{
	Sqlinstance         = 'Labsql1'
	Database            = 'DB_admin'
	BackupLocation      = '\\LabShare\SQLBackups'
	Cleanuptime         = 336
	Logtotable          = $True
	Installjobs 	    = $True
    AutoScheduleJobs    = $True
#    SqlCredential       = $credential
    Replaceexisting     = $true
}

Install-DbaMaintenanceSolution @splat

$sw.stop()
"Ola Rollout completed - $($sw.Elapsed.Minutes) minutes, $($sw.Elapsed.Seconds) seconds."