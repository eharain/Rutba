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
| A2 | Data Files | 20 | a criterion naming a field returns every record; imported IDs and money |
| A3 | Documents | 11 | a tab added per keystroke and saved (the likely cause of the freeze); the Markdown round trip changes a file; page numbers never drawn |
| A4 | Presentations | 8 | presenter Pause ends the show; notes not typed under the slide; picture ideas cropped |
| A5 | Worksheets | 12 | conditional formatting's Apply fails on every rule; no filter arrows; charts keep old values |
| A6 | Mail, Calendar, Contacts | 17 | Mail's moves, deletes and marks never reach the server; Gmail and Outlook sign-in off |
| A7 | PDF, Pictures, Image | 14 | Pictures' tile menu trashes the open picture, not the one clicked; Image's Export offers the original's name |
| A | the gate | 5 | tooling, not a fault people see |

Fix first, when fixing starts: anything that loses or changes a person's
work (A6.1 Mail's server sync, A3.0 the freeze, A3.1 Markdown, A7.0
Pictures trashing the wrong file), then what
is broken outright (A5.1 conditional formatting, A3.10 page numbers).

## The last two releases: 2.19 and 2.20 (D-2026-10-26-07)

The owner, 2026-10-26: "in that can we will only ship these two version
including the one already build no more so properly plan this out and
start building the next as well". 2.18.0 was released on 2026-10-25
(D-2026-10-25-03). Nothing else is released until 2.19, and nothing between
2.19 and 2.20.

### 2.19: every open fault and the features planned for it

1. **Already built and merged on Office main (2026-10-26, not pushed):**
   A7.13 PDF passwords; A2.18 a database asks before reading its sources;
   A2.19 a kept password goes only where it was typed for; C1 the Data
   Files format published; their Urdu, Arabic and Hindi.
2. **Profiles,** Part D items 1 to 7, with the AI Tools command fixed
   (item 6). Merged on Office main 2026-10-26 (4efff1a9, a3fd1468; Urdu,
   Arabic and Hindi a0252199): side by side, Manage Profiles, the optional
   password sealing saved passwords, recent files, calendars, contacts and
   Talk messages (scrypt, AES-256-GCM), and the AI Tools lines naming a
   real start file and the profile. Left for 2.19: mail sealed with the
   password too, as D-2026-10-26-02 says (the mail builder, after its
   sync work, since it changes the same store); the AI tools reach a
   protected profile only while it is open with its password (today, set
   to always, they can read its chosen folders without it); a change of
   password that a crash midway cannot leave half done. A desktop
   shortcut per profile was left out.
3. **AI Tools across the board,** Part E items 1 to 4, 6 and 7 (item 5,
   a choice per AI app, is later). After profiles, as it keeps its
   settings per profile and per account.
4. **Mail at the server,** A6.1 first, then A6.2 (fetching by itself),
   A6.4 (folders), A6.11 (out of office as mail arrives), A6.5 and A6.6.
5. **Gmail and Outlook,** A6.3 and B2.4 Google Sheets, once the owner's
   client ids arrive (next week); oauth.js sends the Google Desktop
   client's secret, read from the build's settings, never the repo.
6. **Calendar, Contacts and the rest of Mail:** A6.7 to A6.10, A6.14,
   A6.15, A6.17. After profiles, which changes calendar.js and
   contacts.js.
7. **Open formats:** A2.20 (files made elsewhere: opened read only when
   foreign, newer versions refused, unknown keys kept, DESIGN_VERSION 7
   and the spec with it); C2 Strict OOXML; C4 docs/OOXML-NOTES.md from
   what C2 finds. C3's real documents: the builder lists candidates with
   their source and licence, and the owner approves the list before any
   is fetched; the measuring follows.
8. **The other faults:** A3.3, A3.8, A3.9 (Documents); A4.2 to A4.8
   (Presentations); A5.9 to A5.12 (Worksheets); A7.4 to A7.6, A7.8 to
   A7.12 (PDF, Pictures, Image).
