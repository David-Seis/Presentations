---
marp: true
theme: straightpath
paginate: true
footer: 'SQL Saturday Boston · 2026-10-03 · David Seis'
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: '' -->

###### SQL Saturday · Boston · October 3, 2026

# Intro to PowerShell Automation for the SQL Server DBA

**David Seis** · DBA / Developer
Straight Path IT Solutions, LLC.

<!--
60 minutes. Most of it is in the terminal, not on these slides.
Saturday morning: start Docker, run "_Setup\3 - Reset lab.ps1" (undoes any rehearsal and
re-seeds fresh backups), then "_Setup\2 - Test lab.ps1". All 36 checks green - leave it up.
If a Story check is red, run "_Setup\1 - Deploy lab.ps1 -Force" (about 3 minutes).
Test lab also loads the lab variables into the terminal, so F8 works from then on -
just do not F8 the first line of a script; $PSScriptRoot is empty for a selection.
Budget: intro 5, Act 1 12, Act 2 18, Act 3 6, Act 4 12, Q&A 7.
-->

---

###### The problem

# Our data estates are growing. Our teams are not.

- More instances, more versions, more places they live
- The same (or less) finite number of DBAs looking after them
- Clicking through SSMS four times does not scale to forty

> If you only do a thing once, do it by hand. If you will do it again, script it.

<!--
Two minutes, maximum. Do not sell PowerShell yet - just land the arithmetic.
Show of hands: who looks after more than 10 instances? More than 50?
-->

---

###### The idea

# PowerShell does not make one task faster. It multiplies.

```text
total time  =  minutes per server  ×  servers  ×  times per year  +  cost of errors
```

- **Once** — get the minutes down, on one server
- **Everywhere** — take the *servers* term out
- **Forever** — take the *times per year* term out
- **Proven** — go after the *cost of errors*

<!--
One minute. This is the whole talk in one line - each act removes one term.
Come back to it at the scoreboard.
-->

---

<!-- _class: two-col -->

###### Agenda

# Four acts

- **Once** — do the task once, by hand
  - A command returns objects, not text
- **Everywhere** — the same work, whole estate
  - One variable is the only thing that changes
- **Forever** — stop being the trigger
  - Collect it, keep it, schedule it
- **Proven** — prove it actually worked
  - The part nobody was doing at all

<!--
These are the four Scripts folders, in order. Say that out loud - people will be
looking at the repo later and the mapping should be obvious.
If you run short, Act 3 compresses. Act 4 does not - it is the whole argument.
Running total to aim for: Act 1 done by 0:17, Act 2 by 0:35, Act 3 by 0:41, Act 4 by 0:53.
-->

---

###### Follow along

# Four servers on your laptop

| Container | Version | Connect with |
|---|---|---|
| `sqlsat2017` | SQL Server 2017 | `localhost,14317` |
| `sqlsat2019` | SQL Server 2019 | `localhost,14319` |
| `sqlsat2022` | SQL Server 2022 | `localhost,14322` |
| `sqlsat2025` | SQL Server 2025 | `localhost,14325` |

Docker Desktop · PowerShell 7 · `Install-Module dbatools` · ~12 GB disk

**Pull the images at home** — conference wifi will not thank you.

<!--
Say this now, not at the end, so anyone who wants to follow along has time.
Everything is in _Setup: 1 - Deploy lab, 2 - Test lab, 3 - Reset lab.
Reset undoes every demo, so nothing here is one-way.
-->

---

<!-- _class: lead -->

###### Act 1

# Once

- Your first command — `Verb-Noun`, and why it returns objects
- Arguments — `-Database Sales` is `@Database = 'Sales'`
- Variables — the seam where one server becomes forty
- Piping — `Where`, `Sort`, `Select`, in that order
- Modules — where `Get-DbaDatabase` actually came from

