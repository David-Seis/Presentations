<#Cmdlets / Commands#>
clear-host

Write-host "Hello World!"

Write-host "Hello World!" -ForegroundColor Red -BackgroundColor White


get-computerinfo | Select-Object -Property csname, windowsproductname

Invoke-Command -ComputerName labsql1,labsql2,labsql3 -ScriptBlock {
    get-computerinfo | Select-Object -Property csname, windowsproductname
    } | Select-Object csname,windowsproductname | Format-Table











<#Variables#>
Clear-host
$Variable = "hello"
$Var = "world"
$V = "!"

$Variable 
$Var 
$V 

Write-host "$variable $var$v"

$list = "LabSQL1", "LabSQL2", "LabSQL3"
$list

$computer = get-computerinfo
$computer.OsName

$sqllist = Get-Content -Path "C:\Users\Administrator\Desktop\sqllist.txt"

$sqllist









<#Objects#>
Clear-host

$computer = get-computerinfo

$computer | Get-Member -MemberType Method

$computer.GetType()


$computer | Select-Object -Property Windows*




<#Modules#>
Clear-Host

Get-InstalledModule

Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true
Invoke-DbaQuery -SqlInstance labsql1,labsql2,labsql3 -query "
SELECT @@SERVERNAME as [Instance], SERVERPROPERTY('Edition') as [Edition]"

Install-Module dbatools -SkipPublisherCheck

Get-InstalledModule

Import-Module dbatools

Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true
Invoke-DbaQuery -SqlInstance labsql1,labsql2,labsql3 -query "
SELECT @@SERVERNAME as [Instance], SERVERPROPERTY('Edition') as [Edition]" | Format-table


clear-host

uninstall-module dbatools
