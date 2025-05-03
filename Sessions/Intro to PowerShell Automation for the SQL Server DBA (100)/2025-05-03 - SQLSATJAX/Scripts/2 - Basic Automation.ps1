<# Credentials and Targets#>
    $SQLInstance =  "Seis-Work,1433", "Seis-Work,1434", "Seis-Work,1435", "Seis-Work,1436", "Seis-Work,1437", "Presenter"
    $cred = $host.ui.PromptForCredential("SQL Credential", "Please enter the username and password for the SQL Auth account", "sa", "")

    Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -register  

<# Script to Backup, Copy a backup file, and then restore a database via DBAtools #> 

    Backup-DbaDatabase -SqlCredential $cred -SqlInstance 'seis-work,1433' -Database StackOverflow2010

    $Backup = Get-ChildItem -path C:\temp\Docker\SQL1\*.bak 
    $Backup | Copy-Item -Destination C:\temp\Docker\SQL2
    $backup.name

    Invoke-DBAQuery -sqlinstance 'seis-work,1434'  -SqlCredential $cred -query  "

        USE [master]
            RESTORE DATABASE [StackOverflow2010] FROM  DISK = N'/var/opt/mssql/data/$($backup.name)' WITH  FILE = 1,  MOVE N'StackOverflow2010' TO N'/var/opt/mssql/data/StackOverflow2010.mdf',  MOVE N'StackOverflow2010_log' TO N'/var/opt/mssql/data/StackOverflow2010_log.ldf',  NOUNLOAD,  STATS = 5

        GO
    "

<# Script to Clear the previous backup and restored database #> 

    Get-ChildItem -path C:\temp\Docker\SQL1\*.bak | Remove-Item 
    Get-ChildItem -Path C:\temp\Docker\SQL2\*.bak | Remove-Item

    Invoke-DBAQuery -sqlinstance 'seis-work,1434'  -SqlCredential $cred -query  "

        USE [master]
            RESTORE DATABASE [StackOverflow2010] FROM  DISK = N'/var/opt/mssql/data/$($backup.name)' WITH  FILE = 1,  MOVE N'StackOverflow2010' TO N'/var/opt/mssql/data/StackOverflow2010.mdf',  MOVE N'StackOverflow2010_log' TO N'/var/opt/mssql/data/StackOverflow2010_log.ldf',  NOUNLOAD,  STATS = 5

        GO
    "

<# Query to check the current job commands #>


    $sqlpresenter = 'Presenter'

    Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true


    $results = Invoke-dbaquery -SQlinstance $sqlpresenter -sqlcredential $cred -query "
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

<# query to fix job comands#>
    $SQLInstance = 'SEIS-Work' #, '', '', '', '' target SQL server(s)
    $Cleanuptime = '48'
    $Directory = '\\labshare\SQLBackups' 
    $SpecificDatabases = 'USER_DATABASES'

    $SystemFULLBackupsEnabled   = '1' # -- 1 = System full backup jobs enabled, 0 = disabled
    $UserFULLBackupsEnabled     = '1' # -- 1 = User full backup jobs enabled, 0 = disabled 
    $UserDIFFBackupsEnabled     = '1' # -- 1 = User diff backup jobs enabled, 0 = disabled 
    $UserLOGBackupsEnabled      = '1' # -- 1 = User log backup jobs enabled, 0 = disabled 

    Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true


    Invoke-DbaQuery -SQLInstance $SQLInstance -query "
    SELECT @@Servername as [server name], name, enabled FROM msdb.dbo.sysjobs where name like '%DatabaseBackup%'
    "| Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | format-table

    Write-Host "Adjust System databases full Backup Job..." -ForegroundColor Green
    Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_jobstep -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - SYSTEM_DATABASES - FULL"; subsystem="TSQL"; database_name="DB_Administration"; step_id = "1"; 
    command = "EXECUTE [dbo].[DatabaseBackup]
    @Databases = 'SYSTEM_DATABASES',
    @Directory = '$Directory', 
    @BackupType = 'FULL',
    @Verify = 'Y',
    @CleanupTime = $Cleanuptime,
    @CheckSum = 'Y',
    @LogToTable = 'Y'"} -CommandType StoredProcedure

    Write-Host "Adjust User Databases FULL backup job..." -ForegroundColor Green
    Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_jobstep -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - USER_DATABASES - FULL"; subsystem="TSQL"; database_name="DB_Administration"; step_id = "1"; 
    command = "EXECUTE [dbo].[DatabaseBackup]
    @Databases = '$SpecificDatabases',
    @Directory = '$Directory', 
    @BackupType = 'FULL',
    @Verify = 'Y',
    @CleanupTime = $Cleanuptime,
    @CheckSum = 'Y',
    @LogToTable = 'Y'"} -CommandType StoredProcedure

    Write-Host "Adjust User Databases diff backup job..." -ForegroundColor Green
    Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_jobstep -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - USER_DATABASES - DIFF"; subsystem="TSQL"; database_name="DB_Administration"; step_id = "1"; command = "EXECUTE [dbo].[DatabaseBackup]
    @Databases = '$SpecificDatabases',
    @Directory = '$Directory',
    @BackupType = 'DIFF',
    @Verify = 'Y',
    @CleanupTime = $Cleanuptime,
    @CheckSum = 'Y',
    @LogToTable = 'Y'
    "} -CommandType StoredProcedure

    Write-Host "Adjust User Databases log backup job..." -ForegroundColor Green
    Invoke-DbaQuery -SqlInstance $SQLInstance -database msdb -Query sp_update_jobstep -SqlParameter @{ job_name = "_MAINT_DatabaseBackup - USER_DATABASES - LOG"; subsystem="TSQL";database_name="DB_Administration";step_id = "1"; command = "EXECUTE [dbo].[DatabaseBackup]
    @Databases = '$SpecificDatabases',
    @Directory = '$Directory',
    @BackupType = 'LOG',
    @Verify = 'Y',
    @CleanupTime = $Cleanuptime,
    @CheckSum = 'Y',
    @LogToTable = 'Y'
    "} -CommandType StoredProcedure



    Write-Host "Enabling/Disabling Backup jobs..." -ForegroundColor Green
    Invoke-DbaQuery -SQLInstance $SQLInstance -Query "
    USE [msdb]

    EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - SYSTEM_DATABASES - FULL', @enabled = $SystemFULLBackupsEnabled;
    EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - USER_DATABASES - FULL', @enabled = $UserFULLBackupsEnabled;
    EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - USER_DATABASES - DIFF', @enabled = $UserDIFFBackupsEnabled;
    EXEC msdb.dbo.sp_update_job @job_name=N'_MAINT_DatabaseBackup - USER_DATABASES - LOG', @enabled = $UserLOGBackupsEnabled;

    GO
    "


<# Query to check the fixed job commands #>


    $sqlinstance = 'SEIS-WORK'

    Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true


    $results = Invoke-dbaquery -SQlinstance $sqlinstance -query "
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


<# ADD one-off job for sql agent job #>

    $SQLInstance = 'Seis-Work' 

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
    "

    Invoke-DbaQuery -SQLInstance $SQLInstance -Query "
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
