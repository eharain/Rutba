# Rutba Office 2.24: list

Items asked for after the 2.23 plan was written (5 Nov 2026). The owner has
not set 2.24's scope. Each item says what is asked, what is there today, and
what is proposed.

## Locker

1. **A Locker for files that matter** (D-2026-11-05-20 to -25). Not tied
   to 2.24 or any release. Owner: "we will build locker and will only release
   it once's it fully and completely build and we feel confident that this is
   the version we can base upon. so no decision on it about version it goes
   in." It is listed here only because this list is where it was first
   written down.
   Owner, 5 Nov 2026: "with increasing security threats keeping few important
   files safe is very important so what do you think providing a secure file
   locker in office with ability to lock and unlock files from it with
   password or with windows pin tool?" Then: "I think the first version should
   be directory add to locker and any files in that directory or selected
   extensions automatically are locked individually and kept in there the
   Rutba office should be able to open these with windows pin or password. can
   export etc. we can implement git concept to ignore include and exclude
   import export etc and support with cli?" And: "all to deicide should be left
   to the end user."

   What is there today (office main): password protection in each format's
   own way. PDF reads every standard security handler revision (RC4 to
   AES-256) and saves keeping the protection (packages/pdf/src/security.js).
   .docx, .xlsx and .pptx open with Agile or Standard encryption and save with
   Agile AES-256, SHA-512 and 100,000 rounds (packages/office-formats/src/
   crypt.js). .doc, .xls and .ppt open with RC4 or XOR
   (crypt-binary.js). Hashing runs off the document service's thread
   (apps/desktop/main/password-host.js). Office has no locker, no Windows
   Hello and no command line tool.

   Proposed (session, not yet agreed in its details):
   - **Folders.** Locker › Add folder, or Lock with Rutba Office on a folder
     in Explorer. The folder stays where it is, synced or not. Files that
     match its rules are locked one by one as they arrive while Rutba Office
     runs (it waits in the tray). Files added while it is closed are locked at
     the next start and shown as waiting until then.
   - **Opening.** Double-click in Explorer or open from any Office app. One
     unlock (Windows PIN or password) lasts until the locker locks: after an
     idle time the person sets, on sleep, or when Windows locks. Documents,
     worksheets, presentations, PDFs and pictures open into Rutba Office in
     memory, and saves are written straight to the locked file. Other file
     types get a temporary copy, wiped on lock.
   - **Keys.** The password is the master and works on any computer. The PIN
     (Windows Hello) unlocks on this computer only, through a small native
     helper, since Electron has no Windows Hello support. A recovery key is
     given at setup. A forgotten password with no recovery key means the files
     cannot be opened, and the Locker says so.
   - **The engine** (D-2026-11-05-22). Owner: "for actual locking we build
     c/c++ port of our secure key store and enhance it with cli", then "and use
     git or some thing more suitable to provide the rest."
     - Today: @tech-style/secure-keystore 3.0 (MIT, eharain/secure-keystore)
       has six implementations (JavaScript, Go, .NET, Python, PHP, Rust)
       written against SPEC.md and checked by conformance/. A store is a
       directory with a master key unlocked by PBKDF2-SHA256 (600,000 rounds)
       from the user key, and each value has an HKDF key and is sealed with
       AES-256-GCM, its context bound in. Office already uses it for each
       profile's saved passwords, with the key wrapped by DPAPI
       (packages/office-shell/src/profile-keystore.js).
     - Then the owner: "we already have js version that can be more suitable
       for rutba office" (D-2026-11-05-23). So in Office the Locker runs on
       the JavaScript package Office already ships, extended, using only
       node:crypto (AES-GCM, PBKDF2, HKDF are all there). Only Windows Hello
       needs native code, a small addon (WinRT KeyCredentialManager). A C/C++
       port, a seventh implementation against SPEC.md, stays possible later
       for opening a locker without Office.
     - Extensions, as SPEC.md 3.1, made first in the JavaScript package (the
       other five may decline them):
       - **Unlockers.** master.json can hold more than one way to open the
         master key: the password (as today), Windows Hello on this computer,
         and the recovery key.
       - **Files.** A file record is a key from HKDF of the master key with
         the file's own salt. The file is sealed in 64 KB chunks of
         AES-256-GCM. Each chunk's nonce and associated data carry the file,
         the chunk's number and a last-chunk flag, so chunks cannot be
         swapped, reordered or cut off.
     - The command line: `rutba-locker` (name to confirm) is the package's
       own command line (it has one today) grown with the Locker's verbs. It
       is run by Office's own runtime (the Office program started as Node), so
       nothing else is installed.
     - **"The rest": git's model, not git** (session-proposed).
       - Git itself does not suit a folder that OneDrive or Dropbox syncs:
         a .git folder inside a synced drive corrupts when two computers write
         it, git keeps each version of a large file whole, and encrypted
         versions do not shrink to differences.
       - Instead the engine keeps git's ideas: objects that never change once
         written and are named by their content; large files cut into pieces
         at points their content decides (FastCDC, a published algorithm,
         written in the package; casync is LGPL, so not used); a small list per
         version of each file, written as a new file each time, so two
         computers never rewrite the same file.
       - The verbs follow git's: status, log, restore, plus the
         `.rutbalocker` rules in gitignore wording.
       - Owner: "i meant gits way of working but our own way and not many
         versions kept" (D-2026-11-05-24). Few versions: by default the
         current one and the two before it, fewer if the person chooses, down
         to the current one only. Pieces that no kept version uses are removed
         straight away, so a locker stays close to the size of its files.
   - **Format.** Each file is locked on its own and encrypted in 64 KB chunks
     (AES-256-GCM, a key per file, the master key from the password by
     scrypt), so Dropbox and OneDrive upload only the blocks that changed.
     Files over about 50 MB become a small folder of content-named pieces of
     1 to 4 MB, cut where their content decides, plus a list, so every drive,
     Google Drive included, uploads only new pieces. Writes go to a
     temporary file and are then swapped in. Pieces never change once written.
     Conflict copies made by a drive are found and shown side by side, never
     merged. The format is to be published.
   - **Nothing private in the synced folder.** The owner asked whether the
     drives' own ignore lists could keep our working files out of the cloud.
     Only some can, and none reads an ignore file we could ship:
     - Dropbox: a supported per-file marker, `com.dropbox.ignored`.
     - OneDrive: only through an administrator policy, for work and school
       accounts.
     - Google Drive: nothing supported.
     - iCloud Drive: `.nosync` names, on a Mac.

     So the synced folder holds only locked files and the rules file.
     Temporary unlocked copies, unlock state, caches and half-written files
     stay in Office's own profile folder. The finished locked file is swapped
     in as the only write into the synced folder. Add to locker and saving
     from Rutba Office write only the locked copy there. Where Dropbox's
     marker is available, it is set on the Locker's own working files too,
     as an extra safety net.
   - **Rules.** `.rutbalocker` at the folder's top, in gitignore wording: lines
     say what to lock, `!` makes exceptions, and a subfolder's file overrides
     its parent's. With none, everything but the temporary and system files
     Office and Windows make (`~$*`, `*.tmp`, `desktop.ini`, `Thumbs.db`).
     `status` and `why <file>` say what is locked, waiting or excluded, and by
     which rule.
   - **The person decides** (D-2026-11-05-21), asked when a folder is added
     with a suggested choice, and changeable later. Hidden file names in the
     cloud (suggested) or visible. Plain originals deleted once locked
     (suggested) or kept. Also the idle time before the locker locks, and
     whether a folder's documents use our format or their own format's
     password, which Microsoft Office and Acrobat can open elsewhere.
   - **Import and export.** Import (lock files brought in); Export copy (an
     unlocked copy elsewhere); Export to share (one locked file with a
     password of its own); Unlock for good; Remove folder (unlocks first).
   - **Command line.** `rutba-locker` (name to confirm), shipped with Office
     and working without the app open: add, status, why, lock, unlock,
     export, import, change-password, recovery. The PIN or password is read at
     the prompt or from standard input, never from an argument.
   - **Said plainly in the app.** A file added from outside may reach the
     cloud before it is locked, and drives keep old versions, so locking a
     folder already in the cloud leaves plain copies in its version history:
     the Locker warns and links to that drive's version history. Deleting a
     plain file does not reliably erase it from an SSD. The Locker protects
     files at rest, not against malware running as the person while unlocked.
   - **Before it is called secure** on the site: an outside security review
     (owner to decide).
   - Checks: unit tests for the format (chunks, pieces, wrong password,
     tampering, conflict copies), the rules (gitignore cases) and the
     command line. A verify:apps block that adds a folder, locks a dropped
     file, opens and saves it from Documents, exports it and unlocks it.
     Upload sizes measured on OneDrive, Google Drive and Dropbox after a small
     change to a large file.
