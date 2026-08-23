@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  Rutba - native desktop apps from anywhere under D:\Rutba2.0.
REM
REM    native-apps build              install workspaces + Electron
REM    native-apps test               the @rutba/sync test suites
REM    native-apps pos|mail|studio    run that desktop shell
REM
REM  Thin wrapper, same convention as dev.cmd / rutba.cmd: one real script per
REM  job inside the repo, a wrapper where a developer happens to be standing.
REM ─────────────────────────────────────────────────────────────────────────
set "NATIVE=%~dp0native-apps"

if /i "%~1"=="build"  ( call "%NATIVE%\native-build.bat" %2 & exit /b %errorlevel% )
if /i "%~1"=="test"   ( call "%NATIVE%\native-build.bat" test & exit /b %errorlevel% )
if /i "%~1"=="pos"    ( call "%NATIVE%\apps\rutba-pos-desktop\run.bat" & exit /b %errorlevel% )
if /i "%~1"=="mail"   ( call "%NATIVE%\apps\rutba-mail-desktop\run.bat" & exit /b %errorlevel% )
if /i "%~1"=="studio" ( call "%NATIVE%\apps\rutba-studio-desktop\run.bat" & exit /b %errorlevel% )

echo usage: native-apps build ^| test ^| pos ^| mail ^| studio
exit /b 1