9. **The release:** translations of every new message, the full gate
   (a minor release, D-2026-10-23-01), the release note, the packaged
   checks, install and update tests, the pre-release, office.rutba.io's
   facts, release timeline and privacy page (profiles, AI Tools' send
   with confirmation), then the how-to scripts that waited on these
   fixes, and the films after them (content-coordination-chain).

Builders, each in its own clone, never two on the same files: profiles
(running); mail at the server (item 4); open formats (item 7); the 2.20
groundwork (below). When profiles is merged: AI Tools (item 3), then
Calendar and Contacts (item 6), and the other faults (item 8) in the
freed clone. Gmail and Outlook (item 5) when the ids arrive. Size: about
three weeks with the builders side by side; the gate and release about
two days.

### 2.20: only the apps a person chose (Part F)

1. **Now, beside 2.19 (it moves no app code, so it does not collide):**
   the map of what each app imports from another and from the shared
   engines (F7); the pack format (a manifest naming the app, its version,
   the packs it needs, its files and their SHA-512, signed with Ed25519);
   the tool that makes and signs packs from a build; the core's loader
   that verifies packs and refuses a wrong version or signature; their
   tests, with a key made for the tests. The real signing key is made
   once and kept with the other release secrets, never in the
   repository.
2. **After 2.19 is tagged:** each app's main-process code moves into
   its own folder and registers through the loader; the build makes the
   core and the packs; the installer asks which apps; Add or remove apps
   in the launcher; packs updated with the core.
3. **Updating from 2.19:** a person updating keeps every app they had,
   and removes any they like afterwards; nothing they use goes missing.
4. **The release:** the full gate with every pack, the check that a
   core with one pack holds no other app's code, file type or tool, the
   install test with a short list of apps, and the update test from
   2.19.0. Size: about two weeks after 2.19.

## What 2.18.0 carries (D-2026-10-25-01; being built since 2026-10-25, D-2026-10-25-02)

1. **The gate,** Part A.
2. **Faults that lose or change work:** A3.0 (a tab per keystroke, the
   freeze), A3.1 (Markdown), A7.0 (Pictures trashes the wrong file), A7.2
   and A7.3 (Image's Export name, closing without asking), A7.7 (PDF's
   Apply Redactions drops the original).
