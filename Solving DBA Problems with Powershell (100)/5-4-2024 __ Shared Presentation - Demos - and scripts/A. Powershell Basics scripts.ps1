<# Basic commands ... are Like stored procedures....#>
Get-ComputerInfo

Clear-Host

Get-Service

Get-InstalledModule

Get-Command


<# Using arguments ... just like stored procedures.... #>
Clear-Host

Get-ComputerInfo -Property "*windows*"

Get-computerinfo -Property "*windows*","*OS*"

Get-ComputerInfo -Property "CsName","OsName","OsLastBootUpTime", "OsVersion", "BiosSMBIOSBIOSVersion", "CsDomainRole"



<# Variables ... far easier to use, and more dynamic, than in SQL Server, and they persist for the entire session #>
Clear-Host

Get-Content -Path "C:\Users\Administrator\Desktop\sqllist.txt"
Get-Content -Path "C:\Users\Administrator\Desktop\complist.txt"

$SQLList = Get-Content -Path "C:\Users\Administrator\Desktop\sqllist.txt"
$ComputerList = Get-Content -Path "C:\Users\Administrator\Desktop\complist.txt"

$SQLList

$ComputerList

Invoke-Command -ComputerName $ComputerList -ScriptBlock {
Get-ComputerInfo -Property "CsName","OsName","OsLastBootUpTime", "OsVersion", "BiosSMBIOSBIOSVersion", "CsDomainRole"
}



<# Piping ... or chaining work on the same data/ variable/ object#>

Invoke-Command -ComputerName $ComputerList -ScriptBlock {
Get-ComputerInfo -Property "CsName","OsName","OsLastBootUpTime", "OsVersion", "BiosSMBIOSBIOSVersion", "CsDomainRole"
} | Format-Table -AutoSize

Clear-Host

Invoke-Command -ComputerName $ComputerList -ScriptBlock {
Get-ComputerInfo -Property "CsName","OsName","OsLastBootUpTime", "OsVersion", "BiosSMBIOSBIOSVersion", "CsDomainRole"
} | Select-object * -excludeproperty PSComputername,RunspaceId | Format-Table -AutoSize

Clear-Host

Get-service -Name "*SQL*" 

Get-service -Name "*SQL*" | Where-Object {$_.Status -eq "running"}

Invoke-Command -ComputerName $ComputerList -ScriptBlock {
Get-service -Name "*SQL*" | Where-Object {$_.Status -eq "running"}
}  | Format-Table -AutoSize




<# Modules ... bundles of new stored procedures that others have created for your use, including one of the greatest collections for DBAs around...#>
Clear-Host

Get-installedmodule

Install-Module dbatools
Import-Module dbatools

<# https://dbatools.io/commands #>

<# The swiss army knife, invoke-dbaquery, Why? Any query, any number of instances. #>

