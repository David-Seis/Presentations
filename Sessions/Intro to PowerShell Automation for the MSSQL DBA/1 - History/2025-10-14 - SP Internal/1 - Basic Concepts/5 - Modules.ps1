Set-ExecutionPolicy -Scope Process Bypass -Force
Install-Module dbatools -Scope CurrentUser -AllowClobber
Import-Module dbatools
$cred = Get-Credential
$sql  = Connect-DbaInstance -SqlInstance 'LABSQL1' -SqlCredential $cred


# Query currently installed modules

    Get-Module -ListAvailable | 
        Select-Object Name, Version, Path | 
        Sort-Object Name |
        Out-GridView -Title "Installed Modules" 

# Query currently loaded modules
    Get-Module | 
        Select-Object Name, Version, Path | 
        Sort-Object Name |
        Out-GridView -Title "Loaded Modules" 

#  Use a different process to get the command names 
    Get-Command -Module dbatools |
        Sort-Object Name |
        Out-GridView -Title "Dbatools with Details" -PassThru


# Install the dbatools module from the PSGallery
    Install-Module Dbatools    
    Import-Module Dbatools


# cleanup the modules
    Remove-Module Dbatools
    Uninstall-Module Dbatools


    