3. **Released features that don't work:** A5.1 (conditional formatting),
   A3.10 (page numbers), A4.1 (presenter Pause), A3.7 and A5.8 (Save As in
   the app menus), A6.16 (Mail's selection after a delete), A6.13 (Sent
   after a reload), A6.12 (Import mail's paths), A7.1 (the redaction list).
4. **Data Files' fixes,** A2.1 to A2.11, A2.14, A2.16, A2.17, so the Data
   Files how-to parts 1 to 4 can be filmed after the release.
5. **The bigger features, moved up by the owner (2026-10-25: "Bigger
   features: move up to 2.18"):**
   - Data Files: a form's layout changed and saved (A2.12), lines added in a
     subform (A2.13), a report's totals chosen (A2.15);
   - Worksheets: filter arrows and the value list (A5.2), charts that follow
     edited cells (A5.3), a new PivotTable shown, with Filters and its own
     Refresh (A5.7);
   - Documents: Tab and Shift+Tab (A3.2), Modify Style (A3.4), comments on
     the selected words (A3.5), tracked changes one at a time (A3.6).
6. **Synced copies and sources,** B1 and B2.1 to B2.3 (D-2026-10-23-03).

**For 2.19:** A6.1 Mail's changes at the server, first; A6.3 Gmail and
Outlook sign-in and B2.4 Google Sheets (they wait on client ids); the rest of
A3 to A7.

**Size:** with item 5, 2.18.0 is about two weeks' work, not one, so it is
ready near the end of the week after next rather than mid next week, unless
it is split (a 2.17.2 of items 2 to 4 first, gated by the apps it changes).

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
18. **A database from someone else reads its sources without asking**
    (found 2026-10-26 reading LibreOffice's CVE-2026-63277: a spreadsheet
    whose database range refreshes itself on open fetched an outside file
    and ran its driver with no warning). Office runs no code from a source,
    but a .rbase file sent by someone else, with a table linked to a web
    address or a file path, is read again as soon as it is opened and due
    (renderer base.js about 677, `refreshDue`; main base-sync.js 204). That
    tells the address's owner the file was opened and from where; a
    `\\server\share` path makes Windows offer the person's sign-in hash to
    that server; a path on this computer reads the person's own file into
    the database, which goes back with it if it is sent on. A database
    opened from a file this computer did not make (or, simpler, the first
    time any database is opened here) asks before it reads any source,
    naming each address and path, as a document asks before its macros;
    the answer is kept for that file. Before 2.19's release, with A7.13.
19. **A stored password goes wherever the file now points** (found writing
    the format spec, 2026-10-26). Engine passwords and a source's secret
    headers are kept by the link's id alone (`base-link:<id>`,
    `base-source:<id>` in main base.js and base-sync.js) while the host or
    URL comes from the file, so a person's .rbase changed to another host
    with the same id sends their secret there when opened. Each secret is
    bound to the destination it was saved for and is not sent elsewhere.
    With A2.18.
20. **What the format spec found Office doing to files made elsewhere**
    (docs/DATA-FILES-FORMAT.md section 11): it opens any SQLite file and
    adds its design tables and WAL mode to it (open another program's
    database read only, or ask before making it a Data Files database);
    it opens a newer design version instead of refusing it; a design change
    rewrites rutba_fields rows and the query designer rewrites a column
    from the keys it knows, so a newer version's additions are lost (keep
    what is not understood); and 2.18.0's synced copies and sources came
    in without a new design version (raise it to 7, so 2.17 refuses rather
    than reading a copy as live). For 2.19.

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
   **Likely cause, found 2026-10-24 and checked in the code:** typing in a
   paragraph that holds a tab adds another tab with every keystroke, and
   they are saved (a .dotx made in the Templates episode carries 72
   `<w:tab/>` after its address line). In packages/ooxml/src/document.js
   `_keptFragments` (about line 5995) a run holding only `<w:tab/>` has no
   `<w:t>`, so it is kept verbatim, and `renderRuns` writes the tab again
   from the model's "	" on every rebuild (`_setRuns`). Backspace does not
   clear them. Treat `<w:tab/>` (and `<w:br/>`, `<w:cr/>`) as text the model
   owns. The Letter template's address line is text, a tab, then more text:
   the line the freeze was found on. Fix this first, then see whether the
   freeze still happens.
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
10. **Data from Picture misreads ruled tables** (packages/ocr/src/layout.js):
    two or more horizontal rules become the only row edges, so a price
    list with a rule above and below its headings and one at the foot reads
    as 2 rows (about line 139); and a title or footer line crossing the
    column gutters merges the columns (about line 152). Use rules as rows
    only when they separate every line; allow a few crossings, as columns()
    does.
11. **Receipt or Invoice:** the tax-rate check always takes the subtotal as
    its base, so a mixed-rate invoice whose subtotal and tax do add up to
    the total is marked as not agreeing (packages/ocr/src/fields.js about
    751); and the currency comes only from the amounts' own text, so "TOTAL
    GBP 89.40" gives none (about 862). Not a corner case: UK grocery and
    supplier receipts mix zero-rated food (milk, bread, tea, coded Z) with
    standard-rated goods (S), so most of a shop's receipts would be marked
    to check though they add up (the video session's receipt: subtotal
    86.40, VAT 3.00 as 20% of 15.00, total 89.40). Read the Z and S codes
    and the stated VAT base where printed; let "subtotal plus tax is the
    total" stand when no single rate fits.
12. **Template gallery search** covers only the list chosen on the rail, and
    personal templates show only in a search from All templates; Word's
    search covers everything.
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
11. **Out of office sent by Rutba Office** runs only as mail arrives, and
    nothing fetches on its own (A6.2), so the dialog's "While Rutba Office
    is running" (mail/dialogs.js about 290 and 306) is untrue today. In
    server mode the Subject hint promises "Automatic reply: " and the
    original subject, but no subject is written into the server's script
    (packages/mailbox/src/managesieve.js about 41).
