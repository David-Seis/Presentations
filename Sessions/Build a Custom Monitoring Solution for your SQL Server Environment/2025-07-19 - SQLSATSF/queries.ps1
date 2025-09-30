Invoke-DbaQuery -SqlInstance $sqlinstance  -Query "
DECLARE @num_logs int;
EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'NumErrorLogs',@num_logs OUTPUT;

SELECT    SERVERPROPERTY('MachineName') AS Machine_Name
,   SERVERPROPERTY('ServerName') AS Instance_Name
,   CASE
        WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '17.%' THEN 2025
        WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '16.%' THEN 2022
        WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '15.%' THEN 2019
        WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '14.%' THEN 2017
        WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '13.%' THEN 2016
        WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '12.%' THEN 2014
        WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '11.%' THEN 2012
        WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '10.%' THEN 2008
        WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '9.%'  THEN 2005
    ELSE NULL END AS [SQL_Version]
,   SERVERPROPERTY('Edition')                                                                         AS SQL_Edition
,   SERVERPROPERTY('ProductLevel')                                                                    AS Product_Level
,   SERVERPROPERTY('ProductUpdateLevel')                                                              AS Update_Level
,   SERVERPROPERTY('ProductVersion')                                                                  AS SQL_Build
,   SERVERPROPERTY('Collation')                                                                       AS Instance_Collation
,   (SELECT service_account FROM sys.dm_server_services WHERE servicename like 'SQL Server (%')       AS SQL_Account
,   (SELECT service_account FROM sys.dm_server_services WHERE servicename like 'SQL Server Agent%')   AS SQL_Agent_Account
,   (SELECT datediff(day, sqlserver_start_time, getdate()) FROM sys.dm_os_sys_info)                   AS Uptime_Days
,   (SELECT is_disabled FROM sys.server_principals WHERE sid = 0x01 )                                 AS is_sa_disabled
,   CONNECTIONPROPERTY('local_net_address')                                                           AS local_net_address
,   CONNECTIONPROPERTY('local_tcp_port')                                                              AS local_tcp_port
,   (SELECT COUNT(memory_node_id) From sys.dm_os_memory_nodes where memory_node_id <> 64)             AS NUMA_Nodes
,   GETDATE()                                                                                         AS Collection_Date
" | Export-Csv -Path ".\ServerInfo.csv" -Delimiter "," -Force -NoTypeInformation



Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -Query "
select SERVERPROPERTY('ServerName') AS Instance_Name, * from sys.dm_os_sys_info 
" | Out-GridView


Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -Query "
select SERVERPROPERTY('ServerName') AS Instance_Name, * from sys.dm_os_host_info 
" | Out-GridView

Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -Query "
SELECT counter_name
	,	cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name in ('Processes blocked','Batch Requests/sec')
UNION
SELECT 
	counter_name
	,	SUM(cntr_value) as cntr_value
FROM sys.dm_os_performance_counters 
WHERE counter_name in ('Data File(s) Size (KB)','Log File(s) Size (KB)','Average Wait Time (ms)')
and instance_name = '_Total'
GROUP BY counter_name
UNION
SELECT 
	counter_name
	,	SUM(cntr_value) as cntr_value
FROM sys.dm_os_performance_counters 
WHERE counter_name in ('CPU usage %', 'Errors/sec')
GROUP BY counter_name
UNION
SELECT 
	REPLACE(counter_name, 'KB','GB')
	,	SUM(cntr_value/1024/1024) as cntr_value 
FROM sys.dm_os_performance_counters 
WHERE counter_name in ('Max memory (KB)','Used memory (KB)')
GROUP BY REPLACE(counter_name, 'KB','GB')
    
" | Out-GridView
Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -Query "

" | Out-GridView
Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -Query "

" | Out-GridView
Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -Query "

" | Out-GridView
Invoke-DbaQuery -SqlInstance $sqlinstance -SQLCredential $cred -Query "

" | Out-GridView
