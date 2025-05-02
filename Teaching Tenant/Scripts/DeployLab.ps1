# This script deploys resources using Azure CLI in parallel for multiple JSON templates
# It assumes that the JSON templates are located in a specific directory and that each template has a corresponding parameters file.
# Ensure you have the Azure CLI installed and are logged in to your Azure account before running this script in powershell 7

#stopwatch to measure the time taken for the operations
$sw = [system.diagnostics.stopwatch]::startNew()
# Query and store the JSON files in the specified directory, excluding any files that contain "parameters" in their name as these are assumed to be present in the same directory as the template files and named with the pattern "<filename>.parameters.json".

Write-information -Message "INFORMATIONAL: verifying that none of the lab resources are currently running..."
	$DeployedResources = az resource list --tag "TeachingResources" | ConvertFrom-Json 
	IF ($null -eq $DeployedResources -or $DeployedResources.Count -eq 0) {
		Write-Information -Message "INFORMATIONAL: No resources were found with the tag 'Automatedlab'. Proceeding with deployment."
	} else {
		Write-Warning -Message "WARNING: Found $($DeployedResources.Count) resources tagged with 'Automatedlab'. Please ensure all resources are deallocated and deleted before proceeding."
		return
	}

write-information -message "checking for the required resource group 'TeachingResources'..."
	If (-not (az group exists --name "TeachingResources")) {
		Write-Information -Message "INFORMATIONAL: Resource group 'TeachingResources' does not exist. Creating it now..."
	} else {
		Write-Information -Message "INFORMATIONAL: Resource group 'TeachingResources' already exists. Proceeding with deployment."
	}
az group create --name TeachingResources --location eastus --tags TeachingResources = "true"

Write-Information -Message "INFORMATIONAL: Retrieving JSON files from the specified directory..." 
$filedir = Get-ChildItem -Path "C:\Users\$($Env:username)\Documents\GitHub\Presentations\Teaching Tenant\JSON Store" | Where-Object { $_.Name -notlike "*.parameters*" }

#process each JSON file in parallel using the Azure CLI command to deploy resources
Write-Information -Message "INFORMATIONAL: Starting deployment of resources..." 
$filedir | ForEach-Object -throttlelimit 10 -parallel {
	Write-Verbose -Message "Processing file: $($_.Name) and $($($_.Name -replace '.JSON', '') + ".parameters.json")" -Verbose
	# Run the deployment scripts using the Azure CLI command
	az deployment group create -g "TestingTenant" -f $_.FullName -p $($_.FullName -replace $($_.Name), $($($_.Name -replace '.JSON', '') + ".parameters.json")) | Out-Null
}

Write-Information -Message "INFORMATIONAL: Get successful deployments..." 
$DeployedResources = az resource list --tag "Automatedlab" | ConvertFrom-Json 
	IF($null -eq $DeployedResources -or $DeployedResources.Count -eq 0) {
		Write-Error -Message "No resources were deployed. Please check the deployment scripts and parameters."
		return
	} elseif ($DeployedResources.Count -eq 42) {
		Write-Information -Message "INFORMATIONAL: Successfully deployed the expected $($DeployedResources.Count)/42 resources."
		$DeployedResrouces | Group-Object -property type | Select-Object -Property Name, Count | ForEach-Object {
			Write-Verbose -Message "Resource Type: $($_.Name), Count: $($_.Count)" -Verbose
		}
	} else {
		Write-Warning -Message "WARNING: Deployed $($DeployedResources.Count) resources, which is not the expected count of 42. Please verify the deployment."
		$DeployedResrouces | Group-Object -property type | Select-Object -Property Name, Count | ForEach-Object {
			Write-Verbose -Message "Resource Type: $($_.Name), Count: $($_.Count)" -Verbose
		}
	}

# Stop the stopwatch
$sw.Stop()
# Output the total time taken for the deployment
Write-Information -Message "INFORMATIONAL: Deployment completed. Total time taken to deploy resources: $($sw.Elapsed.Minutes) minutes, $($sw.Elapsed.Seconds) seconds"
