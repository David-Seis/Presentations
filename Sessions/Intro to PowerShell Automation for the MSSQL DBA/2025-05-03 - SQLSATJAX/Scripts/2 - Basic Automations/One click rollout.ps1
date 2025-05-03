
<# Priming query to test connectivity and identify file locations for the administration database #>
###########################################################################
#						Created by David Seis							  #
#							  11/1/2022									  #
#																		  #
#					Straight Path IT Solutions, LLC.					  #
###########################################################################

<#
Requirements:
- DBATools version 2.0 Recommended, 1.0 minimum
- Permissions on the SQL Instances
#>

<# -------------------------- STEP 1  ------------------------------------#>
<# ----- Verifying Connectivity and file locations -----------------------#>

<# 
Description:
Use this to find out if your connection to the server is working, as well 
as the file locations for tha administrtaion database that will hold the 
community tools.

#>

#Change the test targets to the servers you want to prep for.
$TestTargets = 'Presenter' #, '', '', '', '' 

Invoke-DbaQuery -SQLInstance $TestTargets -SqlCredential $cred -query "
/*~~~ Find Current Location of Data and Log File of All the Database ~~~*/
SELECT 
@@servername as [Server name]
, TYPE_DESC
, physical_name AS current_file_location 
FROM sys.master_files 
--WHERE database_id > 4
ORDER BY type_desc
"| Select-object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | format-table

Invoke-DbaQuery -SQLInstance $TestTargets -SqlCredential $cred -query "
SELECT 
@@servername as [Server name]
, SERVERPROPERTY('InstanceDefaultDataPath') as default_data_path
, SERVERPROPERTY('InstanceDefaultlogPath') as default_log_path
"| Select-object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | Format-List 



<# Script to remove maintenance from a targeted server #>


Invoke-DbaQuery -sqlinstance $sqlpresenter -sqlcredential $Cred -query "

/* ~~~ Clears First Responder Kit Stored procedures from master if they exist ~~~*/
Use master
	DROP PROCEDURE /*if exists is 2016 or newer*/ IF EXISTS 
	[dbo].[sp_AllNightLog],
	[dbo].[sp_AllNightLog_Setup],
	[dbo].[sp_Blitz],
	[dbo].[sp_BlitzAnalysis],
	[dbo].[sp_BlitzBackups],
	[dbo].[sp_BlitzCache],
	[dbo].[sp_BlitzFirst],
	[dbo].[sp_BlitzIndex],
	[dbo].[sp_BlitzLock],
	[dbo].[sp_BlitzQueryStore],
	[dbo].[sp_BlitzWho],
	[dbo].[sp_WhoIsActive]
GO


/* ~~~ Drop DB_Administration ~~~*/
DROP DATABASE DB_Administration
GO


/* ~~~ DELETE STANDARD SP JOBS (you need to check if unique SP jobs exist) ~~~*/
USE msdb ;  
GO  
EXEC sp_delete_job  @job_name = N'_MAINT_CommandLog Cleanup' ;  
EXEC sp_delete_job  @job_name = N'_MAINT_CycleErrorLog' ;  
EXEC sp_delete_job  @job_name = N'_MAINT_DatabaseBackup - SYSTEM_DATABASES - FULL' ;  
EXEC sp_delete_job  @job_name = N'_MAINT_DatabaseBackup - USER_DATABASES - DIFF' ;  
EXEC sp_delete_job  @job_name = N'_MAINT_DatabaseBackup - USER_DATABASES - FULL' ;  
EXEC sp_delete_job  @job_name = N'_MAINT_DatabaseBackup - USER_DATABASES - LOG' ;  
EXEC sp_delete_job  @job_name = N'_MAINT_DatabaseIntegrityCheck - SYSTEM_DATABASES' ;  
EXEC sp_delete_job  @job_name = N'_MAINT_DatabaseIntegrityCheck - USER_DATABASES' ;  
EXEC sp_delete_job  @job_name = N'_MAINT_IndexOptimize - USER_DATABASES' ;  
EXEC sp_delete_job  @job_name = N'_MAINT_Output File Cleanup' ;  
EXEC sp_delete_job  @job_name = N'_MAINT_sp_delete_backuphistory' ;  
EXEC sp_delete_job  @job_name = N'_MAINT_sp_purge_jobhistory' ;  
EXEC sp_delete_job  @job_name = N'_MAINT_sp_whoisactive data collection monitoring' ;  
GO 


EXEC dbo.sp_delete_alert  @name = N'Error 823' ;
EXEC dbo.sp_delete_alert  @name = N'Error 824' ;
EXEC dbo.sp_delete_alert  @name = N'Error 825' ;
EXEC dbo.sp_delete_alert  @name = N'Severity 16 Error' ;
EXEC dbo.sp_delete_alert  @name = N'Severity 17 Error' ;
EXEC dbo.sp_delete_alert  @name = N'Severity 18 Error' ;
EXEC dbo.sp_delete_alert  @name = N'Severity 19 Error' ;
EXEC dbo.sp_delete_alert  @name = N'Severity 20 Error' ;
EXEC dbo.sp_delete_alert  @name = N'Severity 21 Error' ;
EXEC dbo.sp_delete_alert  @name = N'Severity 22 Error' ;
EXEC dbo.sp_delete_alert  @name = N'Severity 23 Error' ;
EXEC dbo.sp_delete_alert  @name = N'Severity 24 Error' ;
EXEC dbo.sp_delete_alert  @name = N'Severity 25 Error' ;
"

Write-Host "Maintenance was cleared" -ForegroundColor Green