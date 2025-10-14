
<# ADD one-off job for sql agent job #>

$Targets = 'Seis-Work' 

$OneOffSQLJob = '_MAINT_DatabaseIntegrityCheck - USER_DATABASES'

Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true

$getdate = Get-Date -UFormat "%m/%d/%Y"
$ActiveStartDate = Get-Date -UFormat "%Y%m%d" #or you can entered the desired future date using the YYYYMMDD format
Invoke-DbaQuery -SQLInstance $Targets -Query "
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
"

Invoke-DbaQuery -SQLInstance $Targets -Query "
SELECT s.name as Job_Name
, ss.name Schedule_name
, ss.date_created
, next_run_date 
FROM msdb.dbo.sysjobs s
LEFT JOIN msdb.dbo.sysjobschedules sj 
    ON s.job_id = sj.job_id  
LEFT JOIN msdb.dbo.sysschedules ss 
    ON ss.schedule_id = sj.schedule_id
WHERE s.name IN ('$OneOffSQLJob')
"
