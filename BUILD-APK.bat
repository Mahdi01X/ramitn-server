@echo off
title RamiTN - Build APK
cd /d "%~dp0mobile"

echo [1/3] flutter pub get...
call flutter pub get
if %ERRORLEVEL% neq 0 (
    echo ERREUR: flutter pub get a echoue
    pause
    exit /b
)

echo.
echo [2/3] Generation des icones...
call dart run flutter_launcher_icons
echo.

echo [3/3] Build APK release...
call flutter build apk --release --target-platform android-arm64

echo.
echo ============================================
if %ERRORLEVEL% equ 0 (
    echo   BUILD REUSSI !
    echo   APK: mobile\build\app\outputs\flutter-apk\app-release.apk
) else (
    echo   BUILD ECHOUE - voir les erreurs ci-dessus
)
echo ============================================

pause

