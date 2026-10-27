# Rutba Office 2.21.0: the fixes and the pictures (plan)

The owner, 2026-10-27, after 2.20.0 went out and the survey of picture
formats and EXIF: "kindly plan a next release with fixes and most of the
recommended images support included" (D-2026-10-27-04).

2.21.0 is a minor release (it adds things people can do), so it takes the
full gate (D-2026-10-23-01). Size: about two weeks, three builders side by
side in clones, then the gate and the release in about two days.

## What 2.21.0 carries

### Part A. Fixes

1. **The slide show's taskbar flicker** (the owner, 2026-10-27). Done on
   Office main, b58c6fa1: full screen taken once for the show, not again
   on every slide; Reading View no longer goes full screen after a few
   slides. Two window checks, proven to fail on the old code.
2. **The installer's size.** 2.20.0's installer is 168 MB against the
   portable's 114 MB, which carries every app. Find how the installer's
   pack files are compressed (build/make-app-packs.js writes them as NSIS
   `File` lines) and bring it under 2.18.0's 143 MB; measure the update's
   download size from 2.20.0 with the blockmap too.
3. **The Mail fixture in the core.** apps/desktop/main/seed-mail.js
   imports @rutba/mailbox, now in Mail's pack, so the packaged smoke runs
   Mail with no messages. Move it into Mail's pack (or reach the mailbox
   through the pack), and make the packaged smoke fail on "seeding
   failed" instead of carrying on.
4. **Releases built by GitHub again** (the owner's decision): the pack
   key as the repository secret RUTBA_PACK_KEY, or every release built
   on this computer as 2.20.0 was. Either way release.yml stops before a
   long run when the key is missing, rather than failing after the tests.
5. **Gmail and Outlook sign-in, and Google Sheets as a source,** only if
   the owner's client ids arrive in time; otherwise in 2.22.
6. **A7.12** (the scanned invoice), only if the owner's sample arrives.
7. Every fault found while building this, and anything the owner reports
   from 2.20.0 in the meantime.

### Part B. One way to read a picture

`packages/imaging/src/decode.js`: `decodePicture(bytes, name)` answers
`{ width, height, pages, rgba or png, exif }` for every format below, in
the main process and the windows alike (pure JavaScript, no canvas), and
says plainly when it cannot. Everything else uses it:

- Pictures' main view: `rutba://file` (packages/office-shell/src/electron/
  protocol.js) serves a PNG made by decodePicture for a format Chromium
  does not draw, a page at a time for a multi-page file;
- Image's open (renderer/apps/image/layered.js) and the batch worker;
- Documents (packages/ooxml/src/document.js toDataUri), Worksheets
  (packages/drawing/src/shapes.js) and Presentations (apps/desktop/main/
  documents.js resolveImage), and the pictures the old .doc and .ppt
  readers already pull out (office-formats/src/msdoc.js).

Every decoder reads untrusted files, so each is bounded (size, pages,
pixels before allocating) and joins tools/fuzz-open.js: a damaged file is
a refusal in a sentence, never a hang or a crash.

### Part C. Picture formats

1. **TIFF everywhere, multi-page too.** UTIF.js (MIT, about 50 KB,
   vendored after its licence is checked): LZW, Deflate, PackBits, CCITT
   fax, JPEG-in-TIFF. Pictures shows a page strip for a multi-page TIFF
   (a fax, a scan); Image opens it (a page, chosen) and saves TIFF;
   Worksheets and Presentations draw an embedded TIFF.
2. **EMF drawings and WMF, as SVG.** `emfToSvg` beside `emfToPng` in
   packages/office-formats/src/emf.js, on the same record walk: objects
   (pens, brushes, fonts), paths, polylines and polygons, rectangles,
   ellipses, arcs, text from EMR_EXTTEXTOUTW with its advances, world
   transforms, clips, bitmaps as images. Then `wmf.js`, the 16-bit
   sibling, onto the same SVG writer. Drawn in all three document apps,
   in old .doc and .ppt files, and opened by Pictures (.emf, .wmf). EMF+
   records stay unread; a dual file draws from its ordinary records.
   This is the largest part: about a week.
3. **Small formats of our own, no library:** QOI, PNM (PBM, PGM, PPM),
   TGA, PCX, Radiance HDR (tone-mapped), and .cur beside .ico. Pictures
   lists and opens them; Image opens them.
