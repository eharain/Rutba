@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  Rutba — release the ecosystem's dev ports.
REM
REM  Only the ports in the chart, never every node.exe. See
REM  management\devkit\scripts\dev-stop.mjs for what it claims and what it
REM  refuses to touch.
REM
REM    dev-stop.bat             release the ports in the chart
REM    dev-stop.bat --dry-run   list what would be stopped, kill nothing
REM    dev-stop.bat --erp       also hand over to consumer\devkit\dev-stop.bat
REM ─────────────────────────────────────────────────────────────────────────
call "%~dp0management\devkit\dev-stop.bat" %*
