@echo off
echo ========================================
echo  MAESTRO E2E TEST RUNNER
echo ========================================
echo.

REM Check Maestro
where maestro >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Maestro not installed!
    echo.
    echo Install on Windows:
    echo   1. Install scoop: irm get.scoop.sh ^| iex
    echo   2. Install maestro: scoop bucket add nicehash https://github.com/nicehash/scoop-bucket ^& scoop install maestro
    echo   OR download from: https://github.com/nicehash/scoop-bucket
    echo.
    echo Alternative - use npm:
    echo   npm install -g @nicehash/maestro
    echo.
    echo Or manual download:
    echo   https://maestro.mobile.dev/getting-started/installing-maestro
    pause
    exit /b 1
)

echo Maestro version:
maestro --version
echo.

REM Check device
echo Connected devices:
adb devices -l 2>nul
echo.

REM Run all flows
set FLOWS_DIR=C:\Users\Karim\AndroidStudioProjects\MyApplication\.maestro
set PASS=0
set FAIL=0
set TOTAL=0

for %%f in (%FLOWS_DIR%\flow*.yaml) do (
    set /a TOTAL+=1
    echo ────────────────────────────────────
    echo Running: %%~nf
    echo ────────────────────────────────────
    maestro test "%%f"
    if %ERRORLEVEL% EQU 0 (
        echo [PASS] %%~nf
        set /a PASS+=1
    ) else (
        echo [FAIL] %%~nf
        set /a FAIL+=1
    )
    echo.
)

echo ========================================
echo  RESULTS: %PASS% passed, %FAIL% failed, %TOTAL% total
echo ========================================
pause

