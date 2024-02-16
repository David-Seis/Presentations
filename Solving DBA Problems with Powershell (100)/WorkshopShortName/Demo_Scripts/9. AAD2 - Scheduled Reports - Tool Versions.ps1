NEEDS Adjustment before session


<#====================================================================================================================#>
<#============ Monthly Tooling Report PowerShell file creation =======================================================#>
<#====================================================================================================================#>

IF($CreateToolingReport -eq 1) {

    Write-Host "Tooling Report: Install Tooling report was set to on..." -ForegroundColor Green
    
    <#==== Advanced Variables - Please do not change unless necessary =====#>
    <#========= Please record any changes here and let David Know =========#>
    $SecurityPath = "C:\StraightPath\Reports\Security"
        If(!(test-path -PathType container $SecurityPath))
        {
        New-Item -ItemType Directory -Path $SecurityPath | Out-Null
        }
    
    $ScriptPath = "C:\StraightPath\Reports"
    $ReportName = "Monthly Tooling Report"
    
    
    Write-Host "Tooling Report: Creating Powershell File (Monthly Tools Report)..." -ForegroundColor Green
    New-Item -Path $ScriptPath -name $("_REPORT_"+$ReportName+"_Script.ps1") -ItemType 'file' | Set-Content -Encoding UTF8  -value "
    
    <#==========================================================#>
    <#==========================================================#>
    `$root = '$DataCollector' +'_'+$ClientID+'_'+'$ClientName'
    
    Write-Host `"Server Prep...`" -ForegroundColor Green
    `$ServerTable = `$root+'_ServerTable_'+`$(get-date -f MM-dd-yy)
    `$InstanceTable = `$root+'_InstanceTable_'+`$(get-date -f MM-dd-yy)
    `$SrvrTableDetails = `$root+'_SrvrTableDetails_'+`$(get-date -f MM-dd-yy)
    `$jumpboxfile = `$root+'_Jumpbox_'+`$(get-date -f MM-dd-yy)
    
    `$dir = `"C:\Temp\SPReports`"
    If(!(test-path -PathType container `$dir))
    {
    New-Item -ItemType Directory -Path `$dir
    }
    
    Set-DbatoolsConfig -FullName sql.connection.trustcert -Value `$true
        

    <#=======================================#>
    <# Required Functions ===================#>
    <#=======================================#>
    Function Get-FileMetadata {
        <#
            .SYNOPSIS
                Get file metadata from files in a target folder.
            
            .DESCRIPTION
                Retreives file metadata from files in a target path, or file paths, to display information on the target files.
                Useful for understanding application files and identifying metadata stored in them. Enables the administrator to view metadata for application control scenarios.
    
            .NOTES
                Author: Aaron Parker
                Twitter: @stealthpuppy
            
            .LINK
                https://github.com/aaronparker/Install-VisualCRedistributables
    
            .OUTPUTS
                [System.Array]
    
            .PARAMETER Path
                A target path in which to scan files for metadata.
    
            .PARAMETER Include
                Gets only the specified items.
    
            .EXAMPLE
                Get-FileMetadata -Path `"C:\Users\aaron\AppData\Local\GitHubDesktop`"
    
                Description:
                Scans the folder specified in the Path variable and returns the metadata for each file.
        #>
        [CmdletBinding(SupportsShouldProcess = `$False)]
        [OutputType([Array])]
        Param (
            [Parameter(Mandatory = `$True, Position = 0, ValueFromPipeline = `$True, ValueFromPipelineByPropertyName = `$True, `
                    HelpMessage = 'Specify a target path, paths or a list of files to scan for metadata.')]
            [Alias('FullName', 'PSPath')]
            [string[]]`$Path,
    
            [Parameter(Mandatory = `$False, Position = 1, ValueFromPipeline = `$False, `
                    HelpMessage = 'Gets only the specified items.')]
            [Alias('Filter')]
            [string[]]`$Include = @('*.exe', '*.dll', '*.ocx', '*.msi', '*.ps1', '*.vbs', '*.js', '*.cmd', '*.bat')
        )
        Begin {
            # Measure time taken to gather data
            `$StopWatch = [system.diagnostics.stopwatch]::StartNew()
    
            # RegEx to grab CN from certificates
            `$FindCN = `"(?:.*CN=)(.*?)(?:,\ O.*)`"
    
            Write-Verbose `"Beginning metadata trawling.`"
            `$Files = @()
        }
        Process {
            # For each path in `$Path, check that the path exists
            ForEach (`$Loc in `$Path) {
                If (Test-Path -Path `$Loc -IsValid) {
                    # Get the item to determine whether it's a file or folder
                    If ((Get-Item -Path `$Loc).PSIsContainer) {
                        # Target is a folder, so trawl the folder for .exe and .dll files in the target and sub-folders
                        Write-Verbose `"Getting metadata for files in folder: `$Loc`"
                        `$items = Get-ChildItem -Path `$Loc -Recurse -Include `$Include
                    }
                    Else {
                        # Target is a file, so just get metadata for the file
                        Write-Verbose `"Getting metadata for file: `$Loc`"
                        `$items = Get-Item -Path `$Loc
                    }
    
                    # Create an array from what was returned for specific data and sort on file path
                    `$Files += `$items | Select-Object @{Name = `"Path`"; Expression = {`$_.FullName}}, `
                    @{Name = `"Owner`"; Expression = {(Get-Acl -Path `$_.FullName).Owner}}, `
                    @{Name = `"Vendor`"; Expression = {`$(((Get-AcDigitalSignature -Path `$_ -ErrorAction SilentlyContinue).Subject -replace `$FindCN, '`$1') -replace '`"', `"`")}}, `
                    @{Name = `"Company`"; Expression = {`$_.VersionInfo.CompanyName}}, `
                    @{Name = `"Description`"; Expression = {`$_.VersionInfo.FileDescription}}, `
                    @{Name = `"Product`"; Expression = {`$_.VersionInfo.ProductName}}, `
                    @{Name = `"ProductVersion`"; Expression = {`$_.VersionInfo.ProductVersion}}, `
                    @{Name = `"FileVersion`"; Expression = {`$_.VersionInfo.FileVersion}}
                }
                Else {
                    Write-Error `"Path does not exist: `$Loc`"
                }
            }
        }
        End {
    
            # Return the array of file paths and metadata
            `$StopWatch.Stop()
            Write-Verbose `"Metadata trawling complete. Script took `$(`$StopWatch.Elapsed.TotalMilliseconds) ms to complete.`"
            Return `$Files | Sort-Object -Property Path
        }
    }
    
    <#=======================================#>
    <# Required Functions END ===============#>
    <#=======================================#>
    
    
    Write-Host `"Jumpbox Details...`" -ForegroundColor Green
    `$UpdateSession = New-Object -ComObject Microsoft.Update.Session
    `$UpdateSearcher = `$UpdateSession.CreateupdateSearcher()
    `$Updates = @(`$UpdateSearcher.Search(`"IsHidden=0 and IsInstalled=0`").Updates)
    
    `$Jumpbox = [PSCustomObject]@{
        ClientID = $clientID
        Servername = `$env:computername
        BeaconVersion = If(test-path `"C:\SQL Beacon\SQL Beacon Agent Gen2\SQLBeaconAgentGen2.exe`"){Get-FileMetadata -Path `"C:\SQL Beacon\SQL Beacon Agent Gen2\SQLBeaconAgentGen2.exe`" | Select-Object ProductVersion} ELSE{`"NULL`"}
        SQLSentryVersion = Get-WmiObject -Class Win32_Product | Where-Object name -like `"*SQL Sentry*`" | Sort-Object | Select-Object Version -Last 1
        SSMSVersion = Get-WmiObject -Class Win32_Product | Where-Object name -like `"SQL Server Management Studio`" | Sort-Object | Select-Object Version -Last 1
        DBAToolsVersion = get-installedmodule -name dbatools | Sort-Object | Select-Object Version -Last 1
        SQLSentryMonitoringJob = If(Get-ScheduledTask | Where-Object taskname -like `"*S1*Monitor*`") {`"TRUE`"} ELSE {`"False`"} 
        MonthlyProactiveReportJob = If(Get-ScheduledTask | Where-Object taskname -like `"*Monthly-Best-Practices*`") {`"TRUE`"} ELSE {`"False`"} 
        PasswordExpiringJob = If(Get-ScheduledTask | Where-Object taskname -like `"*Login*Expiration`") {`"TRUE`"} ELSE {`"False`"}
        WindowsOSVersion = [Environment]::OSVersion | Select-Object Version
        MostRecentHotfix = Get-Hotfix | Sort-Object | Select-Object hotfixid -last 1
        PendingUpdates = `$Updates.count
        CollectionDate = `$(get-date)
    }
    
    `$Jumpbox | Export-Csv -Path `"C:\Temp\SPReports\`$jumpboxfile.csv`" -NoTypeInformation
    (get-content `"C:\Temp\SPReports\`$jumpboxfile.csv`") -replace `"@{ProductVersion=`",`"`" -replace `"@{Version=`",`"`" -replace `"}`",`"`" -replace `"@{hotfixid=`",`"`" | Out-File `"C:\Temp\SPReports\`$jumpboxfile.csv`" -Force
    
    
    Set-location -path C:\Temp
    Write-Host `"Zipping Reports...`" -ForegroundColor Green
    `$compress = @{
    Path = `"C:\Temp\SPReports`"
    ArchiveFileName = `"$ClientName`_Reports_`$(get-date -f MM-yyyy).zip`"
    Password = `"regency5precook9cameo@betaken2tomcat!bran.shell2ROWDY`"
    }
    Compress-7Zip @compress
    
    
    Write-Host `"Sending email...`" -ForegroundColor Green
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    `$Parameters = @{
        FromAddress     = `"alertinbox@straightpathsql.com`"
        ToAddress       = `"david.seis@straightpathsql.com`"
        CCAddress       = `"alertinbox@straightpathsql.com`"
        Subject         = `"Reports for $ClientName attached!`"
        Body            = `"Please find your reports for $ClientName, sent by $DataCollector, attached!`"
        Token           = Unprotect-CmsMessage -Path $SecurityPath\Sendgrid.txt
        FromName        = `"StraightPathSendGrid`"
        ToName          = `"David`"
        AttachmentPath  = `"C:\temp\$ClientName`_Reports_`$(get-date -f MM-yyyy).zip`"
    }
    Send-PSSendGridMail @Parameters
    
    
    
    Write-Host `"Deleting Local Files...`" -ForegroundColor Green
    Remove-Item `"C:\Temp\SPReports\`$jumpboxfile.csv`"
    Remove-Item `"C:\Temp\$ClientName`_Reports_`$(get-date -f MM-yyyy).zip`"
    
    Write-Host `"Complete!`" -ForegroundColor Green" | Out-Null
    
    
    <#====================================================================================================================#>
    <#============ Monthly Tooling Report XML Task creation ==============================================================#>
    <#====================================================================================================================#>
    
    Write-Host "Tooling Report: Creating XML File (Monthly Tools Report)..." -ForegroundColor Green
    New-Item -Path $ScriptPath -Name "_REPORT_$ReportName`_Task.xml" -ItemType 'file' -value "<?xml version=`"1.0`" encoding=`"UTF-16`"?>
    <Task version=`"1.2`" xmlns=`"http://schemas.microsoft.com/windows/2004/02/mit/task`">
    <RegistrationInfo>
    <Date>2024-01-01T00:00:00.0000000</Date>
    <Author>David Seis, Straight Path IT Solutions, LLC.</Author>
    <URI>\_REPORT_Straight Path Tools Report</URI>
    </RegistrationInfo>
    <Triggers>
    <CalendarTrigger>
    <StartBoundary>$(Get-Date -f yyyy-MM-dd)T23:59:59</StartBoundary>
    <ExecutionTimeLimit>PT2H</ExecutionTimeLimit>
    <Enabled>true</Enabled>
    <ScheduleByMonth>
      <DaysOfMonth>
        <Day>5</Day>
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
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
    </Settings>
    <Actions Context=`"Author`">
    <Exec>
    <Command>Powershell.exe</Command>
    <Arguments>-ExecutionPolicy Unrestricted -File `"$($ScriptPath+'\_REPORT_'+$ReportName+'_Script.ps1')`"</Arguments>
    </Exec>
    </Actions>
    </Task>" | Out-Null
    
    Write-Host "Tooling Report: Registering the _REPORT_$ReportName..." -ForegroundColor Green
    Register-ScheduledTask -Xml (get-content "$ScriptPath\_REPORT_$ReportName`_Task.xml" | out-string) -Taskname "_REPORT_$ReportName" -User $($ServiceAccount.GetNetworkCredential().username)  -Password $($ServiceAccount.GetNetworkCredential().Password) | Out-Null
    
    Start-ScheduledTask -TaskName "_REPORT_$ReportName"
    }
    else {
        Write-Host "Tooling Report: Tooling Report Flag was set to OFF" -ForegroundColor DarkYellow  <# Action when all if and elseif conditions are false #>
    }
    
    
    Write-Host "Complete!" -ForegroundColor Green