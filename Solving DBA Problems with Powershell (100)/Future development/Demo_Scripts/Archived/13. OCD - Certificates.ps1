NEEDS Adjustment before session

$Certname = 'testcert'
IF($CertificateNeeded -eq 1) {
    $ServiceAccount = $host.ui.PromptForCredential("Service Account Credential", "Please enter the domainname\username and password for the service account that will run the tasks (password expiry = never is ideal).", "", "")
    
    Write-Host "Security: Certificate Marked as needing creation..." -ForegroundColor Green
    
    $APIKEY = $host.ui.PromptForCredential("APIKey", "Please enter the APIKey", "APIKey", "")
    
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
    
    <#==== Token Encyrption =====#>
    $APIKEY.GetNetworkCredential().Password | Protect-CmsMessage -To "CN=$Certname" -OutFile $SecurityPath\Sendgrid.txt | Out-Null
    
    <#==== Service Account Read rights on cert =====#>
    Invoke-Command -ComputerName localhost -Credential $ServiceAccount -ScriptBlock {
    $pw = Get-Credential -Username "Certificate" -message "Enter Cert Backup Password (in 1Password)"
    Get-ChildItem -Path "C:\StraightPath\Reports\Security\$Certname.pfx" | Import-PfxCertificate -CertStoreLocation "Cert:\LocalMachine\My" -Password $pw.password  | Out-Null
    }
    Write-Host "Security: Service account granted rights to the certificate..." -ForegroundColor Green
    
    }
    
    Write-Host "Security: Sending Test email..." -ForegroundColor Green
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $Parameters = @{
        FromAddress     = ""
        ToAddress       = "david.seis@straightpathsql.com"
        Subject         = "$ClientName Certificate Test"
        Body            = "$DataCollector has installed the Monthly Proactive Data Report on $ClientName using the [$($ServiceAccount.GetNetworkCredential().username)] account"
        Token           = Unprotect-CmsMessage -Path $SecurityPath\Sendgrid.txt
        FromName        = ""
        ToName          = "David"
    }
    Send-PSSendGridMail @Parameters 
    }
    else {
        Write-Host "Security: Certificate Needed Flag was set to OFF" -ForegroundColor DarkYellow  <# Action when all if and elseif conditions are false #>
    }
    
    