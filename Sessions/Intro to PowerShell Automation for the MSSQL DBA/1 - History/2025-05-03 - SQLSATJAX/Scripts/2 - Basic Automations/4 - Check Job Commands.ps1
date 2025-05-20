
<# Query to check the current job commands #>

    $Target = 'Seis-Work'

    Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true


    $results = Invoke-dbaquery -SQlinstance $Target  -sqlcredential $cred -query "
    select 
        @@servername as [Server Name]
        , s.name AS JobName
        , js.command 
        , SERVERPROPERTY('InstanceDefaultBackupPath') AS [Default Backup Path]
        
    from msdb.dbo.sysjobs s
    left join msdb.dbo.sysjobsteps js on js.job_id = s.job_id
    where s.name like '%MAINT%DatabaseBackup%'
    ORDER by s.name

    " 

    $results | Out-GridView 
    $results | Format-Table