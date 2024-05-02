NEEDS Adjustment before session

$ClientName = ''
$toaddress = "david.seis@straightpathsql.com"




$ReportName = 'Runbook Report'





Write-Host "Prep: Checking for the required folders and modules..." -ForegroundColor Green
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

if(-not (Get-Module 7Zip4PowerShell -ListAvailable)){
Write-Host "Prep: 7Zip4PowerShell was missing, attempting install..." -ForegroundColor Green
    Install-Module 7Zip4PowerShell -Scope AllUsers -Force
    Import-Module -Name 7Zip4PowerShell
    }
if(-not (Get-Module PSSendGrid -ListAvailable)){
Write-Host "Prep: PSSendGrid was missing, attempting install..." -ForegroundColor Green
    Install-Module PSSendGrid -Scope AllUsers -Force
    Import-Module -Name PSSendGrid
    }

$SecurityPath = "C:\StraightPath\Reports\Security"
    If(!(test-path -PathType container $SecurityPath)) { New-Item -ItemType Directory -Path $SecurityPath | Out-Null }

$RunbooksPath = "C:\StraightPath\Reports\Runbooks"
    If(!(test-path -PathType container $RunbooksPath)) { New-Item -ItemType Directory -Path $RunbooksPath | Out-Null }







#Define an Empty Array to Hold all of the HTML Fragments
$fragments = @()

