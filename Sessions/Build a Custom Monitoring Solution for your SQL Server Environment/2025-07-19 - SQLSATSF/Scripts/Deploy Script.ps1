
$root = "C:\Users\DavidSeis\Documents\Git\Presentations\Sessions\Build a Custom Monitoring Solution for your SQL Server Environment\2025-07-19 - SQLSATSF\Scripts\"
Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -file "$root\1. Database.sql"
Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -file "$root\2. Table.sql"
Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -file "$root\3. Stored Proc.sql"
Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -file "$root\4. Agent Job.sql"

#Passoword: "Str0ngP@sSw0rd !"
$cred = $host.ui.PromptForCredential("SQL Credential", "Please enter the username and password for the SQL Auth account", "sa", "")
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -register  


Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -query "select * from servermetrics.dbo.perf" |  Export-Csv -Path ".\Export.csv" -Delimiter "," -Force -NoTypeInformation
Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -Query "Truncate table servermetrics.dbo.perf"
Import-DbaCsv -Path "C:\Temp\ContainerData\Export.csv" -SqlInstance "Seis-work" -database 'servermetrics' -table 'perf' -Delimiter ','  -NoProgress | out-null  
  
