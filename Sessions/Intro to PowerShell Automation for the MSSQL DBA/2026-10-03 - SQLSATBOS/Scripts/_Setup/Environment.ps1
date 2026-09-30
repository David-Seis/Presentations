<#
    Environment.ps1  --  the ONLY machine-specific file in this session.

    Every demo script begins with:
        . "$PSScriptRoot\..\_Setup\Environment.ps1"

    Change values here and the entire session follows. If you are running these
    demos on your own laptop, this is the one file you may need to touch.
#>

<# ---------- Lab identity ---------- #>

    # Demo-only password. It lives in a public repo on purpose -- never reuse it.
    $Global:LabSaPassword = 'SqlSat#Boston2026'
    $Global:LabSaUser     = 'sa'

    # RAM ceiling per container. 4 x 2 GB = 8 GB. Lower it to 1536 on a small laptop.
    $Global:LabMemoryMB   = 2048


<# ---------- Where the lab lives on THIS machine ---------- #>

    $Global:LabRoot    = 'C:\SQLSatLab'
    $Global:OutputPath = Join-Path $LabRoot 'output'   # CSVs and reports land here

    # Shared backup location, mounted into all four containers. Backing up on one
    # server and restoring on another is what the backup-testing demo needs.
    #
    # This is a Docker NAMED VOLUME, not a Windows folder, and that is deliberate:
    # SQL Server 2025 cannot write backups to a Docker Desktop bind mount (it fails
    # with OS error 31 on DiskChangeFileSize -- Docker's Windows filesystem shim does
    # not implement the sizing call 2025 makes). A named volume lives inside the Linux
    # VM and behaves like a normal disk for all four versions.
    #
    # To look inside it:  docker exec sqlsat2022 ls -la /var/opt/mssql/backup
    $Global:LabBackupVolume        = 'sqlsatlab-backup'
    $Global:LabContainerBackupPath = '/var/opt/mssql/backup'


<# ---------- The fleet ---------- #>

    # Port numbers end in the version year so you can read them at a glance.
    #
    # 'GroupAdd' exists because the images disagree about who SQL Server runs as:
    #     2017        no mssql user at all -- runs as root (0:0)
    #     2019        uid 10001, gid 0
    #     2022, 2025  uid 10001, gid 10001
    #
    # SQL writes backups mode 0640/0660 with no world-read bit. 2019/2022/2025 all share
    # uid 10001, so they read each other's files through the owner bits. 2017 is the odd
    # one out: its files land as root:root, which the others cannot read -- and that
    # breaks the cross-server restore in Act 4.
    #
    # Adding group 0 as a SUPPLEMENTARY group fixes it: root's files are group 0 and
    # mode 0640 grants group read. It has to be supplementary rather than primary,
    # because 2022+ needs to keep gid 10001 to create its /.system directory at startup
    # (forcing --user 10001:0 makes those containers fail to boot).
    $Global:LabServers = @(
        [pscustomobject]@{ Name = 'sqlsat2017'; Port = 14317; Version = '2017'; GroupAdd = $null; Image = 'mcr.microsoft.com/mssql/server:2017-latest' }
        [pscustomobject]@{ Name = 'sqlsat2019'; Port = 14319; Version = '2019'; GroupAdd = '0';   Image = 'mcr.microsoft.com/mssql/server:2019-latest' }
        [pscustomobject]@{ Name = 'sqlsat2022'; Port = 14322; Version = '2022'; GroupAdd = '0';   Image = 'mcr.microsoft.com/mssql/server:2022-latest' }
        [pscustomobject]@{ Name = 'sqlsat2025'; Port = 14325; Version = '2025'; GroupAdd = '0';   Image = 'mcr.microsoft.com/mssql/server:2025-latest' }
    )

    # Sample databases created on every server so the demos have something to chew on.
    $Global:LabDatabases = 'Sales','Inventory','Reporting'


<# ---------- Connection shortcuts used by the demos ---------- #>

    # ONE server  -- Act 1 "do it once"
    $Global:OneTarget = "localhost,$($LabServers[0].Port)"

    # ALL servers -- Act 2 "do it everywhere". This is the only line that changes.
    $Global:Targets   = $LabServers | ForEach-Object { "localhost,$($_.Port)" }

    $Global:LabCredential = [pscredential]::new(
        $LabSaUser,
        (ConvertTo-SecureString $LabSaPassword -AsPlainText -Force)
    )

    # Containers use self-signed certs, so trust them. Session-scoped, not -Register,
    # so we never leave anything behind on a borrowed machine.
    Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true
    Set-DbatoolsConfig -FullName sql.connection.encrypt   -Value $false

    # Every demo passes -SqlCredential $LabCredential. Splat this instead if you prefer:
    $Global:Lab = @{ SqlCredential = $LabCredential }


Write-Host "Lab environment loaded: $($LabServers.Count) servers, backup volume '$LabBackupVolume'" -ForegroundColor Green
