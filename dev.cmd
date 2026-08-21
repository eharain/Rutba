@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  Rutba — start the ecosystem from anywhere under D:\Rutba2.0.
REM
REM  Delegates to management\devkit\dev.cmd, the way rutba.cmd delegates to
REM  rutba.mjs and the ERP's dev-start.bat delegates to its own dev.cmd. One
REM  real script, thin wrappers where a developer happens to be standing.
REM
REM    dev            every port bound, services booted on first request
REM    dev portal     the control plane only
REM    dev erp        with the ERP's own gateway alongside
REM    dev full       every product that is cloned and installed
REM
REM  The ERP line keeps its own dev.cmd (consumer\devkit\dev.cmd) and it still
REM  works on its own. Nothing here is a prerequisite for running a single app
REM  directly in its own repo.
REM ─────────────────────────────────────────────────────────────────────────
call "%~dp0management\devkit\dev.cmd" %*
