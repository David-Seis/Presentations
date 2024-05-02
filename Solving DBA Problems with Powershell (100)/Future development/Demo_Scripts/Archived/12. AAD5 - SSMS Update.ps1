<#=====================================================================================================#>
<#============ SSMS UPDATE ============================================================================#>
<#=====================================================================================================#>

$SSMSUpdate =1

IF($SSMSUpdate -eq 1){
    Write-Host "SSMS: SSMS Update flag was on, enumerating SSMS installs..." -ForegroundColor Green
    Invoke-Command -ScriptBlock {
        Get-WmiObject Win32_product | Where-Object {$_.name -like "*SQL Server Management Studio*"} | ForEach-object {
            Write-Host "SSMS: Uninstalling SSMS..." -ForegroundColor Green
            $_.Uninstall() | Out-null
        }
    }
    
    # Define the download URL and the destination
    $ssmsUrl = "https://aka.ms/ssmsfullsetup"
    $destination = "C:\Temp\ssms_installer.exe"
    
    # Download SSMS installer
    $WebClient = New-Object System.Net.WebClient
    $webclient.DownloadFile($ssmsUrl, $destination)
    Write-Host "Downloading newest SSMS Installer..." -ForegroundColor Green
    
    # Install SSMS silently
    $install_path = "`"C:\Program Files (x86)\Microsoft SQL Server Management Studio 19`""
    $params = " /Install /Passive SSMSInstallRoot=$install_path /quiet"
            
    Write-Host "SSMS: Installing SSMS..." -ForegroundColor Green
    Start-Process -FilePath $destination -ArgumentList $params -Wait
    Remove-Item $destination
    Write-Host "SSMS: Server restart is required to implement changes fully" -ForegroundColor DarkRed
    }
    else {
        Write-Host "SSMS: SSMS Update Flag was set to OFF" -ForegroundColor DarkYellow  <# Action when all if and elseif conditions are false #>
    }
    