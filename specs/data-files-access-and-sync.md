# Data Files: people, protection and one database on many computers

Status: design. The owner's choices of 2026-10-22 are in (the last section),
with the owner's later change the same day: database engines, not Office
computers, hold the records when a database is shared.
Owner's direction, 2026-10-22: "the data files , user should be able password
protect tables and other items so the admin and workers can see things
differently. the feature will need better designing to make the system more
usable in office environments and deploy it over multiple computers syncing
each other in real time."

## What Data Files is today

- A database is one SQLite file (`.rbase`) opened by `node:sqlite` on the
  computer that has it (`packages/database/src/base.js`). Its design lives in
  its own `rutba_*` tables beside the records.
- Anyone who has the file sees and changes everything in it. There are no
  people, roles or passwords, and nothing keeps two computers in step.
- So the two asks hang together: a password on a table means little while
  every worker's computer holds the whole file, and sharing between computers
  is where the "who sees what" has to be enforced.

## The idea in one paragraph

A protected database has **people** and **roles**. The owner of the database
(the admin) decides, per role, what each table, query, form, report and print
template allows: hidden, read only, add, or change and delete; for a table,
optionally only its own records ("records they entered") and only some fields
(a worker sees a product's price but not its cost). The database is **served**
by one computer, set up as its server by the admin. The other computers are
set up as its clients. Every computer runs its own small server and finds
the others by name or address, and each end of a connection knows which
computer and person it is talking to. A client gets only what its person's
role allows, live: a record one person saves appears on everyone else's
screen at once. Because
a worker's computer is never sent what it may not see, the protection is
real, not a lock drawn over data that is on the disk anyway.

## People and roles

- **Turning it on.** Database > Protect this database. The person turning it
  on becomes its admin and sets a password. From then on, opening the
  database asks who you are.
- **People.** The admin adds people by name, each with a password (or, if
  the owner chooses, by their Rutba account: see question 1). A person can
  change their own password; the admin can reset anyone's.
- **Roles.** Admin (everything, including the design), and roles the admin
  makes: for a shop, say, Manager, Cashier, Stock. A person has one role.
  Ready-made databases and the sample businesses come with sensible roles
  already, so a shop owner starts from Owner, Manager, Cashier.
- **What a role allows, per item.**
  - Table: hidden / read / add / change / delete; only own records; fields
    hidden or read only.
  - Query, form, report, print template: hidden or shown. A query a role
    can run reads only what that role may read: the protection is applied
    beneath the query, so no query or expression can step around it.
  - Design (tables, queries, forms, reports, templates, relationships):
    admin only, or given to a role.
- **One place to see it.** Database > People and roles: a grid of roles
  against items, each cell a choice, with "See as" to open the database as a
  role would see it before anyone relies on it.
- **A trail.** Each change records who made it and when, kept with the
  record's history (`rutba_steps` today keeps design steps only).

## Protection that holds

- **On the server's disk.** The admin may turn on encryption on disk (the
  owner: the admin's option). Encrypted, the file copied to a USB stick opens
  for nobody without a password. Left off, the roles hold inside Rutba
  Office, and Database > People and roles says plainly that anyone who copies
  the file can read it with another program.
- **On a client.** It holds no copy of the database: it asks the server and
  gets the rows and fields its role may see. When the server is unreachable
  it says so and waits for it; it does not fall back to a stale copy.
- **Forgotten passwords.** With encryption on, the admin's password cannot
  be recovered by Rutba (nobody at Rutba holds the key). Turning encryption
  on makes the admin save a recovery key, printed or kept as a file, and says
  plainly that without both, the database cannot be opened.

## Sharing through a database engine (replaces servers and clients)

The owner, 2026-10-22, changed the way a database is shared: "as far the
file distribution is concerned i have changed my mind and now we will build
data sync support with database engines and other sources  and with live
options and making database engine as  master record holder. if some one
needs distribution they can setup a database engine centrally". Office
computers no longer serve each other; the section that described that is
replaced by this one.

- **The engine holds the records.** A Data Files database can be connected
  to a database engine (PostgreSQL, MySQL or MariaDB, Microsoft SQL Server,
  to start). The engine is the master: what it holds is the truth, and every
  computer that needs the records connects to it. An office that wants many
  computers on one database sets an engine up centrally (on a server of its
  own, or a hosted one) and points each copy of Data Files at it.
- **Live.** Tables linked live are read from and written to the engine
  directly: a record one person saves is in the engine at once, and the
  others see it as their view refreshes (or at once, where the engine can
  say what changed, such as PostgreSQL's LISTEN and NOTIFY).
- **Synced.** A table can instead be kept as a copy in the .rbase file and
  synced with the engine: changes made here go to the engine, the engine's
  come back, and when both changed the same record the engine's version
  wins and the person is shown what they had. A copy can be worked on while
  the engine is out of reach.
- **Other sources.** Beyond engines, a table can be fed from another source
  (a spreadsheet or CSV file at a path or address, a Google Sheet, another
  Data Files database, a web API returning JSON), read on a schedule or on
  demand, the source being the master in the same way.
- **Office's side stays the same.** Queries, forms, reports and print
  templates work on linked and synced tables as on local ones; the design
  of a linked table is the engine's, shown read only.
- **Who may do what.** With an engine as master, the engine's own accounts
  and grants are what protect the records; Data Files signs in to the
  engine as the person (or as the database's connection with the person's
  role applied, see the questions below). The roles of step 1 still narrow
  what a person sees in the window.
- **Connection details** (address, database, account) are kept with the
  .rbase; the password in the operating system's credential store, never in
  the file.

## Built in steps, each one shippable

Step 1 is built on Office main for 2.17 (2026-10-22): engine 13d5057
(`packages/database/src/access.js`, temp views per role, checked writes to
`main.`, the trail), window 073f3c8 (sign-in, Protect this database, People
and roles, See as, Change my password), mail merge 36d00b4. Rutba accounts
as people come with step 3.

1. **People, roles and per-item permissions** inside one database on one
   computer: sign-in on open, the People and roles grid, See as, the trail.
   Useful at once on a shared office PC.
2. **Encryption on disk** as the admin's option, the recovery key, and
   change of password.
(Step 3 for PostgreSQL is built on Office main for 2.17, 2026-10-22: engine
and service 657c4cb, window 79a0df6, live re-reading every 15 seconds
d07fef2. Records are read into a TEMP table per window, never the file;
writes go to the engine by primary key; relationships with linked tables
join queries without a foreign key. MySQL or MariaDB and SQL Server are
listed as coming: they need test servers first.)

3. **A table linked live to a database engine**: Connect to an engine
   (PostgreSQL, MySQL or MariaDB, SQL Server), link its tables, read and
   write them in place; the engine's design shown read only.
4. **Synced copies**: a table kept in the file and synced with the engine,
   the engine winning a clash, worked on while the engine is out of reach.
5. **Other sources**: spreadsheets and CSV files at a path or address,
   Google Sheets, other Data Files databases, and web APIs returning JSON,
   read on a schedule or on demand.

(Servers and clients between Office computers, and the route through Talk's
relays, were the plan until the owner's change of 2026-10-22 above; they are
not built.)

Each step has its engine tests and window checks like the rest of Data Files,
and the samples get roles in step 1.

## The owner's choices (2026-10-22)

1. **Who the people are: both.** Names and passwords kept in the database,
   made by its admin, first; Rutba accounts (signed in as for Talk) when the
   database is shared between computers. (Answer: "Both (Recommended)".)
2. **Encryption on disk: the admin's option.** (Answer: "Admin's option".)
3. **Offline and how computers connect.** The owner's words: "fully master
   master setup. computer sync with each other via mutual communication setup
   via name or Ip lookup and  other side know knows who is it connected with
   and run their own tcp or http server." Then, on where the database runs:
   "may be its not master master , we should go with servers and clients and
   they need admin setup". Read together, as this design does: servers and
   clients set up by an admin; each computer runs its own server, is found by
   name or address, and knows who is on the other end. Offline copies on
   clients are not part of it.
4. **Where it runs:** on the server the admin sets up, as above.

Open, for the owner when step 3 is built: whether a client may keep working
on its own records while the server is unreachable and send them when it is
back (a narrow form of what the first answer described), or only wait.

**Superseded the same day.** Choices 3 and 4 (servers and clients set up by
an admin, each computer serving the others) gave way to the owner's change
quoted in "Sharing through a database engine": the engine is the master
record holder, with live and synced options, and distribution is an engine
set up centrally. Choices 1 and 2 stand.

**The owner's choices for engines (2026-10-22, later the same day):**

1. **Engines first:** PostgreSQL, MySQL or MariaDB, and Microsoft SQL Server
   (answers "PostgreSQL (Recommended)", "MySQL / MariaDB (Recommended)",
   "Microsoft SQL Server").
2. **Live first** ("Live first (Recommended)"): tables read and written
   straight in the engine; synced copies follow.
3. **Who decides what each person may do with an engine:** open. The owner:
   "lets decide later but we will not change the data  file behaviour". So
   a database that is not linked to an engine, and the protection of step 1,
   work exactly as they do now; nothing about the .rbase file changes for
   this.
4. **Other sources, all four:** spreadsheets and CSV files, Google Sheets,
   other Data Files databases, and web APIs returning JSON.
