Clear-host

$SQLlist = Get-Content -Path "C:\Users\Administrator\Desktop\sqllist.txt"


$head = @"
    <style>
    body { background-color:#FAFAFA; font-family:Arial; font-size:12pt; }
    td, th { border:1px solid black; border-collapse:collapse; }
    th { color:white; background-color:black; }
    table, tr, td, th { padding: 2px; margin: 0px }
    tr:nth-child(odd) {background-color: lightgray}
    table { margin-left:50px; }
    </style>
    <H1>Powershell Basics Report</H1>
    <H2>Automated powershell Report from Straight Path IT Solutions, LLC.</H2>
"@

Clear-Variable -name fragments


$fragments += Invoke-DbaQuery -SQLInstance $sqllist -Query " 
/*~~~ Basic SQL Server Information ~~~*/
SELECT @@SERVERNAME AS [Server Name]
,	SERVERPROPERTY('Edition') AS [SQL Edition]
,	SERVERPROPERTY('ProductUpdateLevel') AS [Update level]
,	SERVERPROPERTY('ProductVersion') AS [Build]
" | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | ConvertTo-Html | Out-String

$fragments += Get-DbaPowerPlan -computername $sqllist  | Select-Object * -ExcludeProperty instanceid, credential | ConvertTo-Html | Out-String


$path="C:\Temp\Powershell_Basics_Report_$(get-date -f MM-dd-yyyy).htm"
ConvertTo-HTML -Head $head -Body $fragments -PostContent "<br><br><i>Report generated: $(Get-Date)</i>" | Out-File -FilePath $path -Encoding ascii