12. **Import mail shows a person's own details:** the scan reads the real
    Thunderbird, Outlook and Windows Live Mail folders and the Outlook
    registry, and the Importing box prints each file's full path, which
    Outlook names after the account's address (mail/dialogs.js about 1216).
    Show the file's name, not its path; and give the scan a seam a check or
    a film can point at an empty folder.
13. **Sent appears only after a reload:** the first send makes Sent
    (main/mail.js about 1369), and the window's mail:sent handler does not
    read the folders again (renderer mail.js about 389).
14. **Mail's invitation strip forgets the answer** when the message is
    opened again (it reads the file, which still says NEEDS-ACTION;
    main/calendar.js about 251); the reply.ics attachment shows "0 B"; the
    unsubscribe question shows the raw List-Id with its angle-bracket id.
15. **Contacts import:** today's Google CSV headings (Organization Name,
    Organization Title, "E-mail 1 - Label", "Phone 1 - Label") are not read,
    so companies, job titles and every type are lost, and Labels' "*
    myContacts" becomes a tag (packages/contacts/src/csv.js about 51-53,
    93-97); a contact with no email address is added again on every import
    (main/contacts.js about 103); a vCard TEL;TYPE=CELL shows as "cell", not
    "mobile", and the editor then shows "mobile" while the card keeps
    "cell".
16. **Deleting a message loses the place in the list** (the owner,
    2026-10-24: "the email deletion with delete button or delete from list
    reset the selection back to first email, while it should be selecting
    the next rather than first"). Delete, by the ribbon button or the
    list's own menu, clears the selection (renderer mail.js about 565,
    `setSelected(null)` for every action in LEAVES), so the reading pane
    empties and the next Down or j starts again from the first message
    (about 1235-1238, `at < 0`). The same holds for Archive, Junk, Move,
    Not junk and Block. Select the message after the last one removed (or
    the one before it at the foot of the list) and open it, as Outlook
    does; a check in verify-mail-window.js deletes the middle of three and
    sees the third selected and shown.
17. **Importing the same file twice makes a second mailbox** (found checking
    the video session's Mail 4 script against 2.18.0). Import mail calls
    `mail.import` with no account (renderer mail.js about 1021), so main
    mail.js about 1420 makes a new local mailbox each time, and every
    message is copied again into it; "adds nothing" holds only within one
    mailbox. Import into the mailbox already made from that file (its
    `imported` path), or ask which. For 2.19.


## Part A7. PDF, Pictures and Image (2026-10-24)

0. **Pictures' tile menu trashes the wrong file** (checked in pictures.js):
   right-click a tile, "Move to trash", and the picture on show is moved to
   the trash, not the tile clicked (`tileMenu` opens the commands, which act
   on `current`); with nothing on show, "Edit this picture" and "Move to
   trash" do nothing. Each item acts on the tile right-clicked. First in
   this part: it removes the wrong file.
2. **Image: Export offers the original's own name and folder,** so one Enter
   and Windows' replace prompt are all that stand before the photo is
   replaced; offer "{name} edited" beside it. From an Edit in Image window,
   Export offers "scratch.png" in a temp folder.
3. **Image: closing loses unexported edits with no question,** on a picture
   without layers and in every Edit in Image window (which has no autosave).
4. **Image: Alt on the picture leaves the ribbon's KeyTips armed** (read in
   the code, to confirm in a window): the canvas cancels pointerdown, so the
   mousedown that disarms them never comes; after an Alt+click (Clone Stamp,
   Healing Brush, a subtract drag) the letters show and "[", "]", "J" are
   swallowed. Disarm on pointerdown.
5. **Image: Undo without layers skips slider changes** (Ctrl+Z after Auto
   enhance takes back the crop instead); Levels' "Auto" also resets
   Temperature and Tint; Move picks the top full-canvas layer wherever you
   click.
