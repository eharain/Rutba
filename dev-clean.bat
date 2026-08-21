@echo off
setlocal
rem ============================================================
rem  Rutba 2.0 - clean regenerable build caches across the estate.
rem
rem  Deletes every .next directory (outside node_modules) plus the
rem  api/core scratch dir. Everything removed here is gitignored and
rem  rebuilt on the next dev run - the only cost is a cold first build.
rem
rem  Tip: run dev-stop.bat first if dev servers are running, or some
rem  caches will be locked and skipped.
rem ============================================================
cd /d "%~dp0"
set COUNT=0
echo Cleaning .next build caches under %CD% ...
for /f "delims=" %%D in ('dir /b /s /a:d .next 2^>nul ^| findstr /v /i /c:"\node_modules\"') do (
    rd /s /q "%%D" 2>nul
    if exist "%%D" (
        echo   LOCKED   %%D   ^(dev server running? try dev-stop.bat^)
    ) else (
        set /a COUNT+=1
        echo   cleaned  %%D
    )
)
if exist "consumer\api\core\.tmp" (
    rd /s /q "consumer\api\core\.tmp" 2>nul
    echo   cleaned  %CD%\consumer\api\core\.tmp
)
echo.
echo Done - %COUNT% .next cache(s) removed.
endlocal
