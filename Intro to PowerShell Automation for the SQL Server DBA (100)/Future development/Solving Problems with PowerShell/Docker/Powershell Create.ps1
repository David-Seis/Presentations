Clear-host


docker run --name SQL1 -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" -e "MSSQL_MEMORY_LIMIT_MB=2048" -e MSSQL_PID=Enterprise -e "MSSQL_AGENT_ENABLED=true" -p 1433:1433 -d mcr.microsoft.com/mssql/server:2022-latest
docker run --name SQL2 -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" -e "MSSQL_MEMORY_LIMIT_MB=2048" -e MSSQL_PID=Enterprise -e "MSSQL_AGENT_ENABLED=true" -p 1434:1433 -d mcr.microsoft.com/mssql/server:2019-latest
docker run --name SQL3 -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Str0ngP@sSw0rd !" -e "MSSQL_MEMORY_LIMIT_MB=2048" -e MSSQL_PID=Enterprise -e "MSSQL_AGENT_ENABLED=true" -p 1435:1433 -d mcr.microsoft.com/mssql/server:2016-latest

docker ps -a | Out-GridView
<#
docker rm SQL1
docker rm SQL2
docker rm SQL3
#>
<#
docker start SQL1
docker start SQL2
docker start SQL3

docker stop SQL1
docker stop SQL2
docker stop SQL3

#>

<#
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Adm1n@HoM" -p 1433:1433 -d mcr.microsoft.com/mssql/server:2019-latest
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Adm1n@HoM" -p 1433:1433 -d mcr.microsoft.com/mssql/server:2017-latest
#>


$Securecred = Read-Host -AsSecureString
New-LocalUser "Test_service" -Password $Securecred -FullName "Test Account for services" -Description "Used only for testing purposes"
Add-LocalGroupMember -Group "Administrators" -Member "Test_service"

remove-localuser -name "Test_service"

