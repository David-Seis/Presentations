# Demo lab setup

Everything in this session runs against four SQL Server containers on one machine.
Nothing touches a real server, so you can follow along on your own laptop and break
whatever you like.

## What you need

| | |
|---|---|
| Docker Desktop | Linux containers mode (the default on Windows) |
| PowerShell | 7+ recommended, 5.1 works |
| dbatools | `Install-Module dbatools -Scope CurrentUser` |
| Disk | ~12 GB for the four images |
| RAM | ~10 GB free (4 containers × 2 GB, plus headroom) |

**Pull the images before you travel.** The four images are roughly 9 GB together and
conference wifi will not thank you. Run this at home:

```powershell
'2017','2019','2022','2025' | ForEach-Object {
    docker pull "mcr.microsoft.com/mssql/server:$_-latest"
}
```

Everything else about the lab works offline.

## Running it

```powershell
cd "_Setup"

.\1 - Deploy lab.ps1      # build the fleet          (2-4 min)
.\2 - Test lab.ps1        # verify it                (~30 sec)
.\3 - Reset lab.ps1       # undo the demos, re-seed  (~1 min)
.\3 - Reset lab.ps1 -Destroy   # remove the containers
```

`1 - Deploy lab.ps1` is safe to re-run — it leaves existing containers alone and
re-takes the seeded backups, which freshens their dates. Add `-Force` to tear down
and rebuild.

Always run `2 - Test lab.ps1` before presenting. It runs 36 checks — Docker, memory,
images, containers, SQL connectivity, SQL Agent, the sample databases, whether every
version can write to the shared volume, whether the containers can read each other's
backups, and whether the **story** is still intact: each server still has exactly the
backups and CHECKDB history it was seeded with, and the seeded backups are less than
20 hours old (the Act 2 sweep flags anything older than a day). It tells you exactly
what is broken and leaves the demo data alone.

Between rehearsals, `3 - Reset lab.ps1` removes everything the demos create — jobs,
alerts, the admin and repository databases, the scheduled task, generated files —
then re-seeds. The one thing it cannot undo is a CHECKDB on 2017 or 2019 (SQL Server
keeps that date inside the database); the test will tell you, and
`1 - Deploy lab.ps1 -Force` is the cure.

## What you get

Four instances, each with `Sales`, `Inventory` and `Reporting` databases:

| Container | Version | Connect with |
|---|---|---|
| `sqlsat2017` | SQL Server 2017 | `localhost,14317` |
| `sqlsat2019` | SQL Server 2019 | `localhost,14319` |
| `sqlsat2022` | SQL Server 2022 | `localhost,14322` |
| `sqlsat2025` | SQL Server 2025 | `localhost,14325` |

Login is `sa` with the password in `Environment.ps1`. It is a throwaway password in a
public repo — never reuse it anywhere real.

Ports deliberately avoid 1433 so the lab cannot collide with a SQL Server you already
have installed.

### The backup location is a Docker volume, not a folder

All four containers mount the named volume `sqlsatlab-backup` at `/var/opt/mssql/backup`,
so a backup taken on one instance is visible to the others.

It is a named volume rather than a Windows folder for a specific reason: **SQL Server
2025 cannot write backups to a Docker Desktop bind mount.** It fails with
`Operating system error 31 ... DiskChangeFileSize`, because Docker's Windows filesystem
shim does not implement the file-sizing call 2025 makes. 2017 through 2022 are fine on a
bind mount; 2025 is not. A named volume lives inside the Linux VM and works for all four.

To look inside it:

```powershell
docker exec sqlsat2022 ls -la /var/opt/mssql/backup
```

Two more permission details the deploy script handles for you:

- A brand-new named volume is owned by `root`, but SQL runs as uid 10001, so the deploy
  script `chmod 777`s the directory once. Without it every backup fails with
  `Operating system error 5(Access is denied.)`.
- The images disagree about groups — 2017 runs as root, 2019 is `10001:0`, and 2022/2025
  are `10001:10001`. SQL writes backups mode `0640` with no world-read bit, so nothing
  could read 2017's files. The newer containers get `--group-add 0` to fix this. It has
  to be a *supplementary* group: forcing `--user 10001:0` stops 2022+ from booting,
  because they need gid 10001 to create `/.system`.

Remember you can restore *up* a version but never *down*: a 2022 backup restores onto
2025, not onto 2019.

### A note on Test-DbaLastBackup

`Test-DbaLastBackup` restores the last backup, runs `DBCC CHECKDB`, and drops it again.
In this lab, run it **without** `-Destination`:

```powershell
Test-DbaLastBackup -SqlInstance $Targets -SqlCredential $LabCredential -Prefix 'resttest_'
```

If you pass `-Destination`, dbatools requires the backup path to be a UNC share (`\\...`),
http or s3 — otherwise it reports *"Restore not located on shared location"* and skips
every database. A container path like `/var/opt/mssql/backup/...` does not qualify, even
though the containers genuinely do share it. On real servers with a UNC backup share,
`-Destination` works normally and is the better pattern.

### The servers disagree on purpose

Backup coverage is seeded unevenly so the fleet health sweep finds real problems
(the plan is `$LabSeedPlan` in `Environment.ps1`):

- **2017** — no backups at all, never CHECKDB'd
- **2019** — `Sales` only, never CHECKDB'd
- **2022** — everything, healthy
- **2025** — everything, but `Sales` is `COPY_ONLY`, which looks like a real full
  backup until you check the `LastFullBackupIsCopyOnly` column

### The clocks are in UTC

The containers run on UTC, so backup and job times in the output are UTC too — on
an Eastern laptop, four hours ahead of the clock on the wall. Nothing depends on it;
it is just worth knowing before someone in the room asks why a backup finished in
the future.

Agent schedules run on that clock too, and one of them matters on a Saturday: the
rollout schedules the user-database integrity check **weekly, Saturday 20:00 UTC** --
4 PM Eastern. If the rollout's jobs are still in place at that moment, it CHECKDBs
2017 and 2019, and Act 4 no longer finds them unchecked. Reset before then, and if it
has already fired, `1 - Deploy lab.ps1 -Force` is the cure.

## Changing things

`Environment.ps1` is the only machine-specific file. Every demo script dot-sources it:

```powershell
. "$PSScriptRoot\..\_Setup\Environment.ps1"
```

Edit it to move the lab folder, change ports, lower the per-container memory on a small
laptop, or point `$Targets` at your own servers instead of containers.

## When something goes wrong

**A container will not start.** `docker logs sqlsat2019`. Almost always low memory or a
port already in use. Lower `$LabMemoryMB` in `Environment.ps1` and redeploy with `-Force`.

**"Gave up waiting for..."** SQL needs 10–60 seconds after the container starts, longer on
a cold cache. Re-run the deploy script; it will pick up where it left off.

**Login failures.** The password lives in `Environment.ps1` and must match what the
containers were built with. If you changed it after deploying, redeploy with `-Force`.

**Apple Silicon.** The `mssql/server` images are amd64 and run under emulation on M-series
Macs — slow, and 2022+ can be unreliable. The test harness warns you if it sees arm64.
