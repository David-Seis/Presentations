<# Prep Environment Variables for container corrections#>
#Passoword: "Str0ngP@sSw0rd !"

Docker-

$SQLInstance =  "Seis-Work,1433", "Seis-Work,1434", "Seis-Work,1435", "Seis-Work,1436", "Seis-Work,1437"
$cred = $host.ui.PromptForCredential("SQL Credential", "Please enter the username and password for the SQL Auth account", "sa", "")