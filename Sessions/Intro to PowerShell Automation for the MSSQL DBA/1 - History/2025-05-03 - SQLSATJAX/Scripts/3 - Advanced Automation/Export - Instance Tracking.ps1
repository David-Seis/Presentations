<# Credentials and Targets#>
$SQLInstance =  "Seis-Work,1433", "Seis-Work,1434", "Seis-Work,1435", "Seis-Work,1436", "Seis-Work,1437", "Presenter"
$cred = $host.ui.PromptForCredential("SQL Credential", "Please enter the username and password for the SQL Auth account", "sa", "")

Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -register 

$DemoDir = "C:\Temp\Demo"
If(!(test-path -PathType container $DemoDir))   
    { New-Item -ItemType Directory -Path $DemoDir   | Out-Null }

    <# Code to create the Instance tracking csv #> 


Write-Host "Instance tracking..." -ForegroundColor Green
Foreach ($inst in $SQLInstance) {
$serverdetails = Invoke-dbaquery -SqlInstance $Inst -SqlCredential $cred -Query "
IF OBJECT_ID('tempdb..#ola') IS NOT NULL
DROP TABLE #ola
    CREATE TABLE #ola (
    DbName NVARCHAR(100)
    , Ola_Version nvarchar(10)
    )
        INSERT #ola
        EXEC sp_MSforeachdb '
        USE [?]
        SELECT DISTINCT db_name(), CASE WHEN CHARINDEX(N''--// Version: '', OBJECT_DEFINITION(obj.[object_id])) > 0 
        THEN CAST(LEFT(SUBSTRING(OBJECT_DEFINITION(obj.[object_id]),CHARINDEX(N''--// Version: '',OBJECT_DEFINITION(obj.[object_id])) + LEN(N''--// Version: '') + 1, 19),10) AS NVARCHAR(10)) END 
        FROM sys.objects AS obj
        INNER JOIN sys.schemas AS sch 
        ON obj.[schema_id] = sch.[schema_id]
        WHERE sch.[name] = N''dbo''
        AND obj.[name] IN (N''CommandExecute'')'


IF OBJECT_ID('tempdb..#FR') IS NOT NULL
DROP TABLE #FR
    CREATE TABLE #FR (
    dbName NVARCHAR(100)
    , FRDate nvarchar(10)
    )
        INSERT #FR
        EXEC sp_MSforeachdb '
        USE [?]
        SELECT DISTINCT db_name(), 
        CAST(CAST(create_date as DATE) as NVARCHAR(10))
        FROM sys.objects AS obj
        WHERE obj.[name] LIKE ''SP_Blitz'''

        IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'sp_Blitz')
        BEGIN
        DECLARE @VersionOutput VARCHAR(30), @VersionDateOutput DATETIME;
        EXEC sp_Blitz 
        @Version = @VersionOutput OUTPUT, 
        @VersionDate = @VersionDateOutput OUTPUT,
        @VersionCheckMode = 1;
        END 

        DECLARE @num_logs int;
        EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'NumErrorLogs',@num_logs OUTPUT;


SELECT  
    getdate() as Run_Date
    ,   SERVERPROPERTY('MachineName') AS Machine_Name
    ,   SERVERPROPERTY('ServerName') AS Instance_Name
    ,   CASE 
            WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '16.%' THEN 2022
            WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '15.%' THEN 2019
            WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '14.%' THEN 2017
            WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '13.%' THEN 2016
            WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '12.%' THEN 2014
            WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '11.%' THEN 2012
            WHEN Convert(nvarchar(20),SERVERPROPERTY('ProductVersion')) LIKE '10.%' THEN 2008
            ELSE NULL 
        END AS [SQL_Version]
    ,   SERVERPROPERTY('Edition') AS SQL_Edition
    ,   SERVERPROPERTY('ProductLevel') AS Product_Level
    ,   SERVERPROPERTY('ProductUpdateLevel') AS Update_Level
    ,   SERVERPROPERTY('ProductVersion') AS SQL_Build
    ,   (SELECT Ola_Version FROM #ola WHERE DbName in ('DB_Administration','Maintenance','DBA')) AS Ola_Version
    ,   (SELECT CAST(@VersionOutput as NVARCHAR(5)) FROM #FR WHERE dbName in ('master')) AS First_Responder_Version
    ,   (SELECT service_account FROM sys.dm_server_services WHERE servicename like 'SQL Server (%') as SQL_Account
    ,   (SELECT service_account FROM sys.dm_server_services WHERE servicename like 'SQL Server Agent%') as SQL_Agent_Account
    ,   (SELECT datediff(day, sqlserver_start_time, getdate()) FROM sys.dm_os_sys_info) as Uptime_Days
    ,   (SELECT is_disabled FROM sys.server_principals WHERE sid = 0x01 ) as is_sa_disabled
    ,   CONNECTIONPROPERTY('local_net_address') AS local_net_address
    ,   CONNECTIONPROPERTY('local_tcp_port') AS local_tcp_port
    ,   @num_logs as num_error_logs
    ,   GETDATE() AS Collection_Date

" 

    If(!(test-path $CSVpath)){
        $ServerDetails | Export-Csv -Path $CSVpath -Delimiter "," -NoTypeInformation
    } ELSE {
        $ServerDetails | Export-Csv -Path $CSVpath -Delimiter "," -NoTypeInformation -Append
    }
    }
