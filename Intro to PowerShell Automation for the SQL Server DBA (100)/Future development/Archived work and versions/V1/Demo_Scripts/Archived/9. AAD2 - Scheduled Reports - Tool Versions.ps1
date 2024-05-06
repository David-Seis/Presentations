$OutputPath = "C:\StraightPath\Reports"
$OutputFile = 'Example_ManagementServer_'+$(get-date -f MM-dd-yy)
            
$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateupdateSearcher()
$Updates = @($UpdateSearcher.Search("IsHidden=0 and IsInstalled=0").Updates)
    
$ManagementServer = [PSCustomObject]@{
    Servername = $env:computername
    SSMSVersion = Get-WmiObject -Class Win32_Product | Where-Object name -like "SQL Server Management Studio" | Sort-Object | Select-Object Version -Last 1
    DBAToolsVersion = get-installedmodule -name dbatools | Sort-Object | Select-Object Version -Last 1
    WindowsOSVersion = [Environment]::OSVersion | Select-Object Version
    MostRecentHotfix = Get-Hotfix | Sort-Object | Select-Object hotfixid -last 1
    PendingUpdates = $Updates.count
    CollectionDate = $(get-date)
}
    
$ManagementServer | Export-Csv -Path "$OutputPath\$OutputFile.csv" -NoTypeInformation
(get-content "$OutputPath\$OutputFile.csv") -replace "@{ProductVersion=","" -replace "@{Version=","" -replace "}","" -replace "@{hotfixid=","" | Out-File "$OutputPath\$OutputFile.csv" -Force
    
    