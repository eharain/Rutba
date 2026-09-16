@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  Rutba — clear the regenerable build output across the whole estate.
REM
REM  Delegates to management\devkit\dev-clean.bat, the way dev.cmd delegates to
REM  management\devkit\dev.cmd and dev-stop.bat to its own. One real script,
REM  thin wrappers where a developer happens to be standing.
REM
REM  Every repo and every directory under them: .next and .next-verify,
REM  dist/out/build, coverage, bundler caches, .tmp and .dev scratch, test
REM  reports, and the *.tsbuildinfo and *.log files beside them. A path is
REM  removed only if the repo that owns it says git ignores it, so tracked
REM  source that happens to be named `build` or `screens` is never touched.
REM
REM    dev-clean.bat             clean
REM    dev-clean.bat --dry-run   list what would go, with sizes; remove nothing
REM    dev-clean.bat --releases  also the packaged Office installers
REM    dev-clean.bat --modules   also node_modules (reinstall everywhere after)
REM
REM  Run dev-stop.bat first if dev servers are running, or the caches they hold
REM  open are reported LOCKED instead of removed.
REM ─────────────────────────────────────────────────────────────────────────
call "%~dp0management\devkit\dev-clean.bat" %*
