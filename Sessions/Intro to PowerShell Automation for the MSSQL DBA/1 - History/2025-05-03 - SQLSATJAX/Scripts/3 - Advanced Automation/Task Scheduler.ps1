<# Create a report and task inside of task scheduler to check recent job runs #>


    ## DEPENDENCIES
    # 1. Dbatools
    # 2. Service account acctess to all monitored servers
    # 3. SendGrid account for email sending
    # 4. SendGrid token stored in C:\temp\Demo\Sendgrid.txt
    
    $ServiceAccount = $host.ui.PromptForCredential("Task Scheduler account", "Please enter the domainname\username and password for the service account that will run the tasks (password expiry = never is ideal). ", "TaskUser", "")

    <# Necessary Variables #>
    $reportname = "Job Run Report"

    $ClientName = 'Test-Lab' 
    $jobserver = 'Seis-Work'
    $monitoringTarget = $sqlinstance

 
    $EmailRecipients = 'David.seis@straightpathsql.com;' #separate with semicolons

    Write-Host "Creating Powershell File..." -ForegroundColor Green
    New-Item -Path "C:\StraightPath\Reports" -Name "$reportname`Script.ps1" -ItemType 'file' -value "
        
    <# Create C:\StraightPath\Reports for all the reports to go into#>
        `$dir = `"C:\StraightPath\Reports`"
        If(!(test-path -PathType container `$dir))
        {
            New-Item -ItemType Directory -Path `$path
        }
        `$path=`"C:\StraightPath\Reports\$clientname`_$reportname`$(get-date -f MM-dd-yyyy).htm`"

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
            Token           =  Unprotect-CmsMessage -Path C:\temp\Demo\Sendgrid.txt
            FromName        = `"StraightPathSendGrid`"
            ToName          = `"David`"
        }
        Send-PSSendGridMail @Parameters
        "


    Write-Host "Creating XML File..." -ForegroundColor Green
    New-Item -Path "C:\StraightPath\Reports" -Name "$reportname`_Task.xml" -ItemType 'file' -value "<?xml version=`"1.0`" encoding=`"UTF-16`"?>
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

    Register-ScheduledTask -Xml (get-content "C:\StraightPath\Reports\$reportname`_Task.xml" | out-string) -Taskname "_REPORT_$reportname" -User ($ServiceAccount.GetNetworkCredential().username) -Password $($ServiceAccount.GetNetworkCredential().Password) 
