Set-Location -Path "C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Container SQL Environment"


    $containerName = "SQL1-25-1"
    $dataPath = ".\$containerName"
    if (-not (Test-Path -Path $dataPath)) { New-Item -ItemType Directory -Path $dataPath | Out-Null }
        docker run --name $containerName `
            -e "ACCEPT_EULA=Y" `
            -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
            -e MSSQL_PID=Developer `
            -e "MSSQL_AGENT_ENABLED=true" `
            -p "16000:1433" `
            --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL1-25-1,dst=/var/opt/mssql/data `
            -d mcr.microsoft.com/mssql/server:2025-latest

    $containerName = "SQL2-25-2"
    $dataPath = ".\$containerName"
    if (-not (Test-Path -Path $dataPath)) { New-Item -ItemType Directory -Path $dataPath | Out-Null }
        docker run --name $containerName `
            -e "ACCEPT_EULA=Y" `
            -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
            -e MSSQL_PID=Developer `
            -e "MSSQL_AGENT_ENABLED=true" `
            -p "16001:1433" `
            --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL2-25-2,dst=/var/opt/mssql/data `
            -d mcr.microsoft.com/mssql/server:2025-latest

    $containerName = "SQL3-25-3"
    $dataPath = ".\$containerName"
    if (-not (Test-Path -Path $dataPath)) { New-Item -ItemType Directory -Path $dataPath | Out-Null }
        docker run --name $containerName `
            -e "ACCEPT_EULA=Y" `
            -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
            -e MSSQL_PID=Developer `
            -e "MSSQL_AGENT_ENABLED=true" `
            -p "16002:1433" `
            --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL3-25-3,dst=/var/opt/mssql/data `
            -d mcr.microsoft.com/mssql/server:2025-latest

    $containerName = "SQL4-22-1"
    $dataPath = ".\$containerName"
    if (-not (Test-Path -Path $dataPath)) { New-Item -ItemType Directory -Path $dataPath | Out-Null }
        docker run --name $containerName `
            -e "ACCEPT_EULA=Y" `
            -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
            -e MSSQL_PID=Developer `
            -e "MSSQL_AGENT_ENABLED=true" `
            -p "16003:1433" `
            --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL4-22-1,dst=/var/opt/mssql/data `
            -d mcr.microsoft.com/mssql/server:2022-latest

    $containerName = "SQL5-22-2"
    $dataPath = ".\$containerName"
    if (-not (Test-Path -Path $dataPath)) { New-Item -ItemType Directory -Path $dataPath | Out-Null }
        docker run --name $containerName `
            -e "ACCEPT_EULA=Y" `
            -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
            -e MSSQL_PID=Developer `
            -e "MSSQL_AGENT_ENABLED=true" `
            -p "16004:1433" `
            --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL5-22-2,dst=/var/opt/mssql/data `
            -d mcr.microsoft.com/mssql/server:2022-latest

    $containerName = "SQL6-19-1"
    $dataPath = ".\$containerName"
    if (-not (Test-Path -Path $dataPath)) { New-Item -ItemType Directory -Path $dataPath | Out-Null }
        docker run --name $containerName `
            -e "ACCEPT_EULA=Y" `
            -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
            -e MSSQL_PID=Developer `
            -e "MSSQL_AGENT_ENABLED=true" `
            -p "16005:1433" `
            --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL6-19-1,dst=/var/opt/mssql/data `
            -d mcr.microsoft.com/mssql/server:2019-latest     
            
    $containerName = "SQL7-19-2"
    $dataPath = ".\$containerName"
    if (-not (Test-Path -Path $dataPath)) { New-Item -ItemType Directory -Path $dataPath | Out-Null }
        docker run --name $containerName `
            -e "ACCEPT_EULA=Y" `
            -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
            -e MSSQL_PID=Developer `
            -e "MSSQL_AGENT_ENABLED=true" `
            -p "16006:1433" `
            --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL7-19-2,dst=/var/opt/mssql/data `
            -d mcr.microsoft.com/mssql/server:2019-latest

    $containerName = "SQL8-17-1"
    $dataPath = ".\$containerName"
    if (-not (Test-Path -Path $dataPath)) { New-Item -ItemType Directory -Path $dataPath | Out-Null }
        docker run --name $containerName `
            -e "ACCEPT_EULA=Y" `
            -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
            -e MSSQL_PID=Developer `
            -e "MSSQL_AGENT_ENABLED=true" `
            -p "16007:1433" `
            --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL8-17-1,dst=/var/opt/mssql/data `
            -d mcr.microsoft.com/mssql/server:2017-latest
    
    $containerName = "SQL9-17-2"
    $dataPath = ".\$containerName"
    if (-not (Test-Path -Path $dataPath)) { New-Item -ItemType Directory -Path $dataPath | Out-Null }
        docker run --name $containerName `
            -e "ACCEPT_EULA=Y" `
            -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
            -e MSSQL_PID=Developer `
            -e "MSSQL_AGENT_ENABLED=true" `
            -p "16008:1433" `
            --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL9-17-2,dst=/var/opt/mssql/data `
            -d mcr.microsoft.com/mssql/server:2017-latest

    $containerName = "SQL10-17-3"
    $dataPath = ".\$containerName"
    if (-not (Test-Path -Path $dataPath)) { New-Item -ItemType Directory -Path $dataPath | Out-Null }
        docker run --name $containerName `
            -e "ACCEPT_EULA=Y" `
            -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
            -e MSSQL_PID=Developer `
            -e "MSSQL_AGENT_ENABLED=true" `
            -p "16009:1433" `
            --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL10-17-3,dst=/var/opt/mssql/data `
            -d mcr.microsoft.com/mssql/server:2017-latest

    $containerName = "SQL11-17-4"
    $dataPath = ".\$containerName"
    if (-not (Test-Path -Path $dataPath)) { New-Item -ItemType Directory -Path $dataPath | Out-Null }
        docker run --name $containerName `
            -e "ACCEPT_EULA=Y" `
            -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
            -e MSSQL_PID=Developer `
            -e "MSSQL_AGENT_ENABLED=true" `
            -p "16010:1433" `
            --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL11-17-4,dst=/var/opt/mssql/data `
            -d mcr.microsoft.com/mssql/server:2017-latest   
    

        docker run --name $containerName `
            -e "ACCEPT_EULA=Y" `
            -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
            -e MSSQL_PID=Developer `
            -e "MSSQL_AGENT_ENABLED=true" `
            -p "16011:1433" `
            --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL12-17-5,dst=/var/opt/mssql/data `
            -d mcr.microsoft.com/mssql/server:2017-latest 

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