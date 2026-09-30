<#
    ACT 1: ONCE  --  do the task once, by hand, in PowerShell.

    1 - Your first command.

    The whole session rests on one idea: a PowerShell command returns OBJECTS,
    not text. That is why you can filter, sort and export the result without
    ever parsing a string.
#>

. "$PSScriptRoot\..\_Setup\Environment.ps1"


<# ---------- PowerShell is a shell first ---------- #>

    # Verb-Noun. Every command in PowerShell reads like a sentence.
    Get-Location
    Get-Date


<# ---------- Now something a DBA cares about ---------- #>

    # One server. One command. No T-SQL.
    # (@Lab supplies -SqlCredential for the container lab. On a real server you
    #  use Windows auth, so you just delete it.)
    Get-DbaDatabase -SqlInstance $OneTarget @Lab


<# ---------- The part that matters ---------- #>

    # That was not text on your screen. It was a collection of objects.
    # Proof: ask one of them what it is, and what it can do.
    $db = Get-DbaDatabase -SqlInstance $OneTarget -Database Sales @Lab

    $db.GetType().FullName          # a real .NET type, not a string
    $db.Name
    $db.RecoveryModel
    $db.LastFullBackup
    $db.SizeMB

    # Everything a database knows about itself, in one place:
    $db | Select-Object Name, RecoveryModel, Compatibility, Owner, LastFullBackup, SizeMB


<# ---------- Why this is different from what you are used to ---------- #>

<#
    In SSMS you would run a query, read the grid, and then copy-paste the answer
    into whatever came next. The moment you want to ACT on the result -- back up
    the ones with no recent backup, script out the ones owned by the wrong login --
    you are writing the query again by hand.

    Here the result is already structured. The next four scripts are just
    learning how to aim it.
#>
