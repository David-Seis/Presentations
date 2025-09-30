<# Prep Environment Variables for container corrections#>
#Passoword: "Str0ngP@sSw0rd !"


<#
$sqlinstance = @()

$sqlinstance += "Seis-work,16000"
$sqlinstance += "Seis-work,16001"
$sqlinstance += "Seis-work,16002"
$sqlinstance += "Seis-work,16003"
$sqlinstance += "Seis-work,16004"
$sqlinstance += "Seis-work,16005"
$sqlinstance += "Seis-work,16006"
$sqlinstance += "Seis-work,16007"
$sqlinstance += "Seis-work,16008"
$sqlinstance += "Seis-work,16009"
$sqlinstance += "Seis-work,16010"
$sqlinstance += "Seis-work,16011"

#>
$sqlinstance

$cred = $host.ui.PromptForCredential("SQL Credential", "Please enter the username and password for the SQL Auth account", "sa", "")
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -register  


$root = "C:\Users\DavidSeis\Documents\Git\Presentations\Sessions\Build a Custom Monitoring Solution for your SQL Server Environment\2025-07-19 - SQLSATSF\Scripts\"
Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -file "$root\1. Database.sql"
Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -file "$root\2. Table.sql"
Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -file "$root\3. Stored Proc.sql"
Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -file "$root\4. Agent Job.sql"


