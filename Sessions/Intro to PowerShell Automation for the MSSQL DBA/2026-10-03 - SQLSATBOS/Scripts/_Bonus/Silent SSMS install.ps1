#Requires -RunAsAdministrator
<#
    BONUS  --  silent SSMS install, on the machine you run this on.

    Nothing to do with the lab: this installs software here, so read it first.

    aka.ms/ssmsfullsetup now serves the SSMS 21+ installer, vs_SSMS.exe, which is a
    Visual Studio-style bootstrapper and takes Visual Studio installer switches
    (--quiet --norestart --wait). SSMS 18-20 used SSMS-Setup-ENU.exe with
    /Install /Passive -- if you need one of those, download it explicitly and use
    those switches instead.

    $UninstallOld removes SSMS 18-20 (MSI installs) AFTER the new one is in, so you
    are never left without one. SSMS 21+ installs side by side and is updated
    through the Visual Studio Installer.
#>

$UninstallOld = $true

$ssmsUrl     = 'https://aka.ms/ssmsfullsetup'
$downloadDir = Join-Path $env:TEMP 'ssms-install'
$destination = Join-Path $downloadDir 'vs_SSMS.exe'

# SSMS 18-20 register as an MSI product with this name. (Win32_Product is slow --
# it enumerates every MSI on the box -- so this runs once per question.)
function Get-OldSsms { Get-CimInstance -ClassName Win32_Product -Filter "Name = 'SQL Server Management Studio'" }


<# Current install audit #>
Get-OldSsms | ForEach-Object {
    Write-Host "SSMS: Currently installed (MSI) [Version: $($_.Version)]" -ForegroundColor Green
}


<# New installer download #>
try {
    New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
    Write-Host "SSMS: Downloading the current SSMS installer..." -ForegroundColor Green
    Invoke-WebRequest -Uri $ssmsUrl -OutFile $destination -UseBasicParsing
}
catch {
    Write-Host "Unable to download the SSMS installer, please download and install manually." -ForegroundColor Red -BackgroundColor White
    return
}


<# Install silently #>
Write-Host "SSMS: Installing SSMS (this takes several minutes)..." -ForegroundColor Green
$install = Start-Process -FilePath $destination -ArgumentList '--quiet', '--norestart', '--wait' -Wait -PassThru
Remove-Item $destination -ErrorAction SilentlyContinue

# 0 = success, 3010 = success but a restart is needed
if ($install.ExitCode -notin 0, 3010) {
    Write-Host "SSMS: Installer exited with code $($install.ExitCode) -- old versions left in place." -ForegroundColor Red
    return
}
if ($install.ExitCode -eq 3010) { Write-Host "SSMS: Installed. A restart is required to finish." -ForegroundColor Yellow }


<# Remove the old MSI-based versions, now that the new one is in #>
if ($UninstallOld) {
    Get-OldSsms | ForEach-Object {
        Write-Host "SSMS: Uninstalling SSMS [Version: $($_.Version)]..." -ForegroundColor Green
        Invoke-CimMethod -InputObject $_ -MethodName Uninstall | Out-Null
    }
}

Write-Host "SSMS: Done. SSMS 21+ shows up under 'SQL Server Management Studio' in the Start menu." -ForegroundColor Green
