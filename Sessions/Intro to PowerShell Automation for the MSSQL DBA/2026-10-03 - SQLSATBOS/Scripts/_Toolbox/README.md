# Toolbox

Scripts that did not fit in a sixty-minute session but that you will want on a
Monday morning. Each one is a real task, commented with the *why* rather than
just the syntax.

Nothing here is theoretical — these are the shapes of the work: audits, sweeps,
refreshes, migrations, and the handful of checks that catch problems while they
are still cheap.

## Running them

Every script starts with:

```powershell
. "$PSScriptRoot\..\..\_Setup\Environment.ps1"
```

which gives you `$Targets` (all four lab servers), `$OneTarget` (just one), and
`@Lab` (the credential splat). So they run against the demo lab out of the box —
build it with `_Setup\1 - Deploy lab.ps1` first.

**To point them at your own servers**, edit `$Targets` in
[`_Setup/Environment.ps1`](../_Setup/Environment.ps1) and delete the `@Lab` from
the commands. On a domain with Windows authentication you do not need a
credential at all:

```powershell
# Lab
Get-DbaDatabase -SqlInstance $Targets @Lab

# Your servers, Windows auth
Get-DbaDatabase -SqlInstance 'SQLPROD01','SQLPROD02'
```

## Safety

Scripts are **read-only by default**. Anything that changes state is either
commented out or carries `-WhatIf`. Read before you run, and take `-WhatIf` off
only when you have seen the list of what it intends to do.

A few scripts reach the **Windows** side rather than the SQL side —
`Get-DbaDiskSpace`, `Test-DbaPowerPlan`, `Get-DbaService`,
`Test-DbaInstantFileInitialization`. These need remote admin rights and do **not**
work against containers. They are marked, and where a SQL-side equivalent exists
it is included and does work.

## What is here

| | |
|---|---|
| **1 · Discovery and Inventory** | Find instances you did not know about; document what they are; export an instance to files for DR and source control |
| **2 · Backups and Recovery** | Ad-hoc `COPY_ONLY` backups; restore with renaming and relocation; find broken backup chains and log gaps |
| **3 · Integrity and Corruption** | When CHECKDB last passed; suspect pages; whether the alerts that would tell you are even configured |
| **4 · Security and Access** | Who has sysadmin; login and role audit; orphaned users; unused logins; weak passwords |
| **5 · Configuration and Drift** | Best-practice sweep across the estate; patch level and end-of-support dates; deprecated features still in use |
| **6 · Agent Jobs** | Failure report; jobs that exist here but not there; jobs enabled with no schedule; jobs getting slower |
| **7 · Capacity and Growth** | File space and free space; autogrowth settings that will hurt; growth events; TempDB usage |
| **8 · Performance** | What is running right now; blocking; wait statistics; expensive queries; IO latency |
| **9 · Migration and Refresh** | Refresh dev from prod including the steps people forget; migrate a whole instance |
| **10 · Windows and Server** | Service state and accounts; uptime; error log sweep; clean up old files |

## Where to start

If you have never run any of this, in order:

1. **`5 - Configuration and Drift\Best practice sweep.ps1`** — read-only, fast, and
   it will find something. It always does.
2. **`2 - Backups and Recovery\Broken backup chain report.ps1`** — the one most
   likely to change what you do this week.
3. **`4 - Security and Access\Who has access to what.ps1`** — run it before
   somebody asks you to.

## A note on the pattern

Most of these follow the same shape, and it is worth noticing:

```
collect  ->  filter to the problems  ->  report  ->  (optionally) fix
```

The collect step is almost always a single dbatools command against `$Targets`.
The value is in the filtering — knowing which conditions matter. That knowledge
is the DBA part; PowerShell is just how you apply it to forty servers instead of
one.

## Requirements

```powershell
Install-Module dbatools -Scope CurrentUser
```

Written and tested against **dbatools 2.8.3**. Command and property names do
change between major versions — if something returns nothing, check with
`Get-Command <name>` and `Get-Member`.
