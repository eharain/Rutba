# Data Files: people, protection and one database on many computers

Status: design. The owner's choices of 2026-10-22 are in (the last section);
the sections above are written to them.
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

## One database on many computers: servers and clients

- **Set up by the admin.** On the computer that has the database: Database >
  Serve this database. That computer becomes its server. The admin then adds
  each client computer, by its name on the network or its address, and says
  which people may use it. Nothing joins on its own.
- **Every computer runs its own server.** Rutba Office on each computer
  listens on the network (a TCP or HTTP port the admin can change), so the
  server can reach a client to tell it what changed and a client can reach
  the server, whichever side starts.
- **Found by name or address.** Computers on the same network are found by
  name; any computer can be given by its address (IP and port) instead.
- **Each side knows who it is talking to.** When the admin adds a client,
  the two computers exchange keys (shown as a short code on both screens to
  compare, the way a phone pairs). From then on every connection is encrypted
  and both ends check the other's key, so a computer that was not set up,
  or one pretending to be the server, is refused. The server shows which
  computers are connected and who is signed in on each; a client shows which
  server it is on.
- **Live.** Every save goes to the server, which applies it under the
  person's role and tells every connected client what changed, so open
  tables, forms and reports update in place. Two people changing the same
  record: the second sees that it changed under them and what the first
  person saved, and chooses.
- **Not master and master.** There is one server for a database and every
  change goes through it. Two computers each changing their own copy and
  merging later (master to master) is not the design; the owner weighed it
  and chose servers and clients set up by an admin.
- **Across the internet.** A client away from the office reaches the server
  by its address where the network allows it. Where it does not, the
  connection can go through Rutba Talk's introducer and relays the way calls
  do, still encrypted end to end so Rutba cannot read it, following
  D-2026-10-20-11 (a participant's computer first, Rutba servers only when
  neither can carry it). This is a later step.

## Built in steps, each one shippable

1. **People, roles and per-item permissions** inside one database on one
   computer: sign-in on open, the People and roles grid, See as, the trail.
   Useful at once on a shared office PC.
2. **Encryption on disk** as the admin's option, the recovery key, and
   change of password.
3. **Servers and clients on the office network**: Serve this database, adding
   clients by name or address, the key exchange, live updates, the
   same-record rule. Rutba accounts as people, beside names in the database.
4. **Across the internet**: by address, and through Talk's introducer and
   relays where a direct connection cannot be made.

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