<!--
Demo: Scripts\1 - Once\, files 1 to 5 in order. Budget 12 minutes.
Piping is the one that has to land. Teach the verbs on the actor list first -
nobody has to think about strings - then run the identical shape against SQL.
Modules: show the command count and one Get-Command search, then move on.
-->

---

###### Once

# A command returns objects, not text

```powershell
# "Which databases are in FULL recovery but have never had a log backup?"
Get-DbaDatabase -SqlInstance $Target -ExcludeSystem @Lab |
    Where-Object { $_.RecoveryModel -eq 'Full' -and
                   $_.LastLogBackup -lt [datetime]'1900-01-01' } |
    Select-Object Name, RecoveryModel, LastFullBackup, LastLogBackup
```

*No parsing. No string handling. `Where-Object` is `WHERE`, `Sort-Object` is
`ORDER BY`, `Select-Object` is `SELECT` — you already know this query.*

<!--
That output is a production incident waiting to happen, and it is one line.
Pause here. This is the slide the rest of the hour rests on.
Say the gotcha out loud: SQL Server says "never" with 1 January 0001, not with null -
so "-not $_.LastLogBackup" looks right and silently returns nothing. Ask about the date.
-->


---

<!-- _class: lead -->

###### Act 2

# Everywhere

- One line, four servers — the whole session in one script
- Fleet inventory — what do we actually have?
- Fleet backup gap sweep — is everything backed up?
- Fleet maintenance rollout — the half-day-per-server one
- Fleet job audit — six months later, four different answers
- Fleet job fix — the same correction, everywhere at once

<!--
Demo: Scripts\2 - Everywhere\, files 1 to 6. Budget 18 minutes.
4, 5 and 6 CHANGE things. 3 - Reset lab.ps1 undoes all of it - say so before you run
them, it visibly relaxes the room.
The rollout takes about 3 minutes. Start it, then talk over it: what Ola is, why the
jobs get renamed, why the alerts matter. Do not stand in silence watching green text.
The audit opens with a LAB ONLY block that fakes six months of drift - say so.
If you are behind, run 1, 3, 4 and 5, and talk through 2 and 6.
-->

---

###### Everywhere

# One variable is the entire trick

```powershell
# Act 1 ended here
$Target  = 'localhost,14317'

# Change one line
$Targets = 'localhost,14317','localhost,14319','localhost,14322','localhost,14325'

Get-DbaDatabase -SqlInstance $Targets -ExcludeSystem @Lab |
    Select-Object SqlInstance, Name, RecoveryModel, SizeMB, LastFullBackup |
    Sort-Object   SqlInstance, Name
```

*No loop. No `ForEach`. No rewrite — `-SqlInstance` takes an array.*

<!--
Then prove it rather than asserting it:
    (Get-Command Get-DbaDatabase).Parameters['SqlInstance'].ParameterType.Name
DbaInstanceParameter[] - an array. Most of dbatools is built this way.
Say where the real list comes from: Get-DbaRegServer against a CMS, or a text file.
Nobody types four server names in production.
-->

---

###### Everywhere

# The fleet disagrees on purpose

- **2017** — no backups at all
- **2019** — `Sales` only
- **2022** — everything, healthy
- **2025** — everything, but `Sales` is `COPY_ONLY`

*The last one is the interesting one. It looks like a real full backup until you
check `LastFullBackupIsCopyOnly`.*

<!--
Seeded this way by 1 - Deploy lab.ps1 so the sweep finds something real.
The 2025 row is the one to dwell on - that is the failure a human clicking through
SSMS signs off on, every time.
-->

---

<!-- _class: lead -->

###### Act 3

# Forever

- Load data to a database — keep what you collected
- Scheduled report — Task Scheduler, and the report nobody has to remember to run

<!--
Demo: Scripts\3 - Forever\. Budget 6 minutes.
Fan-out multiplies by servers. Scheduling multiplies by time. That is the framing.
The scheduled report runs against the lab and needs no admin rights. Registering and
running it takes about 30 seconds - if time is short, show the generated script and
the task in Task Scheduler and skip the run. Email is in the generated script,
commented out: say "one more line and it lands in your inbox".
-->

