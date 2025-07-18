
$numberofContainers = 3

for($i = 1; $i -le $numberofContainers; $i++) {
    $containerName = "SQL$i"
    $port = 15999 + $i
    $dataPath = "D:\ContainerData\$containerName"

    # Create the data directory if it doesn't exist
    if (-not (Test-Path -Path $dataPath)) {
        New-Item -ItemType Directory -Path $dataPath | Out-Null
    }

    docker run --name $containerName `
        -e "ACCEPT_EULA=Y" `
        -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
        -e MSSQL_PID=Developer `
        -e "MSSQL_AGENT_ENABLED=true" `
        -p "$port`:1433" `
        --mount type=bind,src="$($dataPath)",dst=/var/opt/mssql/data `
        -d mcr.microsoft.com/mssql/server:2022-latest
}

<# Source Code to Create 5 SQL Containers #>
<#
docker run --name SQL1 `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p 1433:1433 `
    --mount type=bind,src=C:\Temp\docker\SQL1,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2022-latest

docker run --name SQL2 `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p 1434:1433 `
    --mount type=bind,src=C:\Temp\docker\SQL2,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2022-latest

docker run --name SQL3 `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p 1435:1433 `
    --mount type=bind,src=C:\Temp\docker\SQL3,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2022-latest

docker run --name SQL4 `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p 1436:1433 `
    --mount type=bind,src=C:\Temp\docker\SQL4,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2019-latest

docker run --name SQL5 `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p 1437:1433 `
    --mount type=bind,src=C:\Temp\docker\SQL5,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2017-latest
    
#>