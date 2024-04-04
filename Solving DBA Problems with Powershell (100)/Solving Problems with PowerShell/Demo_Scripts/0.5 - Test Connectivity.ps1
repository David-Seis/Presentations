

$SQLLIST = 'seis-work,1433','seis-work,1434','seis-work,1435'

$cred = $host.ui.PromptForCredential("SQLlogin", "", "sa", "") #Str0ngP@sSw0rd !

invoke-dbaquery -sqlinstance $sqllist -SqlCredential $cred -Query "Select @@SERVERNAME as [Servername], @@Version as [Version]"