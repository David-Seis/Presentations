<# Prep Environment Variables for container corrections#>
#Passoword: "Str0ngP@sSw0rd !"


<#
$sqlinstance = @()

$sqlinstance += "0.0.0.0,16005"
$sqlinstance += "SQL2-25-2,16001"
$sqlinstance += "SQL3-25-3,16002"
$sqlinstance += "SQL4-22-1,16003"
$sqlinstance += "SQL5-22-2,16004"
$sqlinstance += "seis-work,16005"
$sqlinstance += "SQL7-19-2,16006"
$sqlinstance += "SQL8-17-1,16007"
$sqlinstance += "SQL9-17-2,16008"
$sqlinstance += "SQL10-17-3,16009"
$sqlinstance += "SQL11-17-4,16010"
$sqlinstance += "SQL12-17-5,16011"

#>
$sqlinstance

$cred = $host.ui.PromptForCredential("SQL Credential", "Please enter the username and password for the SQL Auth account", "sa", "")
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -register  


invoke-dbaquery -sqlinstance $sqlinstance -SQLcredential $cred -query  "

	SELECT @@SERVERNAME AS [Server Name]
	,	SERVERPROPERTY('Edition') AS [SQL Edition]
	,	SERVERPROPERTY('ProductUpdateLevel') AS [Update level]
	,	SERVERPROPERTY('ProductVersion') AS [Build]
	,	@@VERSION AS [Version]
        
" | Format-Table