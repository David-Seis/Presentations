# Intro to PowerShell Automation for the SQL Server DBA

Scripts, demos and a self-contained lab from the session.
**SQL Saturday Boston — 3 October 2026 — David Seis, Straight Path IT Solutions**

---

## Start here

```powershell
cd "_Setup"
.\1 - Deploy lab.ps1      # four SQL Server containers, 2017 / 2019 / 2022 / 2025
.\2 - Test lab.ps1        # 36 checks that everything works
```

You need Docker Desktop, PowerShell, and `Install-Module dbatools -Scope CurrentUser`.
Full instructions, including how to pre-pull the images before you travel, are in
[`_Setup/README.md`](_Setup/README.md).

Everything runs on your own machine against throwaway containers. Nothing touches
a real server, so break whatever you like.

---

## The session

The talk is built around one idea: PowerShell does not make any single task
faster. It multiplies.

```
total time  =  minutes per server  ×  servers  ×  times per year  +  cost of errors
```

Four acts, one per multiplier.

### [1 · Once](1%20-%20Once/) — do it once, by hand

Commands, arguments, variables, piping, modules — taught while building one real
thing against one server. By the end you have a database report you would
actually run.

### [2 · Everywhere](2%20-%20Everywhere/) — × servers

The turn. `1 - One line, four servers.ps1` re-runs the Act 1 script with `$Targets`
holding four servers instead of one. No loop, no rewrite — dbatools takes arrays.

Then the same idea gets serious: fleet inventory, a backup gap sweep, a complete
maintenance standard rolled out to every server in one execution, and then -- six
months of drift later -- the job audit that finds it and the fix that puts every
server back on the standard at once.

### [3 · Forever](3%20-%20Forever/) — × times per year

A CSV tells you what is true now; a table tells you what *changed*. Collect into a
database, then schedule it so it keeps happening without you.

### [4 · Proven](4%20-%20Proven/) — cost of errors

Restore-test every backup and verify the maintenance actually ran. This act is
different from the others: most shops do not do restore testing slowly, they do
not do it at all, because by hand it is half a day per server. Automation did not
speed it up — it made it *exist*.

`3 - The scoreboard.ps1` generates the closing numbers live.

---

## After the session

### [`_Toolbox/`](_Toolbox/) — the part you actually take home

Fifteen scripts across ten categories: security audits, backup chain
analysis, config drift sweeps, patch and end-of-support reporting, capacity,
performance triage, dev refreshes, instance migration.

Read-only by default: anything that changes state is commented out, carries
`-WhatIf`, or runs as a dry run until you set `$DryRun = $false` at the top. Start
with `5 - Configuration and Drift\Best practice sweep.ps1` — it is fast, it is safe,
and it will find something.

### [`_Bonus/`](_Bonus/)

Real automations that did not fit the session's argument — silent SSMS installs,
one-off job schedules, plain backup and restore examples.

---

## How the scripts are wired

Every script begins with:

```powershell
. "$PSScriptRoot\..\_Setup\Environment.ps1"
```

That single file is the only machine-specific thing in the repo. It provides:

| | |
|---|---|
| `$Targets` | all four lab servers — the Act 2 fan-out list |
| `$OneTarget` | just the first one, for Act 1 |
| `@Lab` | credential splat for the containers |
| `$OutputPath` | where CSVs and reports land |
| `$LabDatabases` | the sample databases |
| `$LabSeedPlan` | which server gets which backups and CHECKDBs — the story the demos tell |
| `$SessionScripts` | this folder, for demos that need a path to a file beside them |

**To use these against your own servers:** edit `$Targets` in
`_Setup/Environment.ps1` and drop the `@Lab` from the commands — with Windows
authentication you do not need a credential. Scripts that work between two servers
(restore, refresh, migrate) have their own `$Source` / `$Destination` at the top;
set those too.

**Running a few lines at a time (F8):** `$PSScriptRoot` is only set when a whole
file runs, so the first line of every script does nothing useful from a selection.
Run `_Setup\2 - Test lab.ps1` once first — it loads the environment into the
terminal — and everything after that works line by line.

---

## The lab disagrees with itself on purpose

Four healthy identical servers make for a boring demo, so the deploy script seeds
uneven state:

| | backups | CHECKDB |
|---|---|---|
| **2017** | none at all | never run |
| **2019** | `Sales` only | never run |
| **2022** | all three, healthy | run |
| **2025** | all three, but `Sales` is `COPY_ONLY` | run |

That last row is the interesting one. A copy-only backup does not take part in the
backup chain, so 2025 looks fully protected in any inventory query and is not. In
Act 4 the restore test does not fail it — it silently leaves it out, and the script
has to go looking for what is missing. That is the argument for the whole act.

`_Setup\2 - Test lab.ps1` checks this seeded state is still intact before you
present, and `_Setup\3 - Reset lab.ps1` puts it back after a rehearsal.

---

## Resources

- [dbatools](https://dbatools.io/commands/) — 700+ commands, free and open source
- [Ola Hallengren's Maintenance Solution](https://ola.hallengren.com/)
- [First Responder Kit](https://www.brentozar.com/first-aid/)
- [Straight Path blog](https://straightpathsql.com/blog/) · [David's posts](https://straightpathsql.com/archives/author/davidseis/)
- [One-click Ola rollout](https://straightpathsql.com/archives/2023/01/ola-maintenance-from-a-jr-dba/)

Questions afterwards: [david.seis@straightpathsql.com](mailto:david.seis@straightpathsql.com)
· [LinkedIn](https://www.linkedin.com/in/davidseis/)

---

*Tested end to end against dbatools 2.7.6 and PowerShell 7.6 on 2 October 2026. If a
command returns nothing unexpectedly, check `Get-Command` and `Get-Member` — property
names do shift between major versions.*
