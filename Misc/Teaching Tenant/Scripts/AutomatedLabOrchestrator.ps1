# This script is used to build and orchestrate automated lab environments for testing purposes, run the tests, and then clean up the environment.

# It is designed to be run in a PowerShell environment with the necessary permissions and modules installed.
# Ensure verbose logging is enabled for detailed output during the execution of the script.
Write-Host "Orchestrator: Start $(get-date -f MM-dd-yyyy), $(get-date -f "HH:mm:ss")" -ForegroundColor DarkCyan
$Totaltime = [system.diagnostics.stopwatch]::startNew()

$VerbosePreference = "Continue"
$InformationPreference = "Continue"

(az account show | convertfrom-Json).tenantdisplayname
If ((az account show | convertfrom-Json).tenantdisplayname -eq "Tampa Bay Data Community Inc") {
    Write-Host "Orchestrator: Tenant is correct, proceeding with the lab deployment..." -ForegroundColor DarkCyan
} else {
    Write-Error "Orchestrator: Tenant is not correct, please run this script in the correct tenant."
    return
}

#step 1 is taking between 10 and 20 minutes to complete as of 4/23/2025
Write-Host "STEP 1: Starting the Lab Deployment..." -ForegroundColor DarkCyan
    $sw = [system.diagnostics.stopwatch]::startNew()

    # Running the lab deploy script
    & "C:\Users\$($Env:username)\Documents\GitHub\Presentations\Teaching Tenant\Scripts\DeployLab.ps1"
  
    $sw.Stop()
Write-Host "STEP 1: Completed - $($sw.Elapsed.Minutes) minutes, $($sw.Elapsed.Seconds) seconds" -ForegroundColor DarkCyan


#step 3 is taking around 5 minutes to complete as of 4/23/2025
Write-Host "STEP 3: Tearing down the Automated Lab environment... $($Totaltime.Elapsed.Minutes) minutes, $($Totaltime.Elapsed.Seconds) seconds" -ForegroundColor DarkCyan
    $sw = [system.diagnostics.stopwatch]::startNew()
    
    # Lab removal script
    & "C:\Users\$($Env:username)\Documents\GitHub\Presentations\Teaching Tenant\Scripts\RemoveLab.ps1"

    $sw.Stop()
Write-Host "STEP 3: Completed - $($sw.Elapsed.Minutes) minutes, $($sw.Elapsed.Seconds) seconds" -ForegroundColor DarkCyan


$Totaltime.Stop()
Write-Host "Orchestrator: Finish - $($Totaltime.Elapsed.Minutes) minutes, $($Totaltime.Elapsed.Seconds) seconds" -ForegroundColor DarkCyan