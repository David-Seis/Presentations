clear-host
## DEPENDENCIES
# 1. Dbatools
# 2. Service account access to all monitored servers



## WARNINGS -- 
# 1. Running this will cause a RECONFIGURE on the SENDGRID/ DBMAIL Instance



<# Necessary Variables #>
$reportname = "Job Run Report"

$cred = $host.ui.PromptForCredential("Task Scheduler Login", "", "Test_Service", "") 

$ClientName = 'TestLab' #No spaces will look better!


$EmailRecipients = 'David.seis@straightpathsql.com;' #separate with semicolons



Write-Host "Creating Powershell File..." -ForegroundColor Green
    New-Item -Path "C:\Straightpath\Reports" -Name "$reportname`_Script.ps1" -ItemType 'file' -value "
            

            `$username = 'SA'
            `$password = 'Str0ngP@sSw0rd !'
            `$securePassword = ConvertTo-SecureString `$password -AsPlainText -Force
            `$credential = New-Object System.Management.Automation.PSCredential(`$username, `$securePassword)


        <# Create C:\StraightPath\Reports for all the reports to go into#>
            `$dir = `"C:\Straightpath\Reports`"
            If(!(test-path -PathType container `$dir))
            {
                New-Item -ItemType Directory -Path `$path
            }
            `$path=`"C:\Straightpath\Reports\$clientname`_$reportname`_$(get-date -f MM-dd-yyyy).htm`"

            `$sqllist = Get-Content -Path `"C:\StraightPath\Reports\SQLlist.txt`"


  



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

                <H2>Weekly Database Logins and Space Report</H2>
                <H3>Automated powershell script from Straight Path IT Solutions, LLC.</H3>
                `"


            `$results = Invoke-DbaQuery -SQLInstance `$SQLlist -sqlcredential `$credential -Query `"
                WITH jobhistory as 
                (   
                SELECT   
		                job_id
	                ,	Max(instance_id) instance_id
                FROM	msdb.dbo.sysjobhistory
                WHERE	step_id = 0
	                AND	run_status is not null                      
                GROUP BY job_id

                )
                SELECT  
	                @@ServerName as [Servername]
                ,	j.name
                ,	CASE sjh.run_status
		                WHEN 0 THEN 'Failed'
		                WHEN 1 THEN 'Succeeded'
		                WHEN 2 THEN 'Retry'
		                WHEN 3 THEN 'Canceled'
		                WHEN 4 THEN 'In Progress'
		                ELSE 'boogy man'
	                END RunStatus
                ,	last_run_time =  (msdb.dbo.agent_datetime(run_date, run_time))
                ,	last_end_time = (dateadd(ss,run_duration % 100 + ROUND((run_duration % 10000) / 100, 0, 0) * 60 + ROUND((run_duration % 1000000) / 10000, 0, 0) * 3600 ,msdb.dbo.agent_datetime(run_date, run_time)))           
                ,	CASE SJ.next_run_date
		                WHEN 0 THEN cast('n/a' as char(10))
		                ELSE convert(char(10), convert(datetime, convert(char(8),SJ.next_run_date)),120)  + ' ' + left(stuff((stuff((replicate('0', 6 - len(next_run_time)))+ convert(varchar(6),next_run_time),3,0,':')),6,0,':'),8)
	                END AS NextRunTime
                FROM	msdb.dbo.sysjobs j
	                LEFT OUTER JOIN jobhistory jh	ON j.job_id = jh.job_id
	                JOIN msdb..sysjobhistory sjh	ON jh.instance_id = sjh.instance_id
	                LEFT JOIN msdb.dbo.sysjobschedules SJ ON J.job_id = SJ.job_id  
	                LEFT JOIN msdb.dbo.sysschedules SS ON SS.schedule_id = SJ.schedule_id
	
                WHERE sjh.run_status is not null
	                AND j.enabled = 1
                ORDER BY Runstatus,last_end_time desc 
            
            `" | Select-object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | ConvertTo-Html | Out-String

            `$fragments += `"<br>$reportname</i>`"
            `$fragments += `$results 


        ConvertTo-HTML -Head `$head -Body `$fragments -PostContent `"<br><br><i>report generated: `$(Get-Date)</i>.`" | Out-File -FilePath `$path -Encoding ascii

        `$output = ConvertTo-HTML -Head `$head -Body `$fragments -PostContent `"<br><br><i>Report generated on `$(Get-Date)</i> via powershell.`" | Out-File -FilePath `$path -Encoding ascii

        #Define mail variables
            `$subject = `"$Reportname : `$(Get-Date -f MM-dd-yyyy)`" 
        

            #Format Body and send the email
            <#Invoke-dbaquery -SqlInstance $ServerToSetUpSendgridOn -query `"
            EXEC msdb.dbo.sp_send_dbmail
            @profile_name = '',
            @recipients = '$EmailRecipients',
            @body = '`$output',
            @body_format = 'HTML',
            @subject = '`$subject';
            GO
            `"
            #>
            "
        


    Write-Host "Creating XML File..." -ForegroundColor Green
        New-Item -Path "C:\Straightpath\Reports" -Name "$reportname`_Task.xml" -ItemType 'file' -value "<?xml version=`"1.0`" encoding=`"UTF-16`"?>
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
            <UserId>$($cred.GetNetworkCredential().username)</UserId>
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
            <Arguments>-ExecutionPolicy Unrestricted -File `"C:\StraightPath\Reports\$($reportname)`_Script.ps1`"</Arguments>
        </Exec>
        </Actions>
        </Task>"

    Register-ScheduledTask -Xml (get-content "C:\Straightpath\Reports\$reportname`_Task.xml" | out-string) -Taskname "_REPORT_$reportname" -User $($cred.GetNetworkCredential().username) -Password $($cred.GetNetworkCredential().Password)




