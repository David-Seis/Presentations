Clear-host

$certname = "Testcert"

$ServiceAccount = $host.ui.PromptForCredential("Service Account Credential", "Please enter the domainname\username and password for the service account that will run the tasks (password expiry = never is ideal).", "", "")

    
$APIKEY = $host.ui.PromptForCredential("SAPassword", "Please enter the sa password for SQL Servers", "SA", "")
    
<#==== Cert creation =====#>
IF ((Get-ChildItem "Cert:\LocalMachine\My" | Where-Object subject -eq "CN=$Certname")){
Write-host "Certificate found, this step is not needed. If reinstall is on purpose, please remove the previous of the certificate first" -ForegroundColor Red -BackgroundColor White
return
} ELSE {

Write-Host "Certificate not found, attempting install"

    New-SelfSignedCertificate -DnsName $Certname -CertStoreLocation "Cert:\LocalMachine\My" -KeyUsage KeyEncipherment,DataEncipherment,KeyAgreement -Type DocumentEncryptionCert | Out-Null
    $CertObj = Get-ChildItem "Cert:\LocalMachine\My" | Where-Object subject -eq "CN=$Certname" 

Write-Host "Security: Cert Created..." -ForegroundColor Green
    
    
<#==== Cert export =====#>
$pw = Get-Credential -Username "Certificate" -message "Enter Cert Backup Password (in 1Password)"
Export-PfxCertificate -Cert "Cert:\LocalMachine\My\$($CertObj.Thumbprint)" -FilePath "$SecurityPath\$Certname.pfx" -Password $pw.Password | Out-Null
Write-Host "Security: Cert File Exported to StraighPath Security Folder..." -ForegroundColor Green
    
    <#==== SaA Password Encyrption =====#>
    $APIKEY.GetNetworkCredential().Password | Protect-CmsMessage -To "CN=$Certname" -OutFile $SecurityPath\Sendgrid.txt | Out-Null
    
<#==== Service Account Read rights on cert =====#>
Invoke-Command -computername 'seis-work' -Credential $ServiceAccount -ScriptBlock {
$pw = Get-Credential -Username "Certificate" -message "Enter Cert Backup Password (in 1Password)"
Get-ChildItem -Path "C:\StraightPath\Reports\Security\$Certname.pfx" | Import-PfxCertificate -CertStoreLocation "Cert:\LocalMachine\My" -Password $pw.password  | Out-Null
}
Write-Host "Security: Service account granted rights to the certificate..." -ForegroundColor Green
    
}
    

    