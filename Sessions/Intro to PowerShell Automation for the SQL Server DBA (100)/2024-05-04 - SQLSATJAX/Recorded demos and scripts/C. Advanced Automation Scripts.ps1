<# 001 - Instance tracking #> 
clear-host


$sqlinstance = 'labsql1','labsql2','labsql3'
$outputPath = "C:\Users\Administrator\Desktop\CheckOutputs"


Write-Host "Instance tracking..." -ForegroundColor Green
    Invoke-dbaquery -SqlInstance $SQLInstance -Query "
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
    SERVERPROPERTY('MachineName') AS Machine_Name
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

" |  Export-Csv -Path "$outputpath\Home-lab_InstanceTracking.csv" -Delimiter "," -Force -NoTypeInformation


<# 002 - Email Integration #>
clear-host
<#required PSSENDGRID PowerShell module#>

$Client_Name = "Test Labs"
$Data_Collector = "David"

Write-Host "Security: Sending Test email..." -ForegroundColor Green
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Parameters = @{
    FromAddress     = "alertinbox@straightpathsql.com"
    ToAddress       = "david.seis@straightpathsql.com"
    Subject         = "$Client_Name Email Test"
    Body            = "$Data_Collector is testing email configuration on the $Client_Name environment."
    Token           = Unprotect-CmsMessage -Path "C:\StraightPath\Reports\Security\Sendgrid.txt"
    FromName        = "$client_name"
    ToName          = "David"
}
Send-PSSendGridMail @Parameters 



