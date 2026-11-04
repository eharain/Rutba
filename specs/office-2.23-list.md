# Rutba Office 2.23: list

Started after 2.22.0 was released (2026-11-03, tag v2.22.0 at office
18f352f4). Not a plan: the owner has not set 2.23's scope. Each item says
what is asked, what is there today, and where in the code.

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
   oauth-clients 7; engine tests 3,546 pass, 0 fail. Waiting: where the
   build reads the owner's file from (it is at D:\TrustList\private, outside
   the estate), then a build for the owner to sign in with.
   Item 3 written in management 736bd055 (dev and main), live with the next
   sites deploy on the owner's go through Infra.
