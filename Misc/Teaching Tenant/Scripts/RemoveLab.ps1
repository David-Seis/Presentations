# This script is used to deallocate and delete all Azure resources tagged with "TeachingResources" in the "ProactiveTeam" resource group.
# It uses Azure CLI commands to perform the operations and outputs the status of each operation.

# Ensure you have the Azure CLI installed and are logged in to your Azure account before running this script in powershell 7

# stopwatch to measure the time taken for the operations
$sw = [system.diagnostics.stopwatch]::startNew()

# Retrieve all resources tagged with "TeachingResources" in the "ProactiveTeam" resource group and run a parallel operation to deallocate and delete the virtual machines and sql virtual machines resources first, which will release the disks and allow the deletion of the connection resources not marked for delete with virtual machine.
Write-Information -Message "INFORMATIONAL: Deallocating and deleting virtual machines tagged with 'TeachingResources'..."
    
# Use az resource list to get all resources with the tag "TeachingResources" and filter for virtual machines and SQLvirtual machines
    $DeployedResources = az resource list --tag "TeachingResources" | ConvertFrom-Json 
        IF($null -eq $DeployedResources -or $DeployedResources.Count -eq 0) {
            Write-Error -Message "No resources were found with the tag 'TeachingResources'. Please check the tag and try again."
            return
        } else {
            Write-Information -Message "INFORMATIONAL: Found $($DeployedResources.Count) resources tagged with 'TeachingResources', Starting the delete process."
            #these virtual machines need to be deallocated first before they can be deleted, and they have cascade delete set to true, so all other resources should be deleted as well
            $DeployedResources | where-object {$_.type -like "*VirtualMachine*"} | ForEach-Object -throttlelimit 50 -parallel { 

                Write-Verbose -Message "Deallocating resource: $($_.name), type: $($_.type)" -Verbose
                    az vm deallocate -n $_.name -g "TeachingResources" | Out-Null
                
                Write-Verbose -Message "Deleting resource: $($_.name), type: $($_.type)" -Verbose
                    az resource delete --ids $_.id | Out-Null
            }   
        }

            # Retrieve any remaining resources tagged with "TeachingResources" and run a parallel operation to delete them
            Write-Information -Message "INFORMATIONAL: Checking for any straggler resources tagged with 'TeachingResources'..."
            $DeployedResources = az resource list --tag "TeachingResources" | ConvertFrom-Json 
            IF($null -eq $DeployedResources -or $DeployedResources.Count -eq 0) {
                Write-Information -Message "INFORMATIONAL: No straggler resources found tagged with 'TeachingResources'."
                return
            } else {
                Write-Information -Message "INFORMATIONAL: Found $($DeployedResources.Count) straggler resources tagged with 'TeachingResources', Starting the delete process."
                $DeployedResources | ForEach-Object -throttlelimit 50 -parallel { 
                    Write-Verbose -Message "Deleting resource: $($_.name), type: $($_.type)" -Verbose
                        az resource delete --ids $_.id | Out-Null
                }
            }
        }





# Query the remaining resources to check if any resources are left that were not deleted. If there are no remaining resources, print a success message, otherwise attempt to delete the remaining resources one more time
    $Remainingobjects =  az resource list --tag "TeachingResources" | ConvertFrom-Json 
        IF($null -eq $remainingobjects -or $remainingobjects.Count -eq 0) {
            Write-Information -Message "INFORMATIONAL: All resources have been successfully deleted."
        } else {
            Write-Warning -Message "$($remainingobjects.count) resource(s) were not deleted. Attemmpting one more pass."
                $remainingobjects | ForEach-Object -throttlelimit 50 -parallel { 
                    Write-Verbose -Message "Deleting resource: $($_.name), type: $($_.type)" -Verbose
                    az resource delete --ids $_.id | Out-Null
                }
                #final check for remaining resources
                Write-Verbose -Message "Final check for remaining resources tagged with 'TeachingResources'..." -Verbose
                $remainingobjects =  az resource list --tag "TeachingResources" | ConvertFrom-Json
                IF($null -eq $remainingobjects -or $remainingobjects.Count -eq 0) {
                    Write-Verbose -Message "Remaining resources were successfully deleted on the second pass." -Verbose
                } else {
                    Write-Error -Message "$($remainingobjects.count) resource(s) still could not be deleted. Please investigate."
            }
        }

# Stop the stopwatch
$sw.Stop()

# Output the total time taken for the operations
Write-Information -Message "Total time taken to put an end to the TeachingResources resources:  $($sw.Elapsed.Minutes) minutes, $($sw.Elapsed.Seconds) seconds"

