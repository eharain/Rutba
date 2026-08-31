@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  Rutba — the ecosystem's one command. Delegates to management\devkit, the
REM  way the consumer line's dev-start.bat delegates to its own dev.cmd.
REM
REM    rutba              bind every port; boot each service on first request
REM    rutba erp          the same, with the consumer line's gateway alongside
REM    rutba doctor       what is missing, before anything starts
REM    rutba install      dependencies, for the repos you actually have
REM    rutba keygen       development secrets a service will not boot without
REM    rutba stop         release the ports in the chart, not every node.exe
REM    rutba up / down    shared infrastructure containers
REM    rutba list         what a profile covers, and where
REM    rutba status       what is running right now
REM ─────────────────────────────────────────────────────────────────────────
node "%~dp0management\devkit\rutba.mjs" %*