4. **Image saves more:** BMP, ICO (PNG inside) and TIFF beside PNG, JPEG
   and WebP; Image opens SVG (drawn at a chosen size) and ICO.
5. **HEIC, HEIF, camera RAW and JXR through Windows' own codecs,** at the
   screen's size rather than the 512 px tile, where Windows has the codec
   (HEIF and RAW extensions from the Store); a RAW or DNG without one
   shows the full-size JPEG its camera put inside it. No HEIC decoder is
   bundled (HEVC patents). First a day's trial of the quality Windows
   gives at 2048 px; if it is poor, this part waits.
6. **Photoshop PSD, flattened,** with ag-psd (MIT, about 200 KB): Pictures
   shows it and Image opens it as one picture. Its layers in Image wait
   for 2.22.

Not in 2.21 (later): JPEG 2000 (through the openjpeg.wasm pdf.js already
ships), JPEG XL (first a test of what Electron 44 draws itself), AVIF and
animated GIF saving, EMF+, PSD layers. Not planned: a bundled HEIC
decoder, Ghostscript for EPS (an EPS shows its embedded preview instead,
if it is quick), CGM, XPS.

### Part D. EXIF

1. **Read from more files:** PNG (eXIf), WebP (EXIF chunk), HEIC and AVIF
   (the Exif item) beside JPEG and TIFF (packages/imaging/src/exif.js).
2. **Remove location only:** on Image's export and in Pictures' batch
   edit, a choice beside Strip all: the GPS block taken out, the camera's
   details kept.
3. **EXIF kept on more exports:** JPEG, WebP and TIFF exports keep the
   original's EXIF (orientation reset, as now), from a layered picture
   too; PNG keeps it as eXIf.
4. **Windows' own stars and tags, read:** the EXIF Rating and the XMP
   rating and keywords that Windows Photos and Lightroom write show in
   Pictures beside its own. Writing them back to the file, and editing
   date taken, caption, artist and copyright, wait for 2.22.

## Builders and order

Each builder works in a clone of its own (office-parallel-clones), never
two on the same files; the lead merges onto Office main, writes the note,
runs the gate and releases.

| Builder | Clone | Parts | Files it owns |
| --- | --- | --- | --- |
| pictures | office-pictures | B, C1, C3, C4, C6 | packages/imaging (decode.js and new decoders), protocol.js, Image's open and export, Pictures' lists and page strip |
| metafile | office-metafile | C2 | packages/office-formats/src/emf.js and wmf.js, their wiring in document.js, shapes.js, documents.js, msdoc.js |
| exif | office-exif | D, C5 | packages/imaging/src/exif.js, the batch edit's choices, Pictures' details and stars, the platform view |
| lead | Office main | A | the fixes, the note, translations, the gate |

Order: B's `decodePicture` first (two days), since C2 and C5 hand their
pictures to it; the metafile builder starts C2's SVG writer at once,
which needs nothing of B, and wires it in once B is merged. The pictures
and exif builders share packages/imaging: exif.js and decode.js are
separate files, and the pictures builder alone touches index.js.

## Proof

- Engine tests for each decoder, on files made at test time and on small
  public samples (their source and licence in tests/corpus-public/
  SOURCES.json), and for emfToSvg against the EMFs the suite already
  writes.
- The corpus: the C3 documents and the owner's files in D:\Apps-reserch
  (read in place) counted for embedded pictures drawn before and after;
  open rate and round trips unchanged. Add public TIFF, EMF, WMF, PSD,
  QOI, PNM and TGA samples to the C3 set.
- Window checks: Pictures opens a multi-page TIFF and steps its pages;
  Image opens TIFF and PSD and saves BMP, ICO and TIFF; Documents,
  Worksheets and Presentations show an EMF and a WMF drawn; Remove
  location keeps the camera.
- tools/fuzz-open.js over every new decoder, the count in the note.
- The full gate, candidate.yml before publishing, upgrade.yml from 2.20.0
  after.

## For the owner

- The pack key for GitHub (A4): add it as a repository secret, or keep
  building releases here.
- The Gmail and Outlook client ids and the scanned invoice, if they are
  to make 2.21.
- Whether PSD's layers in Image can wait for 2.22 (the plan says yes).
