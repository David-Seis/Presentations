<# Basic Commands #>

    #get the current location of the powershell cli
    get-location

    #get the current date and time
    Get-date

    # get the region information of the computer
    get-culture


<# Arguments for powershell commands are similar to parameters in T-SQL stored procedures #>

    Get-ComputerInfo -Property "CsName","OsName","OsLastBootUpTime", "CsDomainRole"


<# Brief Demonstration of Variables #>

    $characterName = "Frodo Baggins"
    $characterJob = "Ring-bearer"
    $Role = "Hobbit of the Shire"

    # Use variables in a string
    $message = "Greetings, I am $characterName, a $characterJob and I am a $Role on a quest to destroy the One Ring."

    # Output the message
    Write-Output $message

<# Piping #>
# Get a list of actors
    $Actors = "Viggo Mortensen", "Elijah Wood", "Ian McKellen", "Orlando Bloom", "Sean Bean", "Liv Tyler"

    # Use piping to filter and manipulate data
    $Actors | Where-Object { $_ -match 'Mortensen' } | ForEach-Object { "$_ is the true king" }


<# Code to install Dbatools #>

    Install-Module Dbatools