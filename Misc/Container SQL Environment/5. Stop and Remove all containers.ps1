$containers = Docker container ls | Out-GridView

foreach ($container in $($containers."Container ID")) {
    Docker container stop $container
    Docker container rm $container
}