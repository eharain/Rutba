# Rutba Office 2.23: list

Started after 2.22.0 was released (2026-11-03, tag v2.22.0 at office
18f352f4). Each item says what is asked, what is there today, and where in
the code. The release plan that turns these into one release (5 Nov 2026,
for the owner's review) is kept locally in private/OFFICE-2.23-RELEASE-PLAN.md,
with its screens on the owner's design canvas.

## Video

1. **Compact and smaller exports.** Owner, 4 Nov 2026, relayed by the
   LinkedIn and Youtube update session: "in our office video tool we should
   request to add feature to export compact and smaller sized videos as
   well." Why: the Rutba Relay intro film (85.6 s, 1080p, 30 fps) came out
   of Export at about 9.7 Mb/s, 98.8 MB. TikTok's app review takes 50 MB
   at most and Bluesky 100 MB, so copies were made outside Office with
   ffmpeg (two-pass H.264 at 3.9 Mb/s plus AAC 160 kb/s gave 41.5 MB, clean
   at 1080p) and D:\videos\_tools\bluesky.mjs.
   What is there (apps/desktop/renderer/apps/video/export.js 263-330,
   packages/studio/src/presets.js 23-28): "Made for" presets (project,
   YouTube 10 Mb/s, wide and square social, vertical, email 480p at
   0.9 Mb/s with a 20 MB warning); a Quality list (High, Medium, Low
   (smaller file)) for the project preset only; a size estimate for every
   preset except the project's own, which has no fixed bitrate.
   What to add:
   - Presets "Compact" (1080p, about 4 Mb/s) and "Small" (720p, about
     2 Mb/s) in Made for.
   - "Fit under" a size (50 MB, 100 MB, 287 MB, or a number typed): the
     bitrate worked out from the length and the sound's share. The encoder
     is single pass (WebCodecs, hardware where it can), so aim about 8%
     under, check the written file, and if it is still over, encode again
     lower and say so. Say when the size asked would need a picture too poor
     to watch (under about 1 Mb/s at 1080p: suggest 720p).
   - The size estimate shown for every choice, the project preset with its
     Quality included.
   Checks: a verify:apps block exporting a short project with each new
   preset and a 5 MB fit, file sizes read back; presets.js unit tests for the
   bitrate sums.

## Mail

2. **Gmail sign-in with Rutba Office's own Google client.** Owner, 4 Nov
   2026: "when you are already there kindly create a client id for rutba
   office mail to login to gmail . coordinate with rutba office session",
   then "keep rutba office mail app id seperate from relay". The LinkedIn
   and Youtube update session makes a Desktop app client in a Google Cloud
   project of its own, "Rutba Office". The sign-in is built (Mail since
   1.50.0, apps/desktop/main/oauth.js: PKCE, loopback redirect on
   127.0.0.1, scope https://mail.google.com/), but no build carries an id.
   To do: ship the client id in the build; send a client secret with the
   code exchange and the refresh (Google refuses a Desktop client's
   exchange without one; a new key oauth.google.clientSecret, kept in
   Rutba-private until the owner says how it is kept); ask for openid and
   email too, so the address is read from the id token (oauth.js 207);
   update docs/OAUTH.md, which says no secret is needed. Publishing to
   everyone needs Google's verification of a restricted scope (and a yearly
   security assessment); until then, at most 100 users and a warning page.
3. **office.rutba.io privacy policy: Gmail.** Google's review reads it, and
   today it does not mention Gmail or Google user data. Add a section: only
   the refresh token is kept, encrypted in the operating system's keystore;
   mail goes between the computer and Gmail with no Rutba server between;
   signing out deletes the token here; the Google API Limited Use
   statement. Goes live through Infra on the owner's go.

   Item 2 done on Office main 6fa5087c (4 Nov): the client "Rutba Office
   Mail (desktop)" is in Google Cloud project rutba-office (Testing, test
   user eharain@gmail.com, scopes mail.google.com, openid, userinfo.email).
   A release build reads Google's download from RUTBA_GOOGLE_CLIENT_FILE
   (build/make-oauth-clients.js) into resources/oauth/clients.json; Mail
   sends the id and secret on the exchange and each refresh, and removing a
   signed-in account now deletes its refresh token (it did not). Tests
   oauth-clients 7; engine tests 3,546 pass, 0 fail. The owner chose "Read
   it where it is": the build reads the file at D:\TrustList\private, and no
   copy is made. Test build 2.23.0-test.1 (portable, not released) made 4 Nov
   in apps/desktop/release/gmail-test (private/office-release-tools/
   gmail-test-build.sh). The packed client was checked, and Mail and Home
   rendered clean on a scratch profile. Handed to the LinkedIn session for the
   owner to sign in with eharain@gmail.com. 5 Nov: the owner said "i can do
   nothing about gmail test": every app was refused, since the packs were
   2.22.0 and the core 2.23.0-test.1 (the smoke report missed it). Rebuilt
   with the packs at 2.23.0-test.1 (private/office-release-tools/
   make-test-packs.mjs); all 16 packs load, Mail opens, started for the owner
   with "Try Gmail in Rutba Office.cmd" beside the exe.
   Item 3 written in management 736bd055 (dev and main), live with the next
   sites deploy on the owner's go through Infra.

