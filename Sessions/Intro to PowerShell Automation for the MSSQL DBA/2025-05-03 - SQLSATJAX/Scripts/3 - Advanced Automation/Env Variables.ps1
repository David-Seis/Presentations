<# Environment Variables #>

$sqlinstance = 'Seis-Work'
$outputPath = "C:\temp\Demo"
$CSVpath = "$outputpath\Home-lab_InstanceTracking.csv" 

If(!(test-path -PathType container $outputPath)) 
{ 
    New-Item -ItemType Directory -Path $outputPath 
    Write-Host "$outputPath Directory was created"
}

Write-Host "Environment configured"