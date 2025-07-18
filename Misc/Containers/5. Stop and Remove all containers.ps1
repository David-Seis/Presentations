Set-Location -Path "C:\Temp\ContainerData"


$containers = docker ps -a --format "{{.Names}}"



#Partial Teardown - Just containers
foreach ($container in $containers) {
    Docker stop $container | Out-Null
    Docker rm $container | Out-Null

    Write-Host "Removed Container : $container" -ForegroundColor Green
}

#Full Teardown - Containers and directories
foreach ($container in $containers) {
    Docker stop $container | Out-Null
    Docker rm $container | Out-Null

    Get-item -path ".\$container" | Remove-Item -Recurse -Force
    Write-Host "Removed Container and Directory: $container" -ForegroundColor Green
}