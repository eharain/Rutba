# Rutba Office 2.22: faults carried over (list)

Kept while 2.21.1 was released (D-2026-10-27-17, released 2026-10-28, tag
v2.21.1 at office ee2a50d8). Not a plan: the owner has not set 2.22's
scope. Each item says how to see it and where in the code. Earlier items
for 2.22 (PSD layers, Gmail and Outlook client ids, the scanned invoice
sample) stay in office-2.21-plan.md.

## Data Files samples, on some days

The samples are built from the real date, so a check can pass today and
fail on another day. Seen with a sweep that builds each sample for many
days and seeds and runs checkSample (the car dealer was the one fixed in
2.21.1, templates 07fea90):

1. **Trading (Northbank Trading).** "Orders to ship" is empty on some
   days, and on 2026-10-13 with the default seed one product's Units in
   Stock is -2. packages/templates/data-files/samples/trading.js.
2. **Builder.** Seed 7 on 2026-10-13: Unpaid invoices has nothing to
   print. samples/builder.js.
3. **Garage.** Parts to reorder is empty on two days of the sweep.
   samples/garage.js.

The fix for each: after the daily loop, make sure what each report prints
exists (as cars.js does since 07fea90), and no stock below zero.

## Temp folders the app leaves

4. **Two prefixes from the app itself**, not the tests:
   apps/desktop/main/documents.js ('rutba-object-', about line 3412) and
   packages/office-shell/src/electron/ipc.js ('rutba-office-', about line
   275). An installed copy leaves them in %TEMP% in normal use. Remove
   each when its window or job is done, or at quit. (The tests' and the
   gate's own folders go since tools/run-temp.js, landed after the
   v2.21.1 tag.)

## Smaller

5. **The Templates list asks for a folder that is not there.** Every
   smoke run logs "Error occurred in handler for 'rutba-office/fs:list':
   ENOENT ... Documents\Custom Office Templates" (ipc.js about line 851).
   A missing folder is an empty list, not an error.
6. **A search box clicked again keeps the picked words.** In a Data
   Files form, a search control that already has focus keeps the picked
   record's words when clicked, so typing lands after them
   (apps/desktop/renderer/apps/base/forms.js, onFocus runs only when
   focus arrives). Select the words on click, as a browser's address bar
   does. Found by the how-to check of Data Files episode 13.
7. **Check names with run values.** The gate matches a failure to its
   rerun by name, so a name with a value read in the run never clears
   (fixed for the KeyTips check in 294c3ff1). Two more carry values:
   verify-ribbon.js's folded-group check (its label) and verify-pwfast.js
   (constants, harmless). Keep run values in the detail, not the name.

## Found while filming, 28 October

8. **Calendar names Kolkata by its old id.** The event's Time zone and
   View > Second time zone list Asia/Calcutta (and Asia/Saigon), because
   zoneChoices takes Intl.supportedValuesOf('timeZone') as it comes
   (apps/desktop/renderer/apps/calendar.js about lines 110-127) and ICU's
   canonical ids keep the old names. Someone in India sees "Asia/Calcutta
   (UTC+5:30)" and "in Calcutta". Map the old ids to today's
   (Asia/Kolkata, Asia/Ho_Chi_Minh, Europe/Kyiv and the rest of the
   links) and keep matching either.
9. **Two fields called Number in a print template.** Data Files' print
   template wizard on the Sales table labels both the ID and the Number
   field "Number", so a receipt reads "NUMBER 1 NUMBER S1001". The ID
   wants its own label (or leaving out when a Number field is there).
   Seen in the Data Files 16 film.
10. **Mail: a message already in the server's Junk folder never shows.**
    Delivered to Junk on the server before the start (the stand-in,
    packages/mailbox/test/imap-server.js, imap.deliver('Junk', raw)), it
    is not listed when Junk is opened, on the first visit or after Mark as
    junk; only messages moved there by Mark as junk show. The same seeding
    into INBOX shows. Cause not found; start at runFetch and syncFolder in
    apps/desktop/main/mail-sync.js (perhaps Junk is skipped as a special
    folder on the first sync). Seen in the Mail 3 shoot.
11. **Worksheets: a "-" item in Home > Cells > Format.** Between AutoFit
    column width and Protect sheet the menu draws an item reading "-":
    the sheets ribbon passes { label: '-' } (renderer ribbon.js about line
    439) where the menu's separator is the bare string '-' (office-ui
    index.js about line 1354). Still so on dev. Seen in Worksheets 2.

## Done on main, for the next release

12. **Mail's taskbar icon blank after an update.** The owner, 2026-10-28:
    no Mail icon on the taskbar since the update installed with Mail open,
    though the installed tile was whole. Windows keeps an icon by its path;
    each app's tile now reaches the taskbar as a copy named by its content
    in the profile's tiles folder (office afad3577,
    packages/office-shell/src/electron/taskbar-tile.js), so a changed or
    once-missed icon is read afresh. Proven on a dev run (Mail made
    tiles/mail-<hash>.ico); tests/taskbar-tile.test.js.
