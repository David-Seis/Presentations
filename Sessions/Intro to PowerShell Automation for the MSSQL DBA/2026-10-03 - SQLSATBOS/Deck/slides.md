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
Before the room fills: run "_Setup\2 - Test lab.ps1" and leave the green output up.
All four containers must answer before you start.
-->

---

###### The problem

# Our data estates are growing. Our teams are not.

- More instances, more versions, more places they live
- The same finite number of DBAs looking after them
- Clicking through SSMS four times does not scale to forty

> If you only do a thing once, do it by hand. If you will do it again, script it.

<!--
Two minutes, maximum. Do not sell PowerShell yet - just land the arithmetic.
Show of hands: who looks after more than 10 instances? More than 50?
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
Demo: Scripts\1 - Once\, files 1 to 5 in order.
Piping is the one that has to land. Teach the verbs on the actor list first -
nobody has to think about strings - then run the identical shape against SQL.
-->

---

###### Once

# A command returns objects, not text

```powershell
# "Which databases are in FULL recovery but have never had a log backup?"
Get-DbaDatabase -SqlInstance $Target -ExcludeSystem @Lab |
    Where-Object { $_.RecoveryModel -eq 'Full' -and -not $_.LastLogBackup } |
    Select-Object Name, RecoveryModel, LastFullBackup, LastLogBackup
```

*No parsing. No string handling. `Where-Object` is `WHERE`, `Sort-Object` is
`ORDER BY`, `Select-Object` is `SELECT` — you already know this query.*

<!--
That output is a production incident waiting to happen, and it is one line.
Pause here. This is the slide the rest of the hour rests on.
-->

---

<!-- _class: lead -->

###### Act 2

# Everywhere

- One line, four servers — the whole session in one script
- Fleet inventory — what do we actually have?
- Fleet backup gap sweep — is everything backed up?
- Fleet job audit — four servers, four different answers
- Fleet job fix — the same correction, everywhere at once
- Fleet maintenance rollout — the half-day-per-server one

<!--
Demo: Scripts\2 - Everywhere\, files 1 to 6.
5 and 6 CHANGE things. 3 - Reset lab.ps1 undoes both - say so before you run them,
it visibly relaxes the room.
-->

---

###### Everywhere

# One variable is the entire trick

```powershell
# Act 1 ended here
$Target  = 'localhost,14322'

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
- Scheduled report — Task Scheduler, and the email nobody has to remember to send

<!--
Demo: Scripts\3 - Forever\.
Fan-out multiplies by servers. Scheduling multiplies by time. That is the framing.
The scheduled report needs SendGrid + a service account - if the room is cold on
time, talk it through instead of running it.
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
Demo: Scripts\4 - Proven\.
Everything before this made you faster. This act is different in kind - it is work
most shops are not doing at all, at any speed.
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
never going to happen at all.
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
**https://bit.ly/sp-powershell** ← *(repoint this before the 3rd)*

Everything here is free: `Install-Module dbatools -Scope CurrentUser`

<!--
Leave this up for the whole Q&A. Read the short URL out loud twice.
-->
