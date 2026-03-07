@echo off
title RamiTN - Serveur
color 0A

echo ============================================
echo   RamiTN - Serveur de jeu
echo ============================================
echo.

echo Arret de tout processus Node sur le port 3000...
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr :3000 ^| findstr LISTENING') do (
    echo   Killing PID %%a...
    taskkill /F /PID %%a >nul 2>&1
)
:: Also kill any stray node processes running server.js
taskkill /F /IM node.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo.
cd /d "%~dp0simple-server"

:: Install deps if missing
if not exist "node_modules" (
    echo Installation des dependances...
    call npm install
    echo.
)

echo Demarrage du serveur...
echo.
echo ============================================
echo   URL locale: http://localhost:3000
echo   Emulateur:  http://10.0.2.2:3000
echo ============================================
echo.
echo Si tu utilises ngrok, lance dans un autre terminal:
echo   ngrok http 3000
echo Puis appui long sur le logo de l'app pour
echo entrer l'URL ngrok.
echo.

node server.js

pause
