# Rutba Office: the plan for next week (2.17.2 tooling, 2.18.0)

Written 2026-10-23, after 2.17.1 was released. Nothing here is built before
next week (owner: "we will hold the 2.18 f untill next week", "just plan it
out no build until next week"). Decisions it follows: D-2026-10-23-01
(patch releases gated by what they change), -02 (nobody waits on Office
builds), -03 (2.18.0 holds synced copies and the other sources; no
encryption; SQL Server later).

## Part A. The gate and its checks (first, about a day)

None of this changes what a person sees, so it needs no release. It ships
in the next release that has an app change.

1. **A locked screen found before the run.** The gate looks for the lock
   screen (LogonUI) before it starts. Locked, it runs everything that does
   not need the screen and lists the real-screen checks (the computer's own
   clipboard, real input to the grid, the recorder's screen capture) as
   waiting for an unlocked screen, instead of failing them after an hour.
   A release still needs them passed before it goes on the record.
2. **The checks that fail when the PC is busy**, each made to wait for what
   it waits on, and its budget allowing for a busy machine. These failed
   beside the others in the three gates of 2026-10-23 and passed alone:
   - recorder live: the destination's stream and its reconnect
   - recorder: a take as long as its clip, the camera's take on the same clock
   - mail: big archives indexed to their last message; typed keys during indexing
   - ocr-pdf: Find on scanned pages, English and Urdu
   - sheets: dragging a range after =SUM(; the round trip's write
   - a11y-audit: Presentations' window and ribbon tabs
   - spelling: Word's right-click suggestions
   - video mp4: the 60-second export budget
   - the engine test "bodyDocument ... stays quick on a hostile message"
3. **The recorder's checks on a stand-in screen source**, so they no longer
   need the desktop. One real-screen capture check stays, in the machine
   lane.
4. **Scoped by design.** An app's change stays in that app's code, so a
   patch's gate checks one or two apps (about 25 minutes, not 75). A change
   to what every app shares (the title bar, the shell, office-ui) is made
   only when it must be, and then the gate runs in full.
5. **Overnight runs** take the keep-awake hold and start only with the
   screen unlocked.

## Part A2. Data Files rough edges the how-to scripts found (2026-10-23)

Found checking the Data Files how-to series, part 1, against 2.17.1. The
owner: fix next week (answer "Fix next week"); part 1 is filmed after them.

1. **UK dates on import.** A column written 12/04/2025 imports as text;
   only 2025-04-12 is read as a date. Read day-first dates as dates (a
   column with a day above 12 settles the order; otherwise day first, as
   the samples and the UK write them), and say in the import's summary
   how the dates were read.
2. **A type change refused in plain words.** Changing a column to Date
   when a value does not fit is refused with SQLite's "CHECK constraint
   failed: Joined". Say which record and value do not fit, and offer to
   clear them.
3. **A missing related record, in plain words.** A sale line pointing at
   product 99 is refused with "That record is related to others: it points
   at one that is not there, or others point at it." Say "Products has no
   record 99" when adding or changing, and which records point at one
   being deleted.
4. **Names in the datasheet.** Records shows a related field as its number
   (24); show the record's name, as forms and lists do, the number still
   what is stored and what is typed.
5. **Spreadsheets imported.** Import takes .xlsx and .ods (each sheet, or
   the sheet chosen), read by the engines Worksheets uses.
6. **The default in the new row.** The new-record row shows a field's
   default (1.50) where it now shows only its type.

Each with its engine tests and Data Files window checks. They go into
2.18.0 if it is next week's only release, or a 2.17.2 at the start of the
week (Data Files only, a gate of about 25 minutes) so the films can go on.

## Part B. Rutba Office 2.18.0: Data Files' synced copies and other sources

A minor release, so the full gate. Both steps of
`specs/data-files-access-and-sync.md` (4 and 5) in one release. The data
file's own behaviour does not change ("we will not change the data file
behaviour"): a database with no link, and the people and roles of 2.17,
work as they do now.

### B1. Synced copies

What a person gets: in Link to a database engine, a choice for each table,
**Live** (as 2.17) or **Keep a copy in this file**. A copy works with the
engine out of reach and catches up when it is back.

How it works:
- The records are kept in a real table of the file (not the TEMP table of a
  live link), so the database opens and works with no engine at all.
- `rutba_linked` gains a `mode` (`live` or `copy`). A new `rutba_sync` table
  keeps, for each record, the engine's key, a hash of the engine's version
  last seen, and whether it was changed, added or deleted here since.
- **Catching up**, on open, every 15 seconds while on screen (as live does)
  and on Sync now: changes made here are written to the engine by primary
  key first, then the engine's records are read and compared by key and hash.
- **A clash** (changed here and in the engine since the last catch-up): the
  engine wins, as the owner chose. The version from here is kept in
  `rutba_clashes` and shown ("2 of your changes were replaced by newer ones
  in the engine: see them"), so nothing is lost without a word.
- **Out of reach:** changes are kept and marked waiting. The table's bar
  says how many wait and since when; nothing is refused.
- A table with no primary key can be copied but not changed, as with live.
- Reading compares the whole table, as live does today; past about 100,000
  records, a field the engine updates on every change (an updated-at) can
  be chosen in the Link dialog to read only what changed.
- Switching a table between Live and Copy keeps its records.

Checks: engine tests against the local PostgreSQL and MySQL test databases
(`datafiles_` prefix): edits with the engine stopped, then caught up; a
clash, engine wins and the local version kept; deletes on either side; a
key-less table read only. A window check (`base-engine-copy`): link as a
copy, stop the engine, edit, start it, see the edit there.

### B2. Other sources

A source is linked like an engine (`rutba_links` with a new kind) and kept
as a copy in the file, refreshed on open, on a schedule chosen per source
(every 5, 15 or 60 minutes, or by hand) and on Refresh. Sources are read
only in 2.18; writing back, where a source allows it, comes later.

In this order:
1. **CSV and spreadsheet files** (.csv, .xlsx, .xls, .ods) at a path on this
   computer or a network share, or a web address: the sheet, the header row,
   and the types worked out as Import already does (`import.js`). Read
   again, its records are replaced; a changed set of columns updates the
   table's design and says so.
2. **Other Data Files databases**: a table or a query of another `.rbase`
   file, opened read only. A protected one asks who you are there, and its
   roles apply: you see what that person may see.
3. **Web APIs returning JSON**: an address, any headers (a key or token kept
   in the computer's protected store, as engine passwords are, never in the
   file), where the records are in the answer (for example `data.items`),
   and paging by a next link or a page number. Fields are found from the
   first records, nested ones flattened one level (`address.city`).
4. **Google Sheets**, last: a Google sign-in (PKCE and a loopback redirect,
   as Mail's Gmail sign-in in docs/OAUTH.md), then a spreadsheet and its
   sheet. Needs a Google client id with the Sheets read scope: the owner
   adds it to the Google Cloud project, as for YouTube.

Every source's address is the person's own choice; the privacy page's "What
it contacts" gains "the sources you link Data Files to" (tech-style.co
already names the engines).

Checks: engine tests per source from fixtures; JSON against a stand-in
server in the test, paging and a refused key included; Google Sheets
against a stand-in of its API. A window check (`base-sources`): link a CSV,
change the file, Refresh, see the change.

### B3. The release

- The full gate, the note `docs/releases/v2.18.0.md`, office.rutba.io
  brought to it (version, announcement, release notes), the sites told.
- The samples session asked whether a sample should show a source (a shop
  reading its supplier's price list from a CSV, for example), as its own
  template set.
- Films: none until the owner says (held until the remaining fixes are done,
  2026-10-23).

## Order next week

1. Part A, the gate (about a day), and Part A2, the rough edges (about a day).
2. B1, synced copies (about three days).
3. B2.1 to B2.3, files, other Data Files and JSON (about two days).
4. B2.4, Google Sheets (about a day, once the client id is added).
5. The 2.18.0 gate and release.

## For the owner

- A Google client id with the Sheets read scope, for B2.4 (or Google Sheets
  moved to 2.19).
- The default refresh for a source: every 15 minutes is proposed.
