az group create --name TeachingResources --location eastus --tags TeachingResources = "true"

$filedir = Get-ChildItem -Path "C:\Users\$($Env:username)\Documents\GitHub\Presentations\Teaching Tenant\JSON Store" | Where-Object { $_.Name -notlike "*.parameters*" -and $_.Name -notlike "*azureAD*" }
Write-Information -Message "INFORMATIONAL: Starting deployment of resources..." 
$filedir | ForEach-Object -throttlelimit 10 -parallel {
	Write-Verbose -Message "Processing file: $($_.Name) and $($($_.Name -replace '.JSON', '') + ".parameters.json")" -Verbose
	# Run the deployment scripts using the Azure CLI command
	az deployment group create -g "TeachingResources" -f $_.FullName -p $($_.FullName -replace $($_.Name), $($($_.Name -replace '.JSON', '') + ".parameters.json")) | Out-Null
}

$DeployedResources = az resource list --tag "TeachingResources" | ConvertFrom-Json 

$DeployedResources | ForEach-Object -throttlelimit 50 -parallel { 
    Write-Verbose -Message "Deleting resource: $($_.name), type: $($_.type)" -Verbose
        az resource delete --ids $_.id --verbose
}

az group list