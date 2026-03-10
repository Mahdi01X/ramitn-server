@echo off
echo ========================================
echo  RAMI TN - FULL PIPELINE EXECUTION
echo ========================================
echo.

REM Step 1: Shared Engine Tests
echo [STEP 1] Running shared engine tests...
cd /d C:\Users\Karim\AndroidStudioProjects\MyApplication\shared
call npx jest --no-coverage --forceExit 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [FAIL] Shared engine tests FAILED
) else (
    echo [PASS] Shared engine tests PASSED
)
echo.

REM Step 2: Flutter Build APK
echo [STEP 2] Building Flutter APK...
cd /d C:\Users\Karim\AndroidStudioProjects\MyApplication\mobile
call flutter build apk --release 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [FAIL] Flutter build FAILED
) else (
    echo [PASS] Flutter build PASSED
)
echo.

REM Step 3: Check Maestro
echo [STEP 3] Checking Maestro installation...
where maestro >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Maestro not found. Installing...
    echo Please install Maestro manually:
    echo   PowerShell: iwr -useb https://get.maestro.mobile.dev ^| iex
    echo   Or download from: https://maestro.mobile.dev/getting-started/installing-maestro
    echo.
    echo After installing, run:
    echo   maestro test C:\Users\Karim\AndroidStudioProjects\MyApplication\.maestro\
) else (
    echo Maestro found!
    maestro --version
    echo.

    REM Step 4: Check for connected device/emulator
    echo [STEP 4] Checking connected devices...
    adb devices
    echo.

    REM Step 5: Install APK on device
    echo [STEP 5] Installing APK on device...
    adb install -r C:\Users\Karim\AndroidStudioProjects\MyApplication\mobile\build\app\outputs\flutter-apk\app-release.apk
    echo.

    REM Step 6: Run Maestro flows
    echo [STEP 6] Running Maestro flows...
    echo.

    echo --- Flow 1: Smoke Test ---
    maestro test C:\Users\Karim\AndroidStudioProjects\MyApplication\.maestro\flow1_smoke_test.yaml 2>&1
    echo.

    echo --- Flow 4: Rules Screen ---
    maestro test C:\Users\Karim\AndroidStudioProjects\MyApplication\.maestro\flow4_rules_screen.yaml 2>&1
    echo.

    echo --- Flow 7: Frich Vote ---
    maestro test C:\Users\Karim\AndroidStudioProjects\MyApplication\.maestro\flow7_frich_vote.yaml 2>&1
    echo.

    echo --- Flow 6: Quit Dialog ---
    maestro test C:\Users\Karim\AndroidStudioProjects\MyApplication\.maestro\flow6_quit_dialog.yaml 2>&1
    echo.

    echo --- Flow 5: Scoreboard ---
    maestro test C:\Users\Karim\AndroidStudioProjects\MyApplication\.maestro\flow5_scoreboard.yaml 2>&1
    echo.

    echo --- Flow 2: Gameplay Round ---
    maestro test C:\Users\Karim\AndroidStudioProjects\MyApplication\.maestro\flow2_gameplay_round.yaml 2>&1
    echo.

    echo --- Flow 3: Audio Selector ---
    maestro test C:\Users\Karim\AndroidStudioProjects\MyApplication\.maestro\flow3_audio_selector.yaml 2>&1
    echo.

    echo --- Flow 8: Extended Gameplay ---
    maestro test C:\Users\Karim\AndroidStudioProjects\MyApplication\.maestro\flow8_extended_gameplay.yaml 2>&1
    echo.

    echo --- Flow 9: Online Mode ---
    maestro test C:\Users\Karim\AndroidStudioProjects\MyApplication\.maestro\flow9_online_mode.yaml 2>&1
    echo.

    echo --- Flow 10: Setup Variants ---
    maestro test C:\Users\Karim\AndroidStudioProjects\MyApplication\.maestro\flow10_setup_variants.yaml 2>&1
    echo.
)

echo ========================================
echo  PIPELINE COMPLETE
echo ========================================
pause

