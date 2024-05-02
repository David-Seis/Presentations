NEEDS Adjustment before session
#Priming Queries
Get-EventLog -logname 'Application' | where-object source -like "MSSQL*" |Select-Object Source -unique

#REQUIRED VARIABLES
#Event log Application name... Should equal SQL Server application name in event viewer, result from query above!
$source = 'MSSQLSERVER' 

#Name of the server the task is running on. this is used to create the C;\ SQLScripts directory as well.
$Server ='' 

#Directory files will be cleared from. the process uncluded RECURSE, so the root is all that is needed. NOTE: if you do not provide a FILE EXTENSION it will clear ALL FILES older than the retention threshold.
$Directory= "C:\SQLServer\Backup\PRODSQLCLUS*.bak" 
# include *.bak at the end of the root directory to specify only >BAK files, if there are log backups to consider, verify with client no other files will go here and then remove *.bak, this will check ALL files older than the limit provided.

#Retention Threshold
$Threshold = 30 # Value in days to retain, clearing everything older



#Built-In Variables
$limit = (Get-Date).AddDays(-$Threshold)
$path = "$Directory"
$files = Get-ChildItem $path -Recurse
$totalSize = ($files | Measure-Object -Sum Length).Sum  / 1GB
$number = ($files | Where-Object { !$_.PSIsContainer -and $_.lastwritetime -lt $limit } | measure-object).count

#Delete files older than the `$limit.
Get-ChildItem -Path $path -Recurse | Where-Object { !$_.PSIsContainer -and $_.lastwritetime -lt $limit } | Remove-Item -Force -WhatIf

#Record info in the application event log
Write-EventLog -LogName "Application" -Source "$source" -EventID 61916 -EntryType Warning -Message "All items in '$path' before '$limit' have been deleted on $server. $number files at a size of $([math]::Round($totalSize,1)) GB have been cleared."



#Example
$limit = (Get-Date).AddDays(-30)
$path = "E:\LogShipping"

$limit

# Delete files older than the $limit.
Get-ChildItem -Path $path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.lastwritetime -lt $limit } | Remove-Item #-whatif