<# 003 - Task Scheduling #>
clear-host

    ## DEPENDENCIES
    # 1. Dbatools
    # 2. Service account access to all monitored servers

    <# Necessary Variables #>
    $reportname = "Job Run Report"

    $ClientName = 'Test-Lab' 
    $jobserver = 'LABDC'
    $monitoringTarget = "LabSQL3"

    $ServiceAccount = $host.ui.PromptForCredential("Task Scheduler account", "Please enter the domainname\username and password for the service account that will run the tasks (password expiry = never is ideal). ", "DOMAIN\Account", "")

    $EmailRecipients = 'David.seis@straightpathsql.com;' #separate with semicolons

    Write-Host "Creating Powershell File..." -ForegroundColor Green
    New-Item -Path "\\$jobserver\C`$\StraightPath\Reports" -Name "$reportname`Script.ps1" -ItemType 'file' -value "
        
    <# Create C:\StraightPath\Reports for all the reports to go into#>
        `$dir = `"\\$jobserver\C$\StraightPath\Reports`"
        If(!(test-path -PathType container `$dir))
        {
            New-Item -ItemType Directory -Path `$path
        }
        `$path=`"\\$jobserver\C$\StraightPath\Reports\$clientname`_$reportname`$(get-date -f MM-dd-yyyy).htm`"

        `$SQLInstance= `"$monitoringTarget`"

    <#Define an Empty Array to Hold all of the HTML Fragments #>
        `$fragments = @()

    #Define the HTML style
        `$head = `"
            <style>
            body { background-color:#FAFAFA; font-family:Arial; font-size:12pt; }
            td, th { border:1px solid black; border-collapse:collapse; }
            th { color:white; background-color:black; }
            table, tr, td, th { padding: 2px; margin: 0px }
            tr:nth-child(odd) {background-color: lightgray}
            table { margin-left:50px; }
            </style>

            <H2>Daily Job Run report</H2>
            <H3>Automated powershell script from Straight Path IT Solutions, LLC.</H3>
            `"


        `$results = Invoke-DbaQuery -SQLInstance `$SQLInstance -Query `"
        WITH jobhistory as (   
            SELECT    job_id,
                        Max(instance_id) instance_id
            FROM      msdb.dbo.sysjobhistory
            WHERE     step_id = 0
                        AND run_status is not null
                        
            GROUP BY job_id
            --   order by run_status asc
            )
            SELECT  --  j.job_id,
                    j.name,
                    CASE sjh.run_status
                WHEN 0 THEN 'Failed'
                WHEN 1 THEN 'Succeeded'
                WHEN 2 THEN 'Retry'
                WHEN 3 THEN 'Canceled'
                WHEN 4 THEN 'In Progress'
                else 'boogy man'
            END RunStatus,
            --  jh.run_status,
            last_run_time =  (msdb.dbo.agent_datetime(run_date, run_time)),
                        last_end_time = (dateadd(ss,run_duration % 100 + ROUND((run_duration % 10000) / 100, 0, 0) * 60 + ROUND((run_duration % 1000000) / 10000, 0, 0) * 3600 ,msdb.dbo.agent_datetime(run_date, run_time)))
            --  ,j.enabled 
            
            ,
            CASE SJ.next_run_date
                        WHEN 0 THEN cast('n/a' as char(10))
                        ELSE convert(char(10), convert(datetime, convert(char(8),SJ.next_run_date)),120)  + ' ' + left(stuff((stuff((replicate('0', 6 - len(next_run_time)))+ convert(varchar(6),next_run_time),3,0,':')),6,0,':'),8)
                    END AS NextRunTime
            --           jh.duration
            FROM      msdb.dbo.sysjobs j
                    LEFT OUTER JOIN jobhistory jh
                    ON j.job_id = jh.job_id
                    join msdb..sysjobhistory sjh
                    on jh.instance_id = sjh.instance_id
                    left join msdb.dbo.sysjobschedules SJ on J.job_id = SJ.job_id  
            left join msdb.dbo.sysschedules SS on SS.schedule_id = SJ.schedule_id
            
            where sjh.run_status is not null
                and j.enabled = 1
            ORDER BY Runstatus,last_end_time desc 
        
        `" | Select-object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | ConvertTo-Html | Out-String

        `$fragments += `"<br>$reportname</i>`"
        `$fragments += `$results 

        ConvertTo-HTML -Head `$head -Body `$fragments -PostContent `"<br><br><i>report generated: `$(Get-Date)</i> from $jobserver.`" | Out-File -FilePath `$path -Encoding ascii

        `$output = ConvertTo-HTML -Head `$head -Body `$fragments -PostContent `"<br><br><i>Report generated on `$(Get-Date)</i> via powershell on $jobserver.`" | Out-File -FilePath `$path -Encoding ascii

        #Define mail variables
        `$subject = `"$Reportname : `$(Get-Date -f MM-dd-yyyy)`" 

        Write-Host `"Sending email...`" -ForegroundColor Green
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        `$Parameters = @{
            FromAddress     = `"alertinbox@straightpathsql.com`"
            ToAddress       = `"$EmailRecipients`"
            CCAddress       = `"alertinbox@straightpathsql.com`"
            Subject         = `"$reportname for $Client_Name attached!`"
            Body            = `"Please find the $reportname for $Client_Name, attached!`"
            Token           =  Unprotect-CmsMessage -Path C:\StraightPath\Reports\Security\Sendgrid.txt
            FromName        = `"StraightPathSendGrid`"
            ToName          = `"David`"
        }
        Send-PSSendGridMail @Parameters
        "


    Write-Host "Creating XML File..." -ForegroundColor Green
    New-Item -Path "\\$jobserver\C$\Straightpath\Reports" -Name "$reportname`_Task.xml" -ItemType 'file' -value "<?xml version=`"1.0`" encoding=`"UTF-16`"?>
    <Task version=`"1.2`" xmlns=`"http://schemas.microsoft.com/windows/2004/02/mit/task`">
        <RegistrationInfo>
        <Date>2022-02-23T12:59:09.8081565</Date>
        <Author>David Seis, Straight Path IT Solutions, LLC.</Author>
        <URI>\$reportname</URI>
    </RegistrationInfo>
    <Triggers>
    <CalendarTrigger>
        <StartBoundary>2023-05-31T08:00:00</StartBoundary>
        <Enabled>true</Enabled>
        <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
        </ScheduleByDay>
    </CalendarTrigger>
    <CalendarTrigger>
        <StartBoundary>2023-05-31T07:00:00</StartBoundary>
        <Enabled>true</Enabled>
        <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
        </ScheduleByDay>
    </CalendarTrigger>
    <CalendarTrigger>
        <StartBoundary>2023-05-31T09:00:00</StartBoundary>
        <Enabled>true</Enabled>
        <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
        </ScheduleByDay>
    </CalendarTrigger>
    </Triggers>
    <Principals>
        <Principal id=`"Author`">
        <UserId>$($ServiceAccount.GetNetworkCredential().username)</UserId>
        <LogonType>Password</LogonType>
        <RunLevel>HighestAvailable</RunLevel>
        </Principal>
    </Principals>
    <Settings>
        <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
        <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
        <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
        <AllowHardTerminate>true</AllowHardTerminate>
        <StartWhenAvailable>false</StartWhenAvailable>
        <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
        <IdleSettings>
        <StopOnIdleEnd>true</StopOnIdleEnd>
        <RestartOnIdle>false</RestartOnIdle>
        </IdleSettings>
        <AllowStartOnDemand>true</AllowStartOnDemand>
        <Enabled>true</Enabled>
        <Hidden>false</Hidden>
        <RunOnlyIfIdle>false</RunOnlyIfIdle>
        <WakeToRun>false</WakeToRun>
        <ExecutionTimeLimit>P3D</ExecutionTimeLimit>
        <Priority>7</Priority>
    </Settings>
    <Actions Context=`"Author`">
    <Exec>
        <Command>Powershell.exe</Command>
        <Arguments>-ExecutionPolicy Unrestricted -File `"C:\StraightPath\Reports\$reportname`_Script.ps1`"</Arguments>
    </Exec>
    </Actions>
    </Task>"

    Register-ScheduledTask -Xml (get-content "\\$jobserver\C$\StraightPath\Reports\$reportname`_Task.xml" | out-string) -Taskname "_REPORT_$reportname" -User ($ServiceAccount.GetNetworkCredential().username) -Password $($ServiceAccount.GetNetworkCredential().Password) 






