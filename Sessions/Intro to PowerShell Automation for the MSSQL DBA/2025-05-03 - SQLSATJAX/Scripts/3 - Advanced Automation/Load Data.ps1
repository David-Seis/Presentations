$SQLInstance =  "Seis-Work"


Import-DbaCsv -Path "C:\Temp\Demo\Home-lab_InstanceTracking.csv"  -SqlInstance $SQLInstance -Database "DB_Administration" -AutoCreateTable


<# Query Loaded data #>
<# Code to show that the tabel is present - Using Invoke-DBAquery from Dbatools #> 

invoke-dbaquery -sqlinstance $SQLInstance -query  "

	SELECT [Machine_Name]
      ,[Instance_Name]
      ,[SQL_Version]
      ,[SQL_Edition]
      ,[Product_Level]
      ,[Update_Level]
      ,[SQL_Build]
      ,[Ola_Version]
      ,[First_Responder_Version]
      ,[SQL_Account]
      ,[SQL_Agent_Account]
      ,[Uptime_Days]
      ,[is_sa_disabled]
      ,[local_net_address]
      ,[local_tcp_port]
      ,[num_error_logs]
      ,[Collection_Date]
  FROM [DB_Administration].[dbo].[Home-lab_InstanceTracking]

        
" | Out-GridView


<# Get Action items#>
<# query to get action items from the data #>

Invoke-DbaQuery -SqlInstance "Seis-Work" -Query "

SELECT 
machine_name
,	Instance_name
,   'Sa is enabled for login - please correct immediately'
FROM [DB_Administration].[dbo].[Home-lab_InstanceTracking]
Where is_sa_disabled = 'False'
" 
<# Environment Cleanup #>
Remove-Item -Path $CSVpath 

If((test-path -PathType container $outputPath)) 
{ 
    remove-Item -Path $outputPath
    Write-Host "$outputPath Directory was removed"
}

Invoke-DbaQuery -SqlInstance "Seis-Work" -Query "
    DROP DATABASE ADMIN
" 

Write-Host "Environment cleaned"