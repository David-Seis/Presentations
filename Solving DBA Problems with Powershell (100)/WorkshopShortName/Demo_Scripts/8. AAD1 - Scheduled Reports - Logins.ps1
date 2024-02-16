NEEDS Adjustment before session


## DEPENDENCIES
# 1. Dbatools on the beacon server
# 2. Task service account needs access to all monitored servers
# 3. Task account needs LOG ON AS BATCH Job permission in local security policy
#	3a. may need to grant explicit access for the SQl service account tot he C:\Straightpath\Reports directory, or grant everyone access. 
# 	3b. May need to make the Straightpath Reports folder a Share with access to everyone if sendgrid is on a different server and it is using NT Accounts.
# 4. You may get an error for the register task step, all you need to do is improt the task manually and you should be good to go!

## WARNINGS -- 
# 1. Running this will cause a RECONFIGURE on the SENDGRID/ DBMAIL Instance
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true


<# Necessary Variables #>
$TaskSchedulerServiceAccount = ''
$TaskSchedulerServiceAccountPassword = ''

$ClientName = '' #Please use dashes as spaces 
$reportname = 'Weekly-Login-Report' 

$ServerToSetUpSendgridOn = '' #Needs to be a sql instance for SQLmail
$serverWhereBeaconLives = ''

$Testrecipient = 'david.seis@straightpathsql.com; alertinbox@straightpathsql.com'
$EmailRecipients = 'david.seis@straightpathsql.com; alertinbox@straightpathsql.com' #separate with semicolons within the ''

$Servers = 'se1sql400', 'se1sql500','se1sql600'
#known bug - manual server entry will not have quotations in final script - manual fix needed

<###############################################################################################################################>
<###############################################################################################################################>
<###################################                                                       #####################################>
<########################              Nothing Else Needs to be Changed below this line. 			############################>
<###################################                                                       #####################################>
<###############################################################################################################################>
<###############################################################################################################################>




<# Create C:\StraightPath\Reports for all the reports to go into#>
$dir = "\\$ServerWhereBeaconLives\C$\StraightPath\Reports"
If(!(test-path -PathType container $dir))
{
New-Item -ItemType Directory -Path $dir
}





Write-Host "Creating Powershell File..." -ForegroundColor Green
New-Item -Path "\\$serverWhereBeaconLives\C`$\StraightPath\Reports" -Name "$reportname`_Script.ps1" -ItemType 'file' -value "

Set-DbatoolsConfig -FullName sql.connection.trustcert -Value `$true

`$path=`"\\$ServerWhereBeaconLives\C$\StraightPath\Reports\$clientname`_$reportname`_`$(get-date -f MM-dd-yyyy).htm`"

<# Collect Server and Instance information #>
`$SQLInstance = $servers

<#Define an Empty Array to Hold all of the HTML Fragments #>
`$fragments = @()

#Define the HTML style
`$head = @`"
<style>
body { background-color:#FAFAFA; font-family:Arial;font-size:12pt; }
td, th { border:1px solid black; border-collapse:collapse; }
th { color:white; background-color:black; }
table, tr, td, th { padding: 2px; margin: 0px }
tr:nth-child(odd) {background-color: lightgray}
table { margin-left:50px; }
h3{ margin-left:30px; background-color:#abc8f7;}
h4{margin-left:40px; background-color:#abc8f7;}
</style>
<H1 style=`"color: white; background-color:#8fbaff;`">$reportname</H1>
<H2 style=`"background-color:#8fbaff;`">A Report from Straight Path IT Solutions, LLC.</H2>
`"@


`$fragments +=  `"<H3>Login Record</H3>`"

`$fragments +=   Invoke-DbaQuery -SQLInstance `$SQLInstance -Query `"

SELECT @@SERVERNAME AS [Server Name], [Login Name], LoginHistory, [Last Login Date], account_status, [last host] FROM [DB_Administration].[dbo].[LoginRecord]


`" | SELECT-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | ConvertTo-Html | Out-String


ConvertTo-HTML -Head `$head -Body `$fragments -PostContent `"<br><br><i>Report generated on `$(Get-Date)</i> via powershell on $ServerWhereBeaconLives. The report was sent from $ServerToSetUpSendgridOn via SendGrid and DBMail.`" | Out-File -FilePath `$path -Encoding ascii

`$output = ConvertTo-HTML -Head `$head -Body `$fragments -PostContent `"<br><br><i>Report generated on `$(Get-Date)</i> via powershell on $ServerWhereBeaconLives. The report was sent from $ServerToSetUpSendgridOn via SendGrid and DBMail.`"


#Define mail variables
`$subject = `"$clientname - $reportname Report: `$(Get-Date -f MM-yyyy)`" 


#Format Body and send the email
Invoke-dbaquery -SqlInstance $ServerToSetUpSendgridOn -query `"
EXEC msdb.dbo.sp_send_dbmail
@profile_name = 'StraightPath_Sendgrid_Profile',
@recipients = '$EmailRecipients',
@body = '`$output',
@body_format = 'HTML',
--@body = 'Please find your report attached!'
--@file_attachments= '`$path',
@subject = '`$subject';
GO
`"
"






Write-Host "Creating XML File..." -ForegroundColor Green
New-Item -Path "\\$ServerWhereBeaconLives\C$\Straightpath\Reports" -Name "$reportname`_Task.xml" -ItemType 'file' -value "<?xml version=`"1.0`" encoding=`"UTF-16`"?>
<Task version=`"1.2`" xmlns=`"http://schemas.microsoft.com/windows/2004/02/mit/task`">
<RegistrationInfo>
<Date>2022-02-23T12:59:09.8081565</Date>
<Author>David Seis, Straight Path IT Solutions, LLC.</Author>
<URI>\$reportname Report</URI>
</RegistrationInfo>
<Triggers>
<CalendarTrigger>
<StartBoundary>$(Get-Date -f yyyy-MM-dd)T23:59:59</StartBoundary>
<Enabled>true</Enabled>
<ScheduleByMonth>
<DaysOfMonth>
<Day>1</Day>
</DaysOfMonth>
<Months>
<January />
<February />
<March />
<April />
<May />
<June />
<July />
<August />
<September />
<October />
<November />
<December />
</Months>
</ScheduleByMonth>
</CalendarTrigger>
</Triggers>
<Principals>
<Principal id=`"Author`">
<UserId>$TaskSchedulerServiceAccount</UserId>
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

Register-ScheduledTask -Xml (get-content "\\$ServerWhereBeaconLives\C$\StraightPath\Reports\$reportname`_Task.xml" | out-string) -Taskname "_REPORT_$reportname" -User $TaskSchedulerServiceAccount  -Password $TaskSchedulerServiceAccountPassword



