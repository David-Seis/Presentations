$Instance =
$Database = 
$Dataloc = #do not use a trailing \
$Logloc = #do not use a trailing \


Move-DbaDbFile -SqlInstance $Instance -Database $Database -FileType Data -FileDestination $Dataloc -force 
Move-DbaDbFile -SqlInstance $Instance -Database $Database -FileType LOG -FileDestination $Logloc -force 