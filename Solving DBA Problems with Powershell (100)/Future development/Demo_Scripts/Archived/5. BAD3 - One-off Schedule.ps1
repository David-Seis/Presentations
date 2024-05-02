$SQLInstance = 'LabSQL3' 


$OneOffSQLJob = '_MAINT_DatabaseIntegrityCheck - USER_DATABASES'

Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true

$getdate = Get-Date -UFormat "%m/%d/%Y"
$ActiveStartDate = Get-Date -UFormat "%Y%m%d" #or you can entered the desired future date using the YYYYMMDD format
Invoke-DbaQuery -SQLInstance $SQLInstance -Query "
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'$OneOffSQLJob', @name=N'One-Off added $getdate', 
		@enabled=1, 
		@freq_type=1, 
		@freq_interval=1, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=$ActiveStartDate, 
		@active_end_date=99991231, 
		@active_start_time=230000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO"

Write-Host "Completed adding one off to $OneOffSQLJob" -ForegroundColor Green
Start-Sleep -Seconds 1.5 



Write-Host "checking for added schedule..." -ForegroundColor Green
Start-Sleep -Seconds 1.5 
Invoke-DbaQuery -SQLInstance $SQLInstance -Query "
select 
       @@Servername as [Server name],
	   s.name AS JobName,
       ss.name AS ScheduleName,                    
       CASE(ss.freq_type)
            WHEN 1  THEN 'Once'
            WHEN 4  THEN 'Daily'
            WHEN 8  THEN (case when (ss.freq_recurrence_factor > 1) then  'Every ' + convert(varchar(3),ss.freq_recurrence_factor) + ' Weeks'  else 'Weekly'  end)
            WHEN 16 THEN (case when (ss.freq_recurrence_factor > 1) then  'Every ' + convert(varchar(3),ss.freq_recurrence_factor) + ' Months' else 'Monthly' end)
            WHEN 32 THEN 'Every ' + convert(varchar(3),ss.freq_recurrence_factor) + ' Months' -- RELATIVE
            WHEN 64 THEN 'SQL Startup'
            WHEN 128 THEN 'SQL Idle'
            ELSE '??'
        END AS Frequency,
        ss.enabled, 
       CASE
            WHEN (freq_type = 1)                       then 'One time only'
            WHEN (freq_type = 4 and freq_interval = 1) then 'Every Day'
            WHEN (freq_type = 4 and freq_interval > 1) then 'Every ' + convert(varchar(10),freq_interval) + ' Days'
            WHEN (freq_type = 8) then (select 'Weekly Schedule' = MIN(D1+ D2+D3+D4+D5+D6+D7 )
                                        from (select ss.schedule_id,
                                                        freq_interval, 
                                                        'D1' = CASE WHEN (freq_interval & 1  <> 0) then 'Sun ' ELSE '' END,
                                                        'D2' = CASE WHEN (freq_interval & 2  <> 0) then 'Mon '  ELSE '' END,
                                                        'D3' = CASE WHEN (freq_interval & 4  <> 0) then 'Tue '  ELSE '' END,
                                                        'D4' = CASE WHEN (freq_interval & 8  <> 0) then 'Wed '  ELSE '' END,
                                                    'D5' = CASE WHEN (freq_interval & 16 <> 0) then 'Thu '  ELSE '' END,
                                                        'D6' = CASE WHEN (freq_interval & 32 <> 0) then 'Fri '  ELSE '' END,
                                                        'D7' = CASE WHEN (freq_interval & 64 <> 0) then 'Sat '  ELSE '' END
                                                    from msdb..sysschedules ss
                                                where freq_type = 8
                                            ) as F
                                        where schedule_id = sj.schedule_id
                                    )
            WHEN (freq_type = 16) then 'Day ' + convert(varchar(2),freq_interval) 
            WHEN (freq_type = 32) then (select  freq_rel + WDAY 
                                        from (select ss.schedule_id,
                                                        'freq_rel' = CASE(freq_relative_interval)
                                                                    WHEN 1 then 'First'
                                                                    WHEN 2 then 'Second'
                                                                    WHEN 4 then 'Third'
                                                                    WHEN 8 then 'Fourth'
                                                                    WHEN 16 then 'Last'
                                                                    ELSE '??'
                                                                    END,
                                                    'WDAY'     = CASE (freq_interval)
                                                                    WHEN 1 then ' Sun'
                                                                    WHEN 2 then ' Mon'
                                                                    WHEN 3 then ' Tue'
                                                                    WHEN 4 then ' Wed'
                                                                    WHEN 5 then ' Thu'
                                                                    WHEN 6 then ' Fri'
                                                                    WHEN 7 then ' Sat'
                                                                    WHEN 8 then ' Day'
                                                                    WHEN 9 then ' Weekday'
                                                                    WHEN 10 then ' Weekend'
                                                                    ELSE '??'
                                                                    END
                                                from msdb..sysschedules SS
                                                where ss.freq_type = 32
                                                ) as WS 
                                        where WS.schedule_id = ss.schedule_id
                                        ) 
        END AS Interval,
        CASE (freq_subday_type)
            WHEN 1 then   left(stuff((stuff((replicate('0', 6 - len(active_start_time)))+ convert(varchar(6),active_start_time),3,0,':')),6,0,':'),8)
            WHEN 2 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' seconds'
            WHEN 4 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' minutes'
            WHEN 8 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' hours'
            ELSE '??'
        END AS [Time],
        CASE sj.next_run_date
            WHEN 0 THEN cast('n/a' as char(10))
            ELSE convert(char(10), convert(datetime, convert(char(8),sj.next_run_date)),120)  + ' ' + left(stuff((stuff((replicate('0', 6 - len(next_run_time)))+ convert(varchar(6),next_run_time),3,0,':')),6,0,':'),8)
        END AS NextRunTime,
		js.command 
from msdb.dbo.sysjobs s
left join msdb.dbo.sysjobschedules sj on s.job_id = sj.job_id  
left join msdb.dbo.sysschedules ss on ss.schedule_id = sj.schedule_id
left join msdb.dbo.sysjobsteps js on js.job_id = s.job_id
where s.name in ('$OneOffSQLJob')
AND ss.freq_type = 1
order by s.name
" | Out-GridView


<#
$RunNowSQLJob = '_MAINT_DatabaseIntegrityCheck - SYSTEM_DATABASES'

Write-Host "Starting $RunNowSQLJob..." -ForegroundColor Green
Start-Sleep -Seconds 1.5 
Invoke-DbaQuery -SQLInstance $SQLInstance -Query "
USE msdb ;  
GO  
  
EXEC dbo.sp_start_job N'$RunNowSQLJob' ;  
GO
"
#>

