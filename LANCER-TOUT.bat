@echo off
title Rami Tunisien - TOUT EN UN
color 0A
echo.
echo ============================================
echo   RAMI TUNISIEN - Lancement complet
echo ============================================
echo.

:: 1. Start server in background
echo [1/2] Demarrage du serveur...
cd /d "%~dp0simple-server"
start "Rami Server" /min cmd /c "node server.js"
timeout /t 2 /nobreak >nul
echo      Serveur demarre sur le port 3000 ✓
echo.

:: Show IPs
echo ============================================
echo   ADRESSES POUR L'APP:
echo ============================================
echo.
echo   Emulateur:  http://10.0.2.2:3000
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do echo   Meme WiFi:  http://%%a:3000
echo   Distance:   Lance ngrok http 3000
echo.
echo ============================================
echo.

:: 2. Start Flutter
echo [2/2] Demarrage de l'app Flutter...
cd /d "%~dp0mobile"
flutter run

pause

