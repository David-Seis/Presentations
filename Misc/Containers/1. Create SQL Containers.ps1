docker run --name "SQL1-25-1" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16000:1433" `
    --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL1-25-1,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2025-latest

docker run --name "SQL2-25-2" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16001:1433" `
    --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL2-25-2,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2025-latest

docker run --name "SQL3-25-3" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16002:1433" `
    --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL3-25-3,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2025-latest

docker run --name "SQL4-22-1" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16003:1433" `
    --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL4-22-1,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2022-latest

docker run --name "SQL5-22-2" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16004:1433" `
    --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL5-22-2,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2022-latest

docker run --name "SQL6-19-1" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16005:1433" `
    --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL6-19-1,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2019-latest         

docker run --name "SQL7-19-2" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16006:1433" `
    --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL7-19-2,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2019-latest

docker run --name "SQL8-17-1" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16007:1433" `
    --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL8-17-1,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2017-latest

docker run --name "SQL9-17-2" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16008:1433" `
    --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL9-17-2,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2017-latest

docker run --name "SQL10-17-3" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16009:1433" `
    --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL10-17-3,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2017-latest

docker run --name "SQL11-17-4" `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" `
    -e MSSQL_PID=Developer `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p "16010:1433" `
    --mount type=bind,src=C:\Users\DavidSeis\Documents\Git\Presentations\Misc\Containers\SQL11-17-4,dst=/var/opt/mssql/data `
    -d mcr.microsoft.com/mssql/server:2017-latest   

docker run --name "SQL12-17-5" `
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