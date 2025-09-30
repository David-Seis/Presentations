# Demo 1: Query currently installed modules

    Get-installedModule -ListAvailable | 
        Select-Object Name, Version, Path | 
        Sort-Object Name |
        Out-GridView -Title "Installed Modules" 

# Demo 2: Query currently loaded modules

    Get-Module | 
        Select-Object Name, Version, Path | 
        Sort-Object Name |
        Out-GridView -Title "Loaded Modules" 

# Demo 3: Query currently loaded modules with a specific name
    Get-Module -Name dbatools | 
        Select-Object Name, Version, Path | 
        Sort-Object Name |
        Out-GridView -Title "Dbatools" -PassThru

#demo 4: Query currently loaded modules with details
        Get-Module -Name dbatools | 
        Select-Object Name, Version, Path, ExportedCommands | 
        Sort-Object Name |
        Out-GridView -Title "Dbatools with Details" -PassThru

# Demo 5: Query currently loaded modules with splitting the exported commands
    Get-Module -Name dbatools | 
        Select-Object Name, Version, Path, ExportedCommands  | 
        Sort-Object Name |
        Out-GridView -Title "Dbatools with Details" -PassThru

# Demo 6: Use a different process to get the command names 
    Get-Command -Module dbatools |
        Sort-Object Name |
        Out-GridView -Title "Dbatools with Details" -PassThru


#demo 7: Install the dbatools module from the PSGallery

    Install-Module Dbatools
    Install-Module SqlServer
    
    Import-Module Dbatools
    Import-Module SqlServer


#demo 8: cleanup the modules
    Remove-Module Dbatools
    Remove-Module SqlServer
    Uninstall-Module Dbatools
    Uninstall-Module SqlServer

    