## Recorder and Live Broadcast

4. **Rethink how both are used.** Owner, 5 Nov 2026: "the recorder and live
   broadcast user experience need proper rethinking as their current
   usability imposes lots of limits. there needs to be simplicity and
   advance use and state saving as well."
   Today (office main, apps/desktop/renderer/studio/window.js): one studio
   window for both, every control showing at once (Picture, Go Live, Record,
   the Video and Sound switches, the source bar, scenes, and in Live
   Broadcast the Next and On air frames with Cut, Fade, Preview, Follow the
   speaker and Rotate). What is kept is one stack and one settings set per
   app (shell.store recorder.stack, recorder.studio), restored on open. A
   window source is kept by its capture id, which changes when that window's
   app restarts, so a kept window is lost; there are no named setups, and at
   most 9 scenes. A proposal goes to the owner before any build.
   Decided: D-2026-11-05-13 (named setups, also as files, shared by both
   apps) and D-2026-11-05-14 (two panels, Set up and Record, Set up and
   Live; opens ready on Record or Live). Build order: 1 setups and reliable
   restore, 2 the two panels, 3 Set up's layout tools and live switching.
   Talk (D-2026-11-05-15, plan only): Talk contacts as guests in Set up, the
   studio's picture into a Talk call, recording Talk calls, and web guests
   later. Setups get no guest slots until the owner says build.
   Planning first (D-2026-11-05-16, owner: "we will build a single decent
   sized release after we have planned it"): nothing is built until the
   whole plan is written and agreed, then one release carries it.

## Home

5. **Two sets side by side: Office and Studio** (D-2026-11-05-17). Owner,
   5 Nov 2026: "our all aps view has gone very media heavy as well. how about
   we split that view between two of our core app sets by their
   functionality as well." Office: Mail, Calendar, Contacts, Talk,
   Documents, Worksheets, Presentations, PDF, Data Files. Studio: Pictures,
   Image, Video, Recorder, Live Broadcast. Each column has its tiles and its
   own Start something; Recent below both; the same names in the app menu,
   Choose apps, the installer and office.rutba.io. Today: registry.js
   APP_GROUPS has office (with Pictures) and more (with Talk and Data Files);
   apps-choice.js titles them "Office apps", "More apps", "Add-ons"; home.js
   shows one flat grid; Record a screen opens Video.

## Fixes

6. **AI Tools and Live Broadcast packs not starting** (D-2026-11-05-18,
   looked at in the release build). The released 2.22.0 build (apps/desktop/
   release/win-unpacked), smoke-run on a fresh profile, and the 2.23.0-test.1
   build both show "could not be started: protocol.registerSchemesAsPrivileged
   should be called before app is ready" for the two packs. Both import
   @rutba/office-shell/electron/main, which registers the scheme when it is
   evaluated; packs carrying code find the core's packages through
   office-shell/src/electron/pack-resolve.js. The owner's installed 2.22.0
   starts all 16 with nothing logged.
