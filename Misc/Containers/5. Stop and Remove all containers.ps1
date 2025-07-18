$containers = docker ps -a --format "{{.Names}}"

foreach ($container in $containers) {
    Docker stop $container | Out-Null
    Docker rm $container  

    Get-item -path ".\$container" | Remove-Item
}

