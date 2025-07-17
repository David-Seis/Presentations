<# Arguments for powershell commands are similar to parameters in T-SQL stored procedures #>

Get-ComputerInfo -Property "CsName","OsName","OsLastBootUpTime", "CsDomainRole"

# get the current process information
get-process -Name "pwsh*"

# Run dbaquery command to get the server name and version
Invoke-dbaquery -SqlInstance localhost -Query "SELECT @@SERVERNAME AS ServerName, @@VERSION AS Version"

# Show a different way to run the same command using the -File parameter
Invoke-dbaquery -SqlInstance "Localhost" -File "C:\Users\DavidSeis\Documents\Git\Presentations\Sessions\Intro to PowerShell Automation for the MSSQL DBA\2025-05-20 - TFAB\Scripts\1 - Basic Concepts\basics.sql" 

