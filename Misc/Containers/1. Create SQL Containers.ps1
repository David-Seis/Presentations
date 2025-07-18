$sqlinstance = @()

docker run --name "SQL1-25-1" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -p "16000:1433" `
    --hostname SQL1-25-1 `
    -d mcr.microsoft.com/mssql/server:2025-latest

    $sqlinstance += "Seis-Work,16000"

docker run --name "SQL2-25-2" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -p "16001:1433" `
    --hostname SQL2-25-2 `
    -d mcr.microsoft.com/mssql/server:2025-latest

    $sqlinstance += "Seis-Work,16001"

docker run --name "SQL3-25-3" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -p "16002:1433" `
    --hostname SQL3-25-3 `
    -d mcr.microsoft.com/mssql/server:2025-latest

    $sqlinstance += "Seis-Work,16002"

docker run --name "SQL4-22-1" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16003:1433" `
    --hostname SQL4-22-1 `
    --mount type=bind,src=C:\Temp\ContainerData\SQL4-22-1,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2022-latest

    $sqlinstance += "Seis-Work,16003"

docker run --name "SQL5-22-2" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16004:1433" `
    --hostname SQL5-22-2 `
    --mount type=bind,src=C:\Temp\ContainerData\SQL5-22-2,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2022-latest

    $sqlinstance += "Seis-Work,16004"

docker run --name "SQL6-19-1" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16005:1433" `
    --hostname SQL6-19-1 `
    --mount type=bind,src=C:\Temp\ContainerData\SQL6-19-1,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2019-latest
    
    $sqlinstance += "Seis-Work,16005"

docker run --name "SQL7-19-2" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16006:1433" `
    --hostname SQL7-19-2 `
    --mount type=bind,src=C:\Temp\ContainerData\SQL7-19-2,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2019-latest

    $sqlinstance += "Seis-Work,16006"

docker run --name "SQL8-17-1" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16007:1433" `
    --hostname SQL8-17-1 `
    --mount type=bind,src=C:\Temp\ContainerData\SQL8-17-1,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2017-latest
    
    $sqlinstance += "Seis-Work,16007"

docker run --name "SQL9-17-2" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16008:1433" `
    --hostname SQL9-17-2 `
    --mount type=bind,src=C:\Temp\ContainerData\SQL9-17-2,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2017-latest

    $sqlinstance += "Seis-Work,16008"

docker run --name "SQL10-17-3" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16009:1433" `
    --hostname SQL10-17-3 `
    --mount type=bind,src=C:\Temp\ContainerData\SQL10-17-3,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2017-latest

    $sqlinstance += "Seis-Work,16009"

docker run --name "SQL11-17-4" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16010:1433" `
    --hostname SQL11-17-4 `
    --mount type=bind,src=C:\Temp\ContainerData\SQL11-17-4,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2017-latest   

    $sqlinstance += "Seis-Work,16010"

docker run --name "SQL12-17-5" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16011:1433" `
    --hostname SQL12-17-5 `
    --mount type=bind,src=C:\Temp\ContainerData\SQL12-17-5,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2017-latest 

    $sqlinstance += "Seis-Work,16011"

$sqlinstance

