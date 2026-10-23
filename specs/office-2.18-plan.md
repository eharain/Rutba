# Rutba Office: the plan for next week (2.17.2 tooling, 2.18.0)

Written 2026-10-23, after 2.17.1 was released. Nothing here is built before
next week (owner: "we will hold the 2.18 f untill next week", "just plan it
out no build until next week"). Decisions it follows: D-2026-10-23-01
(patch releases gated by what they change), -02 (nobody waits on Office
builds), -03 (2.18.0 holds synced copies and the other sources; no
encryption; SQL Server later).

## The fix list at a glance (kept up to date; nothing fixed before next week)

The owner, 2026-10-24 (D-2026-10-24-01): "or just keep track what needs to
fix". Each fault below says how to see it and where in the code; nothing is
fixed, pushed or released until the middle of next week.

| Part | App | Items | The worst of them |
| --- | --- | --- | --- |
| A2 | Data Files | 17 | a criterion naming a field returns every record; imported IDs and money |
| A3 | Documents | 11 | a freeze that loses work; the Markdown round trip changes a file; page numbers never drawn |
| A4 | Presentations | 8 | presenter Pause ends the show; notes not typed under the slide; picture ideas cropped |
| A5 | Worksheets | 9 | conditional formatting's Apply fails on every rule; no filter arrows; charts keep old values |
| A6 | Mail, Calendar, Contacts | 10 | Mail's moves, deletes and marks never reach the server; Gmail and Outlook sign-in off |
| A7 | PDF, Pictures, Image | 1 so far | the redaction list shows each "s" as a space (checks under way) |
| A | the gate | 5 | tooling, not a fault people see |

Fix first, when fixing starts: anything that loses or changes a person's
work (A6.1 Mail's server sync, A3.0 the freeze, A3.1 Markdown), then what
is broken outright (A5.1 conditional formatting, A3.10 page numbers).

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

Found checking parts 2 to 4 (episodes 8 to 17), the same day:

7. **A criterion naming another field** (`<= [Reorder Level]`) is taken as
   the text "[Reorder Level]" and returns every record, with no error.
   Compare with the field, or refuse in plain words.
8. **An average rounded in the designer.** The engine's per-column
   decimals are not offered in the window, and an expression cannot hold
   Avg or Sum; offer the decimals beside Total, and say so when Avg is typed
   into an expression. The heading "Avg of Total" should read "Average of
   Total", as the Total list says.
9. **Import keeps a CSV's own ID.** A column named ID becomes "ID
   (imported)" beside a new AutoNumber, so relating by the file's own
   numbers fails ("pointing at nothing", "must be unique"). Use the file's
   IDs as the key when they are whole numbers, unique and present.
10. **Money imported as Currency** when a column's values have two decimal
    places, so receipts show 1.10 and the template wizard adds its Amount
    and Total.
11. **A query saved from the SQL view,** and its text kept when the view is
    left.
12. **A form's layout changed:** fields moved, resized and taken off, and a
    label renamed, saved with the form.
13. **Lines added and changed in a subform,** a new row at its foot, as
    the datasheet has.
14. **A form's Delete asks first.**
15. **A report's totals chosen:** Sum, Average, Count or none for each
    number field, Whole numbers included; a report made from a query gets
    them too.
16. **A record named by nothing** (a sale with only a payment) named by its
    number and date in lists ("Sale 17, 21/10/2026"), not "Cash".
17. **A form with no print template** says how to make one where its Print
    buttons would be; the template's record chooser names records, not
    "Record 17"; Letterhead says what it is for when no Business table
    exists.

Items 12, 13 and 15 are features rather than fixes (a form designer, an
editable subform, report totals); they may go into 2.18.0 with the rest.

Each with its engine tests and Data Files window checks. They go into
2.18.0 if it is next week's only release, or a 2.17.2 at the start of the
week (Data Files only, a gate of about 25 minutes) so the films can go on.

## Part A3. Documents faults the how-to scripts found (2026-10-24)

Found checking the Documents how-to scripts against 2.17.1; the episodes
that need them wait, as the Data Files ones do.

0. **A freeze that loses work** (found filming episode 6, 2026-10-24,
   three times in three on 2.17.1): in a new document from the Letter
   template, triple-click the first "Your Name" line, type "L", "arkspur",
   then a space; the renderer goes to 100% CPU and never answers, and
   nothing can be saved. Two faults: a triple-click's selection runs to the
   start of the next paragraph ("Your Name

"), so typing over it joins
   the two lines (Word keeps the paragraph mark); and a space typed into the
   joined line (text, then a tab, then "phone  |  you@example.com") hangs
   the layout. First in this part: it loses a person's work. Reproduce on the
   engine (doc-view) before the window; keep an edit that hangs from
   freezing the window (a time limit on layout, the document kept).
1. **Markdown round trip damages a file:** a raw HTML block directly above
   a code block loses the blank line between them, and the code block breaks
   on GitHub. Also kept as written: table padding, reference links,
   definition lists. Task boxes clickable, the "- " marker hidden. Next
   after the freeze: it changes a person's file.
2. **Tab and Shift+Tab** wired to the engine's tabCell: a list item's level,
   the next or previous cell, a new row from the last cell. Today Tab moves
   focus off the page.
3. **Headings in a Word file that has not used them:** offer Word's latent
   built-in styles (Heading 1 to 3, Title) when styles.xml lacks them; today
   only "Normal" shows and Add Text's levels fail.
4. **Change a style:** Modify Style, and Update Heading 1 to Match Selection.
5. **Comments:** anchored to the selected words, as the dialog says, marked
   on the page, and signed with the author tracked changes use (empty today).
6. **Tracked changes per change:** Next and Previous select each change;
   Accept and Reject This Change act on that change, not the paragraph;
   Accept All and Reject All work wherever the caret is.
7. **Save As in the app menu,** beside Open and Save as Template.
8. **A tab in the header and footer box,** as its hint promises; "Page
   number" and "Of total" combining sensibly.
9. **Home's template row** refreshed when it regains focus.
10. **Page numbers from the header and footer box:** "Page number" and "Of
    total" write "{PAGE} of {PAGES}" into the file as plain text, so no page,
    print, PDF or Word ever shows a number, though the box says "Fields in
    braces are resolved when the page is drawn and when it is printed."
    Write real PAGE and NUMPAGES fields (fldSimple) for {PAGE} and {PAGES};
    "Of total" adds no second space. Found filming episode 4.

## Part A4. Presentations faults the how-to scripts found (2026-10-24)

1. **The presenter view's Pause ends the show** (and zeroes the clock), and
   Reset sends it back to slide 1. Pause should pause the clock only; Reset
   restart the clock, not the slides.
2. **Notes typed under the slide in Normal view** ("Click to add notes"),
   as PowerPoint users expect; today the strip is read only and hidden when
   empty. The presenter's no-notes hint names the right place (it says the
   Home tab, which has no notes control).
3. **New Slide applies the layout chosen,** from the deck's own layouts, not
   a fixed three; the two buttons both called "Layout" (Home, Design) named
   apart.
4. **Use Presenter View** says it starts the show; with one screen, the
   presenter window is not covered without a word. Esc in the show tells the
   presenter window the show ended.
5. **Design Ideas replace each other:** a second pick takes the first one's
   shapes off before adding its own. **And a picture idea applied matches
   its preview** (found filming episode 3, 2026-10-24): "The picture on the
   right, the words beside it" with a 1200×760 picture shows it whole in the
   pane, but applied, the picture's box takes the right half at full height
   and the picture is cropped to fill it ("spur Corner Store"), in the deck
   too. Fit the picture inside its new box, as the preview draws it.
6. **Clear Narration clears the slide's timing too,** as the code says it
   should, and says so only when there was narration.
7. **An exported video** plays each cameo's recording, not a still, and does
   not draw the narration speaker icon; in the editor the icon does not sit
   on the default cameo's corner.
8. **Minor:** "Play Narrations"' tooltip ("as this suite records none") is
   out of date; shape fill and outline offer quick swatches; a shape can be
   drawn by dragging; Design Ideas' names are translated.

## Part A5. Worksheets faults the how-to scripts found (2026-10-24)

1. **Conditional formatting's Apply fails on every rule:** the dialog sends
   { type, format } where the engine reads { kind, look }, so each rule is
   refused ('"" is not a rule this dialog writes') and nothing is added.
   'Not equal to' and 'Unique values' are offered but the engine refuses
   them. A released feature that does not work: first in this part. Offer
   colour scales and data bars too, which the engine writes already.
2. **Filter arrows and the value list** in the header row; the engine's
   filterOptions, openFilterPanel and applyFilter are ready, the grid does
   not call them.
3. **Charts follow edited cells,** and their cached values are written on
   save; today a chart keeps the values it was opened with.
4. **A chart's title,** and its other parts (axes, legend), set from a
   Chart Design tab; a chart made from the selection when there is one.
5. **A table grows** to take a row typed directly under it.
6. **Sort** names columns from the list's heading row, not the row above
   the active cell, and never sorts the heading row into the data; the
   Data tab's "A → Z" tip says which column it sorts by.
7. **A new PivotTable** is shown once made (scrolled to, its Fields pane
   open), with a Filters area and a Refresh of its own; months from a date
   field.
8. **Save As in Worksheets' app menu;** Ctrl+S on a converted old file
   offers Save As instead of an error.
9. **Error cells** carry a mark with the reason on hover; Error Checking's
   reasons translated. **Insert function** shows each function's arguments
   and what it does.

## Part A6. Mail, Calendar and Contacts faults the how-to scripts found (2026-10-24)

1. **Mail's changes never reach the server** (checked in main/mail.js):
   `flag`, `move` and `delete` change only the local store, and Get mail
   fetches the newest messages again by position, so a message deleted or
   filed here can come back, and a phone sees none of it. Read and flagged
   marks, moves, deletes, junk and the Sent copy go to the server (IMAP
   STORE, MOVE or COPY and EXPUNGE, APPEND), and fetching goes by UID from
   what was last seen. The largest item in this plan: a mail client's core.
2. **Mail fetches by itself:** on opening and every few minutes (a setting),
   so rules and Rutba Office's own automatic replies run without Get mail.
3. **Gmail and Outlook sign-in in released builds:** a Google and a
   Microsoft client id registered and built in (docs/OAUTH.md says how; the
   owner registers them, as for YouTube). Until then the disabled card says
   it in a person's words, not "See docs/OAUTH.md", and a typed Gmail
   address does not promise Google's page.
4. **Folders:** make, rename and delete a folder, at the server; drag
   messages onto folders.
5. **One-click Unsubscribe** sends the one request it says it sends,
   instead of opening the browser.
6. **Out of office on hosted mail without ManageSieve** (Gmail, Outlook,
   Yahoo, iCloud with an app password) says at once that the server cannot
   send them and offers Rutba Office's own, not "could not be reached" after
   ten seconds.
7. **Calendar:** Invite offers to send on save, as its hint says; editing
   one occurrence defaults to that occurrence; a repeating event keeps its
   Reminder; an event's time zone can be chosen and another zone shown; the
   small month's arrows move the main view too.
8. **Accounts for calendars and contacts** named by the person (not the
   host), renamed later; "New cards go to" defaults to the account's book
   once there is one.
9. **Contacts CSV import:** reads ANSI as well as UTF-8 (Outlook writes
   ANSI), shows a preview with the columns it matched and lets one be
   changed, and says what it left out.
10. **Minor:** the Microsoft tile's note ("Outlook, Hotmail and Microsoft
    365's servers"); Signature and Out of office say why they are greyed in
    All accounts.

## Part A7. PDF, Pictures and Image (2026-10-24, checks under way)

1. **Apply Redactions lists the marked words with every "s" as a space:**
   packages/pdf/src/redact.js:691 has `/s+/g` where `/\s+/g` was meant. Only
   the list shown in the dialog; what is redacted is matched on the
   normalised words. Found by the video session reading the source.

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

1. Part A, the gate (about a day); Part A2, Data Files' rough edges, and
   Part A3, Documents' faults, Part A4, Presentations', Part A5,
   Worksheets' and Part A6, Mail, Calendar and Contacts' (more than a
   week together: see the note below).
2. B1, synced copies (about three days).
3. B2.1 to B2.3, files, other Data Files and JSON (about two days).
4. B2.4, Google Sheets (about a day, once the client id is added).
5. The 2.18.0 gate and release.
6. The Data Files how-to scripts, parts 1 to 4 (D:\videos\_how-to\data-files-part-1.md
   and data-files-parts-2-4.md, 14 steps marked "pending fix"), checked
   against the release that carries the fixes, then the video session's go.

**Size, 2026-10-24:** Parts A2 to A6 together, about 60 items, are more
than a week's work, and A6.1 (Mail's changes at the server) alone is
several days. They are ordered for the owner to choose what comes first;
the how-to episodes that need each wait for it.

## For the owner

- A Google client id with the Sheets read scope, for B2.4 (or Google Sheets
  moved to 2.19).
- The default refresh for a source: every 15 minutes is proposed.
