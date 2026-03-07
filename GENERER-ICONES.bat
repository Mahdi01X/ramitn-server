@echo off
title RamiTN - Generer les icones
cd /d "%~dp0mobile"

echo ============================================
echo   Generation des icones RamiTN
echo ============================================
echo.

echo [1/2] Installation des dependances...
call flutter pub get
echo.

echo [2/2] Generation des icones a partir de unnamed.jpg...
call dart run flutter_launcher_icons
echo.

if %ERRORLEVEL% equ 0 (
    echo ============================================
    echo   ICONES GENEREES AVEC SUCCES !
    echo   Tu peux maintenant builder l'APK:
    echo   cd mobile
    echo   flutter build apk --release
    echo ============================================
) else (
    echo ERREUR lors de la generation des icones.
)

pause

