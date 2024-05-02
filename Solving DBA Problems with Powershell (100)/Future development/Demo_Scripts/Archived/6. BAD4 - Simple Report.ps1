$SQLinstance ='LABSQL3'
$jobname= ''
$enable = '' #1 to enable, 0 to disable

Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true

invoke-dbaquery -SqlInstance $SQLinstance -Query "
use msdb
select @@servername as [Server Name], enabled from sysjobs where name like '%$jobname%'
" | format-table -autosize

invoke-dbaquery -SqlInstance $SQLinstance -Query "
Use msdb
go
exec msdb.dbo.sp_update_job @job_name N'$jobname',
    @enabled = $enable

" |format-table -autosize