6. **Pictures shows a file written while it is open** (no folder watch;
   Back does not list the folder again).
7. **PDF: Apply Redactions drops the marked-up original unsaved:** the
   window switches to the redacted copy without asking about the marks.
   Ask, or keep the original open beside it.
8. **PDF: the words list also holds an area mark's glyph runs, spaces not
   collapsed** (with item 1, redact.js:691), and "1 mark on 1 pages" is not
   made singular (redact.js:138).
9. **PDF: page moves and marks.** Dragging one of several selected pages
   to a place inside the selection does nothing and says nothing; Date and
   Checkmark stay in hand, each click adding another; a placed signature,
   tick or date cannot be moved or resized; clicking a mark's card puts
   Mark Area down without a word; Split's files are named only in a toast
   (no Open or Show in folder).
10. **Pictures: ratings and tags lost on rename or move** (kept by full
    path); Batch edit forgets every setting each time; the slideshow takes
    the whole display full screen; with Copy Text shown a zoomed picture
    cannot be panned.
11. **Copy Text misreads heavy bold figures** ("£1.65" as "£ / 41 65").
    Noted for the OCR work, not a quick fix.
1. **Apply Redactions lists the marked words with every "s" as a space:**
   packages/pdf/src/redact.js:691 has `/s+/g` where `/\s+/g` was meant. Only
   the list shown in the dialog; what is redacted is matched on the
   normalised words. Found by the video session reading the source.
12. **PDF: Fields finds a tick box in a scanned address line.** In PDF 5's
    Fields pane, the scanned invoice's address line is detected as "1 tick
    box". Found by the video session shooting PDF 5 on 2.17.1. For 2.19.
