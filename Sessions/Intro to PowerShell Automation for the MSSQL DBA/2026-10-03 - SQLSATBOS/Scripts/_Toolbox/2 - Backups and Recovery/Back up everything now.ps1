<#
    TOOLBOX  --  Backups and Recovery

    Back up everything now.

    The pre-change backup. Before a deployment, a patch, a schema migration or
    anything else you might need to undo -- take a COPY_ONLY full of everything
    in scope, so you have a known-good point that did not disturb the schedule.

    Ten seconds of typing that has saved a great many weekends.
#>

. "$PSScriptRoot\..\..\_Setup\Environment.ps1"


<# ---------- PARAMETERS ---------- #>

    $Reason     = 'pre-deploy'
    $BackupRoot = $LabContainerBackupPath     # a UNC share on real servers
    $Stamp      = Get-Date -Format 'yyyyMMdd_HHmm'

    # Dry run by default: every backup below only SAYS what it would do. Read that
    # list, then set this to $false and run it again.
    $DryRun     = $true


<# ---------- The important flag ---------- #>

<#
    -CopyOnly is what makes this safe to run at any time.

    A normal full backup resets the differential base, so your scheduled
    differentials silently start measuring from YOUR ad-hoc backup instead of
    from last Sunday's full. If your restore plan is "full plus latest diff",
    you have just broken it without any error being raised.

    COPY_ONLY takes the backup and leaves the chain alone.
#>

    Backup-DbaDatabase -SqlInstance $OneTarget @Lab `
        -Database Sales `
        -Type Full `
        -CopyOnly `
        -CompressBackup `
        -Checksum `
        -Path        $BackupRoot `
        -FilePath    "Sales_${Reason}_$Stamp.bak" `
        -WhatIf:$DryRun |
        Select-Object SqlInstance, Database, Type, TotalSize, Duration, BackupComplete


<# ---------- Everything on one server ---------- #>

<#
    Backup-DbaDatabase takes ONE -SqlInstance, unlike most of dbatools. So for
    several servers you pipe or loop -- this is the exception that makes the
    ForEach-Object lesson worth teaching.
#>

    Get-DbaDatabase -SqlInstance $OneTarget -ExcludeSystem @Lab |
        Backup-DbaDatabase -CopyOnly -CompressBackup -Checksum -Path $BackupRoot -WhatIf:$DryRun |
        Select-Object SqlInstance, Database, TotalSize, Duration, BackupComplete |
        Format-Table -AutoSize


<# ---------- Everything on every server ---------- #>

    foreach ($t in $Targets) {
        Write-Host "Backing up $t..." -ForegroundColor Green
        Get-DbaDatabase -SqlInstance $t -ExcludeSystem @Lab |
            Backup-DbaDatabase -CopyOnly -CompressBackup -Checksum -Path $BackupRoot -WhatIf:$DryRun |
            Select-Object SqlInstance, Database, TotalSize, Duration, BackupComplete
    }


<# ---------- Arguments worth knowing ---------- #>

<#
    -Checksum          verifies pages as they are read, and records a checksum in
                       the backup. Costs a little CPU; catches corruption at the
                       point of backup rather than at the point of restore.

    -Verify            runs RESTORE VERIFYONLY afterwards.

    -CompressBackup    smaller and usually FASTER, because less is written to disk.

    -FileCount 4       stripes across several files. Meaningfully quicker on large
                       databases -- but you need every file to restore.

    -MaxTransferSize / -BufferCount   tuning knobs for very large backups.

    -EncryptionAlgorithm AES256 -EncryptionCertificate MyCert
                       encrypted backups. Back the certificate up somewhere else,
                       or the backup is unrestorable.

    -TimeStampFormat   controls the generated filename.
#>


<# ---------- Confirm ---------- #>

    # -IncludeCopyOnly, or the history leaves out the copy-only backups this just took.
    Get-DbaDbBackupHistory -SqlInstance $Targets @Lab -Since (Get-Date).AddMinutes(-30) -IncludeCopyOnly |
        Select-Object SqlInstance, Database, Type, Start, Duration, IsCopyOnly,
                      @{ n = 'SizeMB'; e = { [math]::Round($_.TotalSize.Megabyte, 1) } },
                      Path |
        Sort-Object Start -Descending |
        Format-Table -AutoSize


<# ---------- And then test it ---------- #>

<#
    A backup you have not restored is a hope, not a backup.
    See 4 - Proven\1 - Test the backups.ps1.
#>