#Define the HTML style
$head = @"
<style>
body { background-color:#FAFAFA; font-family:Arial;font-size:12pt; }
td, th { border:1px solid black; border-collapse:collapse; }
th { color:white; background-color:black; }
table, tr, td, th { padding: 2px; margin: 0px }
tr:nth-child(odd) {background-color: lightgray}
table { margin-left:50px; }
h3{ margin-left:30px; background-color:#abc8f7;}
h4{ margin-left:40px; background-color:#abc8f7;}
h5{ margin-left:50px; background-color:#abc8f7;}
</style>
<H1 style="color: white; background-color:#8fbaff;">$ReportName</H1>
<H2 style="background-color:#8fbaff;">A Report from Straight Path IT Solutions, LLC.</H2>
"@



Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true

$count= 0 
While($count -le 3) {
$fragments = ''
$comp = $computer[$count]
$inst = $SQLInstance[$count]
$path="C:\StraightPath\Reports\Runbooks\$reportName`_$comp`_$count`_$(get-date -f MM-dd-yyyy).htm"


Write-Progress -Activity 'Compiling Reports' -Status "Computer: $comp | Instance: $inst" -PercentComplete (($count/$computer.count)*100)

$fragments +=  "<H3>Server Information</H3>"

$fragments += "<H5>Server and Instance Name</H5>"
$compname= [PSCustomObject]@{
    ComputerName   = $comp
    InstanceName   = $inst	
}
$fragments += $compname | SELECT-Object * -excludeproperty PSComputerName, RunspaceId, PSShowComputerName | ConvertTo-Html | Out-String

$fragments +=  "<H4>OS Information</H4>"
$fragments += Invoke-Command -ComputerName $comp -ScriptBlock {
    Get-ComputerInfo -Property "pscomputername",WindowsProductName, WindowsCurrentVersion, "OsVersion","CsManufacturer","CSModel" | SELECT-Object * -excludeproperty RunspaceId, PSShowComputerName |  ConvertTo-Html | Out-String
}

$fragments +=  "<H4>Hardware Information</H4>"
$fragments +=  "<H5>CPU Information</H5>"
$fragments += Invoke-Command -ComputerName $comp -ScriptBlock {
    Get-WmiObject -Class Win32_Processor -ComputerName. | Select-Object -Property DeviceID,Name,numberofcores,numberoflogicalprocessors
} | SELECT-Object * -excludeproperty PSComputerName, RunspaceId, PSShowComputerName | ConvertTo-Html | Out-String

$fragments +=  "<H5>Memory in GB</H5>"
$memgb = [PSCustomObject]@{
    ComputerName   = $comp 
    TotalMemoryGB   = (Get-CimInstance Win32_PhysicalMemory -ComputerName $comp | Measure-Object -Property capacity -Sum).sum /1gb
}
$fragments +=  $memgb | Select-Object * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName | ConvertTo-Html | Out-String

$fragments +=  "<H5>Disk Information</H5>"
$fragments +=  Get-DbaDiskSpace -ComputerName $comp | Select-Object Name,Label, Capacity,Free,PercentFree,blockSize,filesystem,type -excludeproperty PSComputerName, RunspaceId, PSShowComputerName |  ConvertTo-Html | Out-String
   
$fragments +=  "<H5>PowerPlan Information</H5>"
$fragments +=  Get-DbaPowerPlan -ComputerName $comp | Select-Object computername,powerplan -excludeproperty PSComputerName, RunspaceId, PSShowComputerName |  ConvertTo-Html | Out-String
   
$fragments +=  "<H5>Cluster Information</H5>"
$fragments += Get-DbaWsfcResource  -ComputerName $servername | Select-Object -Property clustername,type,state,name -excludeproperty PSComputerName, RunspaceId, PSShowComputerName |  ConvertTo-Html | Out-String
$fragments += Get-DbaWsfcNetwork -ComputerName $servername | Select-Object -Property clustername, name, address, addressmask -excludeproperty PSComputerName, RunspaceId, PSShowComputerName  |  ConvertTo-Html | Out-String





$fragments +=  "<H3>Instance Information</H3>"
$fragments +=  "<H4>Network configuration</H4>"

$fragments +=  Get-DbaNetworkConfiguration -SqlInstance $inst | Select-Object SQLinstance,sharedmemoryenabled,namedpipesenabled,tcpipenabled,tcpipproperties -excludeproperty PSComputerName, RunspaceId, PSShowComputerName,certificate,advanced  | ConvertTo-Html | Out-String
$fragments +=  Get-DbaAgHadr -SqlInstance $inst  | Select-Object SqlInstance,isazure, netport  | ConvertTo-Html | Out-String
#$fragments +=  Get-NetIPAddress -AddressFamily IPv4 |Where-Object {$_.InterfaceAlias -inotlike "*loopback*"} | SELECT-object -property ifindex,Ipaddress -excludeproperty PSComputerName, RunspaceId, PSShowComputerName  | ConvertTo-Html | Out-String

$fragments +=  Invoke-DbaQuery -SqlInstance $inst -Query "
SELECT  
   CONNECTIONPROPERTY('net_transport') AS net_transport,
   CONNECTIONPROPERTY('protocol_type') AS protocol_type,
   CONNECTIONPROPERTY('auth_scheme') AS auth_scheme,
   CONNECTIONPROPERTY('local_net_address') AS local_net_address,
   CONNECTIONPROPERTY('local_tcp_port') AS local_tcp_port,
   CONNECTIONPROPERTY('client_net_address') AS client_net_address 
   " | Select-Object * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName,RowError, RowState, Table, ItemArray, HasErrors  | ConvertTo-Html | Out-String


$fragments +=  "<H4>Instance Overview</H4>"

$instov = [PSCustomObject]@{
    ComputerName   = $comp 
    Version = Get-DbaProductKey -ComputerName $comp | Select-Object Version -ExpandProperty version
    Edition = Get-DbaProductKey -ComputerName $comp | Select-Object Edition -ExpandProperty Edition
    Key = Get-DbaProductKey -ComputerName $comp | Select-Object Key -ExpandProperty Key
    Build = Invoke-DbaQuery -SqlInstance $inst -Query "SELECT SERVERPROPERTY('ProductVersion') as [ds]" | Select-Object ds -ExpandProperty ds
    UpdateLevel = Invoke-DbaQuery -SqlInstance $inst -Query "SELECT SERVERPROPERTY('ProductUpdateLevel') AS [ds]" | Select-Object ds -ExpandProperty ds
    Collation = Get-DbaInstanceProperty -SqlInstance $servername | Where-Object { $_.name -eq "Collation" } | Select-Object -Property value -ExpandProperty value
    CaseSensitive = Get-DbaAgHadr -SqlInstance $inst  | Select-Object IsCaseSensitive -ExpandProperty iscasesensitive
    VMType = Invoke-DbaQuery -SqlInstance $inst -Query "Select virtual_machine_type_desc as [ds] FROM sys.dm_os_sys_info" | Select-Object ds -ExpandProperty ds
}

$fragments +=  $instov| ConvertTo-Html | Out-String

$fragments += Invoke-DbaQuery -SqlInstance $inst -Query "
	SELECT @@SERVERNAME as [Server Name]
	,	servicename AS [Service name]
	,	startup_type_desc AS [Startup Type]
	,	Status_Desc AS [Status]
	,	service_account AS [Service Account] 
	FROM sys.dm_server_services
" | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors, PSComputerName, RunspaceId, PSShowComputerName  | ConvertTo-Html | Out-String



$fragments +=  "<H4>Installed Features</H4>"
$fragments +=  Get-DbaFeature -ComputerName $comp |  Select-Object * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName  | ConvertTo-Html | Out-String


$fragments +=  "<H4>Databases</H4>"
$fragments += Invoke-DbaQuery -SqlInstance $inst -Query "
	select Name,state,database_id,SUSER_SName(owner_sid)as [owner],recovery_model_desc,compatibility_level,collation_name from sys.databases where database_id >4
" |  Select-Object * -excludeproperty RowError, RowState, Table, ItemArray, HasErrors, PSComputerName, RunspaceId, PSShowComputerName  | ConvertTo-Html | Out-String



ConvertTo-HTML -Head $head -Body $fragments -PostContent "<br><br><i>report generated: $(Get-Date)</i>" | Out-File -FilePath $path -Encoding ascii

$count ++
$fragments = ''
}

Set-location -path "C:\Straightpath\reports"
Write-Host "Zipping Reports..." -ForegroundColor Green
$compress = @{
Path = "C:\StraightPath\Reports\Runbooks\"
ArchiveFileName = "$ClientName`_Runbooks_$(get-date -f MM-yyyy).zip"
}
Compress-7Zip @compress


Write-Host "Sending email..." -ForegroundColor Green
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Parameters = @{
    FromAddress     = ""
    ToAddress       = $toaddress
    Subject         = "Runbooks for $ClientName attached!"
    Body            = "Please find your reports for $ClientName, sent by $DataCollector, attached!"
    Token           = Unprotect-CmsMessage -Path $SecurityPath\Sendgrid.txt
    FromName        = ""
    ToName          = "David"
    AttachmentPath  = "C:\Straightpath\reports\$ClientName`_Runbooks_$(get-date -f MM-yyyy).zip"
}
Send-PSSendGridMail @Parameters



Write-Host "Deleting Local Files..." -ForegroundColor Green
#Remove-Item "C:\straightpath\Reports\Runbooks\*.htm"
#Remove-Item "C:\Temp\$ClientName`_Reports_$(get-date -f MM-yyyy).zip"

Write-Host "Complete!" -ForegroundColor Green