13. **A PDF with a password does not open** (the owner, 2026-10-26: "the password
    protected pdf dose not open with our viewer that we will need taking care
    off"). Refused by design so far: the window's pdf.js open gives up at the
    password question (renderer pdf/pdfjs.js, `task.onPassword` destroys the
    task) and says "not built yet", and packages/pdf reads no encrypted file
    (reader.js; annotations, fields, navigation, redaction, page changes,
    compressing, the text layer and every save refuse one). In two steps:
    (a) ask for the password, again when it is wrong, and show the file:
    reading, Find, copying, printing and Export as Pictures, through pdf.js;
    (b) packages/pdf decrypts the standard security handler (RC4 40 and 128
    bit, AES-128, AES-256), so comments, fields, bookmarks and edits work,
    and a save keeps the password or, asked, saves without it. Files with
    only an owner password (permissions) are checked too. For 2.19.

## Part C. Open formats (D-2026-10-26-01)

The owner, 2026-10-26: "the data files format we are implementing we will
make these transparent for the world .  strict if it is coming up as a
limiting factor we should help these regulators out too."

1. **The Data Files format, published.** docs/DATA-FILES-FORMAT.md in the
   Office repository: a .rbase file is one SQLite file whose data sits in
   ordinary tables; the spec gives every rutba_* design table (meta, tables,
   fields, relations, steps, queries, forms, reports, documents, links,
   linked, roles, people, trail, sync, clashes), each JSON layout a column
   holds (a query's design, a form's and a report's layout, a print
   template), what each DESIGN_VERSION added, how a protected database is
   kept, and what a reader must do with what it does not know. Free to
   implement, no patent claim, the text under CC BY 4.0. With sample files
   and `tools/check-rbase.mjs`, which says whether a file follows it. A test
   fails when the design tables change and the spec does not.
2. **Strict OOXML.** Documents, Worksheets and Presentations open files in
   ISO/IEC 29500 Strict (the purl.oclc.org/ooxml namespaces, dates as ISO
   8601 in Worksheets, no VML), and Save As offers Strict beside the usual
   form. Today a Strict file does not open properly: packages/ooxml knows
   only the Transitional namespaces. Round-trip tests with Strict files
   saved by Word, Excel and PowerPoint.
3. **Real documents, measured.** A test set of public documents (government
   forms, council spreadsheets, published reports and decks, kept with
   their sources and licences), each opened and checked for blank pages,
   missing text, pictures and charts, and layout drift against Word's and
   Excel's own rendering (tools/compare-word.ps1, compare-excel.ps1). The
   figure goes on office.rutba.io only as measured.
4. **Where files depart from the standard.** What item 3 and the Strict
   work find in real files that ISO/IEC 29500 does not describe, written up
   in docs/OOXML-NOTES.md for other implementers and for regulators, plain
   and factual, naming no one unkindly.

## Part D. Profiles (D-2026-10-26-02), for 2.19

The owner, 2026-10-26: "we should offer multiple profiles in office so user
can switch between  them and manage them as well." Side by side, with an
optional password.

Today everything a person has is in one folder, %APPDATA%\Rutba Office
(template-set-choice.js PROFILE_NAME; office-shell store.js keeps
settings.json, secrets.json and recent.json there, and every app keeps its
own files beside them: mail and its index, calendars, contacts, Talk's
keys, thumbnails, AI Tools, errors.log).

1. **Profiles kept apart.** Each profile is a folder of its own; the
   folder people have now becomes the first profile, "Default", left where
   it is so nothing is moved. A small profiles list beside it names each
   profile, its colour and folder, and the one that opens first. What is
   shared by every profile: the installed program and its updates, the
   downloaded template sets, the spelling dictionaries.
2. **Side by side.** Each profile runs as its own Rutba Office (one single
   instance lock per profile), so two profiles can be open together; a
   file opened from Explorer goes to the profile last used, and a person
   can choose Open in Profile. Every window shows its profile's name and
   colour in the title bar when more than one profile exists.
3. **Switching and managing.** The launcher's account menu lists the
   profiles (open, or switch to, each), with Manage profiles: make one,
   rename, choose a colour and picture, choose the one that opens first,
   remove one (asking first, saying what goes with it). A desktop shortcut
   can open a chosen profile.
4. **An optional password.** A profile with a password asks for it before
   anything of it opens. Its saved passwords, mail, calendars and contacts
   are kept encrypted with a key made from the password (scrypt), so
   another person at the same Windows account cannot read them; the
   password is never stored, and a forgotten one cannot be recovered
   (said plainly when it is set). Change and remove the password.
6. **The AI Tools command names a file that is not there** (the owner,
   2026-10-26: "when i passed this mcp cli the tool complained its not
   there"). The command AI Tools shows (ai-tools.js `mcpCommand`) runs
   Rutba Office.exe as Node on `resources\app.asar\main\mcp\node.js`.
   That file exists only inside the app.asar archive, which only Electron
   reads: run that way it answers (checked 2026-10-26 against the installed
   2.18.0), but an AI app or command line that checks the path first finds
   nothing. Ship a small real file outside the archive (electron-builder
   extraResources, e.g. `resources\mcp\rutba-office-mcp.js`) that loads the
   archive's mcp/node.js, show that path, and say in AI Tools that older
   settings should be copied again. With profiles, the command names its
   profile (`--profile <id>`), so an AI app works in the profile it was set
   up from.
7. **Checks:** engine tests for the profile list and the folders; window
   checks that make a second profile, open both side by side, see each
   window's badge and keep their settings and mail apart, and open a
   protected profile with a wrong then the right password.

## Part E. AI Tools: everything the tools could reach carries its own setting, for 2.19

The owner, 2026-10-26: "the mcp tool should also let the user choose what
to allow from apps, what emails accounts to allow to all etc."

Today (apps/desktop/main/mcp/tools.js) the tools reach files only: list
and read files in the folders given, make documents, workbooks and
presentations, templates, PDF export and combining, and reading text in a
picture. The person chooses off, this session or always, and the folders.

1. **One rule across the board** (the owner, 2026-10-26: "so the settings
   should be email accounts", then "same for calendars and contacts and
   across the board"). Every thing the tools could reach carries its own AI
   tools setting, kept with it and shown in its own settings: each mail
   account, each calendar, each address book, each Data Files database and
   each folder of files. The AI Tools window lists them all with the same
   setting, one setting shown in both places. Everything is Off until the
   person chooses, except the folders already given today, which keep
   what they allow. A refusal names the thing and where its setting is.
2. **The same four steps everywhere:** Off; Read; Read and prepare
   (drafts, new events and contacts, new files and records, all kept on
   this computer for the person to look at); Read, prepare and act, where
   anything that leaves the computer or tells another person (a message
   sent, an invitation or its answer, a shared file, a change written to a
   database engine) is shown in Office first, with the action, Keep as
   draft and Cancel, and happens only when the person presses it (the
   owner, 2026-10-26: "allow sending too, but confirm each message first
   with choice to create drafts only"). Deleting or moving anything is
   never in reach of the tools.
3. **What each step means, per kind.** Mail: read and search; drafts;
   send, each message confirmed (an archive opened in place is read only).
   Calendar: events; new events; invitations sent and answered, each
   confirmed. Contacts: people; new contacts; contacts kept in step with a
   server, each change confirmed. Data Files: records; new and changed
   records (never the design), within the role the person chose for the
   tools when the database is protected; writes to a linked engine
   confirmed. Folders: list and read; new files (never overwriting, as
   now); nothing further.
4. **Attachments, invitations and linked files** are read only from
   things the tools may read.
5. **Per AI app, later.** The window already lists the AI apps that
   connected; a choice per AI app (one AI app may read mail, another not)
   comes after items 1 to 4.
6. **The log** names the app, the account, calendar or database each call
   used, never what it read.
7. **With profiles (Part D):** every choice is kept per profile.

## Part F. Only the apps a person chose are on their computer, for 2.20 (D-2026-10-26-07)

The owner, 2026-10-26: "how do we ensure that the code only is deployed on
customers computer when the user has chosen the app.  so the code should
not be disabled but actual is there or not depending on user choices".

Today every app is in the one archive (resources\app.asar, 74 MB, plus 15
MB unpacked; the Electron runtime is most of the 457 MB installed). The
windows already load each app's code only when it opens
(renderer/index.js imports apps/<app>.js on demand); the main process
starts every app's service at launch.

1. **Core and app packs.** The core is the runtime, the shell, the
   launcher, settings, profiles, the updater and the engines several apps
   share (reading and writing Office files, drawing pages). Each app is a
   pack: its window code, its main-process service and IPC handlers, its
   own heavy parts (text recognition's data, video's codecs, Talk's
   calling, AI Tools' server), its tiles, file types and checks. Packs:
   Documents, Worksheets, Presentations, PDF, Pictures, Image, Video,
   Recorder, Mail, Calendar, Contacts, Data Files, Talk, AI Tools.
2. **Absent, not off.** A pack not chosen is not on the disk: no file of
   it, no IPC channel, no file type, no tile, no AI tool. The core finds
   the installed packs at start and loads only those.
3. **Choosing.** The installer asks which apps (all ticked, or a short
   list of common sets), and the launcher's Add or remove apps adds a pack
   (downloaded from the release, or from the full installer kept on the
   computer for offline use) and removes one (its program files go; the
   person's own files and settings stay unless they ask). An app that
   needs another names it (for example Mail's invitations open Calendar).
4. **Trust.** Every pack is signed (an Ed25519 key whose public half is
   in the core) and carries its SHA-512; the core refuses a pack that does
   not match its own version or its signature. Packs update with the core
   in one step, only the ones installed.
5. **Build and checks.** The build makes the core and one archive per
   pack from the same commit; the gate runs with every pack, and a check
   installs the core with one pack and finds no code, file type or tool of
   any other.
6. **What it saves.** Mostly trust and attack surface rather than disk:
   the runtime is fixed, and the app code is about 90 MB in all. The
   biggest packs (text recognition, video, PDF's viewer) save the most.
7. **First step:** a map of what each app imports from another and from
   the shared engines, so the core's line is drawn where the code
   already divides. Size: about two weeks after the map. The map and the
   pack format are built beside 2.19; the app code moves after 2.19.

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
