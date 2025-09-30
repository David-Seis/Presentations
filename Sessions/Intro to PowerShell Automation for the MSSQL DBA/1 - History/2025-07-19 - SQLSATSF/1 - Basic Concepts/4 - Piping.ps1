
#Demo 1: Using the pipeline to filter and manipulate data
# the pipeline operator (|) is used to pass the output of one command as input to another command
    
    # Get a list of actors
    $Actors = "Viggo Mortensen", "Elijah Wood", "Ian McKellen", "Orlando Bloom", "Sean Bean", "Liv Tyler"

    invoke-dbaquery -sqlinstance seis-work -query "Select name from sys.databases"| ForEach-Object { "$_ is the true king" }
    # Use piping to filter and manipulate data
    $Actors | Where-Object { $_ -match 'o' } | ForEach-Object { "$_ is the true king" }


# Demo 2: Sorting and selecting data
$Actors | Sort-Object | Select-Object -First 3

# Demo 3: Converting data to uppercase
$Actors | ForEach-Object { $_.ToUpper() }

# Demo 4: Grouping and counting data
$Actors | Group-Object | ForEach-Object { "$($_.Name): $($_.Count)" }

# Demo 5: Filtering, sorting, and exporting data
$Actors | Where-Object { $_ -like '*o*' } | Sort-Object | Export-Csv -Path './FilteredActors.csv' -NoTypeInformation

# Demo 6: Calculating string lengths and finding the longest name
$Actors | ForEach-Object { [PSCustomObject]@{ Name = $_; Length = $_.Length } } | Sort-Object Length -Descending | Select-Object -First 1

# Demo 7: Creating a custom object and exporting to JSON
$Actors | ForEach-Object { [PSCustomObject]@{ ActorName = $_; NameLength = $_.Length } } | ConvertTo-Json | Set-Content -Path './Actors.json'
