@echo off
title RamiTN - Build complet
color 0A
cd /d "%~dp0mobile"

echo ============================================
echo   RamiTN - Build complet
echo ============================================
echo.

echo [1/4] Nettoyage...
call flutter clean
echo.

echo [2/4] Installation des dependances...
call flutter pub get
if %ERRORLEVEL% neq 0 (
    echo ERREUR: flutter pub get a echoue
    pause
    exit /b
)
echo.

echo [3/4] Generation des icones du logo...
call dart run flutter_launcher_icons
echo.

echo [4/4] Build APK release...
call flutter build apk --release --target-platform android-arm64
echo.

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo ============================================
    echo   BUILD REUSSI !
    echo.
    echo   APK: build\app\outputs\flutter-apk\app-release.apk
    echo ============================================
    echo.
    echo Ouverture du dossier de l'APK...
    explorer "build\app\outputs\flutter-apk"
) else (
    echo BUILD ECHOUE - voir les erreurs ci-dessus
)

pause
