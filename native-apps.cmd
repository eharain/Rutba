@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  Rutba - native desktop apps from anywhere under D:\Rutba2.0.
REM
REM    native-apps build              install workspaces + Electron
REM    native-apps test               the native-apps test suites
REM    native-apps <app> [local]      run the one shell as that app (crm, pos ...)
REM
REM  Thin wrapper, same convention as dev.cmd / rutba.cmd: one real script per
REM  job inside the repo, a wrapper where a developer happens to be standing.
REM ─────────────────────────────────────────────────────────────────────────
set "NATIVE=%~dp0native-apps"

if /i "%~1"=="build"  ( call "%NATIVE%\native-build.bat" %2 & exit /b %errorlevel% )
if /i "%~1"=="test"   ( call "%NATIVE%\native-build.bat" test & exit /b %errorlevel% )

if not "%~1"=="" ( call "%NATIVE%\apps\rutba-desktop\run.bat" %1 %2 & exit /b %errorlevel% )

echo usage: native-apps build ^| test ^| ^<app^> [local]
exit /b 1
