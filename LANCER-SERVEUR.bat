@echo off
title Rami Tunisien - Serveur
color 0E
echo.
echo ============================================
echo   RAMI TUNISIEN - Serveur de jeu en ligne
echo ============================================
echo.

cd /d "%~dp0simple-server"

:: Verify node is installed
where node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERREUR: Node.js n'est pas installe!
    echo Telecharge-le sur https://nodejs.org
    pause
    exit /b
)

:: Install if needed
if not exist "node_modules" (
    echo Installation des dependances...
    call npm install
    echo.
)

:: Show local IP
echo ============================================
echo   ADRESSES DE CONNEXION:
echo ============================================
echo.
echo   EMULATEUR ANDROID:
echo   http://10.0.2.2:3000
echo.
echo   MEME WIFI (ton IP locale):
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do echo   http://%%a:3000
echo.
echo   A DISTANCE: lance ngrok dans un autre terminal:
echo   ngrok http 3000
echo   puis utilise l'URL ngrok dans l'app
echo.
echo ============================================
echo.
echo Serveur demarre! Ne ferme pas cette fenetre.
echo.

node server.js

pause