---

###### Forever

# A fact, or a decision

> A CSV tells you what is true right now.
> A table tells you what **changed**.

- "Sales is 40 GB" is a fact
- "Sales grew 12 GB this month" is a decision

You cannot get the second one without having kept the first.

<!--
This is why loading to a table matters and a folder of CSVs does not.
Nobody trends a folder of CSVs. Everybody means to.
-->

---

<!-- _class: lead -->

###### Act 4

# Proven

- Test the backups — restore, `CHECKDB`, drop, repeat
- Prove maintenance ran — deploying is not the same as working
- The scoreboard — measured live, on the servers you just built

<!--
Demo: Scripts\4 - Proven\. Budget 12 minutes.
Everything before this made you faster. This act is different in kind - it is work
most shops are not doing at all, at any speed.
The restore test takes about a minute across the fleet - talk over it.
-->

---

###### Proven

# A backup you have never restored is a hope

- Most shops do not do restore testing **badly** — they do not do it **at all**
- By hand it is most of a day per server, so nobody has the days
- `Test-DbaLastBackup` restores it, runs `CHECKDB`, and drops it

> Rolling maintenance out is not the same as it working. Act 2 deployed it.
> This closes the loop.

<!--
The reveal: count the 2025 rows. Sales is not there - not failed, MISSING. Its only full
backup is COPY_ONLY, so the restore test silently leaves it out. The script's "just the
failures" table adds it back as NOT TESTED. That is the 2025 row from Act 2, closed.
Then "Prove maintenance ran": if a quarter-hour has passed since the rollout, the log
backup job shows Failed on every server (it points at a share that does not exist).
Run it WITHOUT -Destination in this lab. dbatools requires a UNC share for
-Destination and a container path does not qualify - it silently skips every
database. On real servers with a UNC backup share, -Destination is the better pattern.
-->

---

###### Proven

# The scoreboard

Run `4 - Proven\3 - The scoreboard.ps1` — every number measured in this room,
on the servers you just watched get built.

| Task | Script | By hand |
|---|---|---|
| Inventory the estate | seconds | 6 min × 4 |
| Check every backup | seconds | 10 min × 4 |
| Verify maintenance ran | seconds | 15 min × 4 |
| Restore-test the backups | seconds | **never** |

<!--
Do NOT read the numbers off this slide - run the script and read them off the
terminal. The point is that they are measured, not asserted.
Then point at the last row and land the close: the first rows are about doing your
job faster. The last one is about doing a part of your job that, without this, was
never going to happen at all. (Last rehearsal: about 40 seconds of script against
roughly 2 hours of hand work.)
-->

---

<!-- _class: two-col -->

###### Take it home

# The toolbox — 15 scripts

- Discovery and inventory
- Backups and recovery
- Integrity and corruption
- Security and access
- Configuration and drift
- Agent jobs
- Capacity and growth
- Performance
- Migration and refresh
- Windows and server

<!--
Scripts\_Toolbox\ - ten folders, fifteen scripts, none of them part of the talk.
Each one is a real question a DBA gets asked, already answered.
This is the slide people photograph. Leave it up while you take the first question.
-->

---

<!-- _class: lead -->

![bg right:31% contain](assets/qr-code.png)

###### Thank you

# Questions?

**David Seis** — DBA / Developer, Straight Path IT Solutions

[david.seis@straightpathsql.com](mailto:david.seis@straightpathsql.com)
[linkedin.com/in/davidseis](https://www.linkedin.com/in/davidseis)

Slides, scripts, demos and resources:
**https://bit.ly/4m05kBy**

Everything here is free:
`Install-Module dbatools -Scope CurrentUser`

<!--
Leave this up for the whole Q&A. Read the short URL out loud twice.
The QR code and the short URL are the same link: it opens the session's ResourceList,
which links to this event's folder.
-->