<# 004 - Loading Data #>
    $managementInstance = 'labddc\sqlexpress'
    $managementDatabase = "DB_admin"
    $sqlinstance = 'labsql1','labsql2','labsql3'
    $outputPath = "C:\Users\Administrator\Desktop\CheckOutputs"


    Write-Host "Create Tracking Table ..." -ForegroundColor Green
        Invoke-dbaquery -SqlInstance $managementInstance  -Query "
        USE $managementDatabase
        CREATE TABLE InstanceTable (
        Inst_ID INT IDENTITY(1,1) NOT NULL
        , 	instance_ID BIGINT REFERENCES MasterInstanceTable(instance_ID)
        ,	Env_Type NVARCHAR(30) DEFAULT ''
        ,	SQL_Version NVARCHAR(10)
        ,	SQL_Edition NVARCHAR(50)
        ,	Product_Level NVARCHAR(20)
        , 	Update_Level NVARCHAR(20)
        ,	SQL_Build NVARCHAR(20)
        ,	Ola_Version NVARCHAR(20)
        ,	First_Responder_Version NVARCHAR(20)
        , 	SQL_Account NVARCHAR(255)
        , 	SQL_Agent_Account NVARCHAR(255)
        ,	Uptime_Days SMALLINT
        , 	is_sa_disabled BIT
        ,	local_net_address VARCHAR(48)
        ,	local_tcp_port INT
        ,	num_error_logs TINYINT
        ,   Collection_date datetime
        ,	[Valid_From] [datetime2](7) GENERATED ALWAYS AS ROW START NOT NULL
        ,	[Valid_To] [datetime2](7) GENERATED ALWAYS AS ROW END NOT NULL
        ,	PERIOD FOR SYSTEM_TIME (Valid_From, Valid_To)
        ,	CONSTRAINT [PK_InstanceTable_T] PRIMARY KEY CLUSTERED 
        ([Inst_ID] ASC)
        WITH 
        (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],) ON [PRIMARY]
        WITH
        (SYSTEM_VERSIONING = ON 
        (HISTORY_TABLE = [dbo].[InstanceTable_T_history]
        ,	HISTORY_RETENTION_PERIOD = 12 MONTHS)
        )
    GO

        CREATE UNIQUE NONCLUSTERED INDEX IX_InstanceTable_machinename_instancename_localnetaddress
        ON InstanceTable (machine_name, Instance_name,local_net_address)

        CREATE TABLE ToolsAudit (
        Tool_Name NVARCHAR(50) PRIMARY KEY 
        ,	Supported_Version NVARCHAR(30) 
        )
        INSERT ToolsAudit (Tool_Name, Supported_Version)
        VALUES 	('Ola_Hallengrin', '2022-12-03')
        ,	('First_Responder_Toolkit', '8.18')
        GO
        
        CREATE TABLE SQLBuilds (
            Version NVARCHAR(50) PRIMARY KEY 
            ,	SupportedBuild NVARCHAR(30) 
            )
            INSERT SQLBuilds (Version, SupportedBuild)
            VALUES ('2022', '16.0.4120.1')
            ,	('2019', '15.0.4365.2')
            ,	('2017', '14.0.3465.1')
            /*Azure connect updates only Below*/
            ,	('2016', '13.0.6435.1')
            ,	('2014', '12.0.6449.1')
            ,	('2012', '11.0.7507.2')
            ,	('2008 R2', '10.50.6560.0')
            ,	('2008', '10.0.6814.4')
        GO

    "

    $Instancefiles = Get-ChildItem -Path $outputPath\* | Where-Object Name -like "*InstanceTracking*"
        foreach ($inst in $Instancefiles) {
    Import-DbaCsv -Path $inst -SqlInstance $instance  -database $database  -schema dbo -AutoCreateTable -Delimiter ',' -enableexception 

    Invoke-DbaQuery -SqlInstance $instance  -database $database  -Query "
    USE $database

    UPDATE InstanceTable
    SET 
    SQL_Version = D.SQL_Version
    , SQL_Edition = D.SQL_Edition
    , Product_Level = D.Product_Level
    , Update_Level = D.Update_Level
    , SQL_Build = D.SQL_Build
    , Ola_Version = D.Ola_Version
    , First_Responder_Version = D.First_Responder_Version
    , SQL_Account = D.SQL_Account 
    , SQL_Agent_Account = D.SQL_Agent_Account 
    , Uptime_Days = D.Uptime_Days 
    , is_sa_disabled = D.is_sa_disabled
    , local_net_address = D.local_net_address 
    , local_tcp_port = D.local_tcp_port
    , num_error_logs = D.num_error_logs
    , collection_date = D.collection_date
    FROM InstanceTable I
    JOIN [dbo].[$((get-item $inst).basename)] D 
        D.Machine_Name = I.Machine_Name 
        AND D.instance_Name = I.Instance_Name

    INSERT INTO InstanceTable (Machine_name,Instance_name, SQL_Version, SQL_Edition, Product_Level, Update_Level, SQL_Build, Ola_Version, First_Responder_Version, SQL_Account, SQL_Agent_Account, Uptime_Days, is_sa_disabled, local_net_address, local_tcp_port, num_error_logs,collection_date)
    SELECT 
    mahcine_name
    , instance_name
    , SQL_Version
    , SQL_Edition
    , Product_Level
    , Update_Level
    , SQL_Build
    , Ola_Version
    , First_Responder_Version
    , SQL_Account
    , SQL_Agent_Account
    , Uptime_Days
    , is_sa_disabled
    , local_net_address 
    , local_tcp_port
    , num_error_logs
    FROM [dbo].[$((get-item $inst).basename)] D
    JOIN MasterMachineTable mm 
        ON D.machine_name = mm.Machine_name
        AND D.client_id = mm.client_id
    JOIN MasterInstanceTable mi
        ON mm.machine_id = mi.machine_id
    WHERE D.Instance_name NOT IN (SELECT Instance_name From InstanceTable)
            AND D.machine_name NOT IN (SELECT Machine_name from InstanceTable)

    DROP TABLE [dbo].[$((get-item $inst).basename)]
    "
    }

    <#
        SELECT 
            machine_name
            ,	Instance_name
            ,   CASE 
                    WHEN i.First_Responder_Version <> (SELECT Supported_Version FROM ToolsAudit AS ToolsAudit_1 WHERE (Tool_Name LIKE '%first%')) 
                        THEN 'YES || Current: [' + i.First_Responder_Version + '] =/= Target: [' + (SELECT     Supported_Version FROM        ToolsAudit AS ToolsAudit_1 WHERE (Tool_Name LIKE '%first%')) + ']' 
                    WHEN i.First_Responder_Version IS NULL 
                        THEN 'YES || Rollout Needed, First Responder not present.' 
                    ELSE 'NO  || [' + i.First_Responder_Version + ']' 
                END AS first_responder_update_needed
            ,	CASE 
                    WHEN i.Ola_Version <> (SELECT Supported_Version FROM ToolsAudit AS ToolsAudit_1 WHERE (Tool_Name LIKE '%Ola%')) 
                        THEN 'YES || Current: [' + i.Ola_Version + '] =/= Target: [' + (SELECT Supported_Version FROM ToolsAudit WHERE (Tool_Name LIKE '%Ola%')) + ']' 
                    WHEN i.Ola_Version IS NULL 
                        THEN 'YES || Rollout Needed, Ola not present.' 
                    ELSE 'NO  || [' + i.Ola_Version + ']' 
                END AS [Ola_Update_Needed]
            ,	CASE 
                    WHEN i.SQL_Build <> s.SupportedBuild 
                        THEN 'YES || Current: [' + i.SQL_Build + '] =/= Target: [' + s.SupportedBuild + ']' 
                    ELSE 'NO  || Current: [' + i.SQL_Build + ']' 
                END AS [Patch_Needed]
        FROM InstanceTable i
            JOIN SQLBuilds AS s
                ON i.SQL_Version = s.Version
    GO
    #>

    <# 005 - Updating Tools #>

    <# Current install audit #>
    Get-WmiObject Win32_product | Where-Object {$_.name -eq "SQL Server Management Studio"} | ForEach-object {
        Write-Host "SSMS: Currently Installed Versions of SSMS [Version: $($_.Version)]`..." -ForegroundColor Green
    }


    <# New Installer download #>
    $ssmsUrl = "https://aka.ms/ssmsfullsetup"
    $destination = "C:\Temp\ssms_installer.exe"

    try {
        Write-Host "SSMS: Downloading newest SSMS Installer..." -ForegroundColor Green
        $WebClient = New-Object System.Net.WebClient
        $webclient.DownloadFile($ssmsUrl, $destination)
    }
    catch {
        Write-Host "Unable to download the latest SSMS installer, please download and install manually." -ForegroundColor Red -BackgroundColor White
        return
    }

    <# Installer was successfully downloaded, uninstall old ssms versions #>
    Write-Host "SSMS: SSMS Update flag was on, enumerating SSMS installs..." -ForegroundColor Green
        Invoke-Command -ScriptBlock {
            Get-WmiObject Win32_product | Where-Object {$_.name -eq "SQL Server Management Studio"} | ForEach-object {
                Write-Host "SSMS: Uninstalling SSMS [Version: $($_.Version)]`..." -ForegroundColor Green
                $_.Uninstall() | Out-null
            }
        }


    # Install SSMS silently
    $install_path = "`"C:\Program Files (x86)\Microsoft SQL Server Management Studio 19`""
    $params = " /Install /Passive SSMSInstallRoot=$install_path /quiet"
            
    Write-Host "SSMS: Installing SSMS..." -ForegroundColor Green
    Start-Process -FilePath $destination -ArgumentList $params -Wait
    Remove-Item $destination
    #Write-Host "SSMS: Server restart is required to implement changes fully" -ForegroundColor DarkRed
    Invoke-Command -ScriptBlock {
        Get-WmiObject Win32_product | Where-Object {$_.name -eq "SQL Server Management Studio"} | ForEach-object {
            Write-Host "SSMS: Currently Installed Versions of SSMS [Version: $($_.Version)]`..." -ForegroundColor Green
        }
    }