$sqlinstance = 'LabSQL3'

Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true


Invoke-dbaquery -SQlinstance $sqlinstance -query "
select 
       @@servername as [Server Name]
       , s.name AS JobName
       , js.command 
       , SERVERPROPERTY('InstanceDefaultBackupPath') AS [Default Backup Path]
	
from msdb.dbo.sysjobs s
left join msdb.dbo.sysjobsteps js on js.job_id = s.job_id
where s.name like '%MAINT%DatabaseBackup%'
ORDER by s.name

" | Out-GridView