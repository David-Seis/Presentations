<# SSMS update script #>
    
$uninstallold = 1

<# Current install audit #>    
Get-WmiObject Win32_product | Where-Object {$_.name -eq "SQL Server Management Studio"} | ForEach-object {
    Write-Host "SSMS: Currently Installed Versions of SSMS [Version: $($_.Version)]`..." -ForegroundColor Green
}


<# New Installer download #>
$ssmsUrl = "https://aka.ms/ssmsfullsetup"
$destination = "C:\Temp\ssms_installer.exe"

$version = ((get-item "C:\Temp\ssms_installer.exe").VersionInfo.FileVersion).Substring(0, 2)

try {
    Write-Host "SSMS: Downloading newest SSMS Installer..." -ForegroundColor Green
    $WebClient = New-Object System.Net.WebClient
    $webclient.DownloadFile($ssmsUrl, $destination)
}
catch {
    Write-Host "Unable to download the latest SSMS installer, please download and install manually." -ForegroundColor Red -BackgroundColor White
    return
}

IF($uninstallold -eq 1) {
<# Installer was successfully downloaded, uninstall old ssms versions #>
Write-Host "SSMS: SSMS Update flag was on, enumerating SSMS installs..." -ForegroundColor Green
    Invoke-Command -ScriptBlock {
        Get-WmiObject Win32_product | Where-Object {$_.name -eq "SQL Server Management Studio"} | ForEach-object {
            Write-Host "SSMS: Uninstalling SSMS [Version: $($_.Version)]`..." -ForegroundColor Green
            $_.Uninstall() | Out-null
        }
    }
}

# Install SSMS silently
$install_path = "`"C:\Program Files (x86)\Microsoft SQL Server Management Studio $version`""
$params = " /Install /Passive SSMSInstallRoot=$install_path /quiet"
        
Write-Host "SSMS: Installing SSMS..." -ForegroundColor Green
Start-Process -FilePath $destination -ArgumentList $params -Wait
Remove-Item $destination
#Write-Host "SSMS: Server restart is required to implement changes fully" -ForegroundColor DarkRed
Invoke-Command -ScriptBlock {
    Get-WmiObject Win32_product | Where-Object {$_.name -eq "SQL Server Management Studio"} | ForEach-object {
        Write-Host "SSMS: Currently Installed Versions of SSMS [Version: $($_.Version)]`..." -ForegroundColor Green
    }
}