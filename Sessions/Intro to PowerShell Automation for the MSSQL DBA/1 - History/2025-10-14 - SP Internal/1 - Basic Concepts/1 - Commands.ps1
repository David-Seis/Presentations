<#
-- Why PowerShell for DBAs

Repeatability: scripts beat screenshots
Scale: one pattern → many instances
Evidence: CSVs & transcripts keep you honest
dbatools: 700+ battle-tested DBA commands you can compose like LEGO®
🧠 Principle: Read first, change later. You’ll see Get-* and Test-* before any Set-*.




<# Basic Commands #>

    #get the current location of the powershell cli
    get-location

    #get the current date and time
    Get-date

    # get the region information of the computer
    get-culture

    # get the current computer information
    get-computerinfo

    # get the current process information
    get-process

    # get the current time zone information
    get-timezone


<#
-- The PowerShell Mental Model
PowerShell is object-oriented.

Objects → Filter → Shape → Output
Filter left, select late for speed and clarity.
Use splatting (@params) to make long commands readable.
Get-Help, Get-Command, and Get-Member are your best friends.
#>

# Discovery
Get-Command -Module dbatools *backup*
Get-Help Get-DbaDbBackupHistory -Online
'LABSQL1' | Get-Member  # everything's an object

# Splatting pattern
$params = @{ SqlInstance='LABSQL1'; Database='master'; Query='SELECT @@VERSION;' }
Invoke-DbaQuery @params
#>