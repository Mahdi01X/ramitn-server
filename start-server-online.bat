@echo off
echo ========================================
echo   Rami Tunisien - Serveur + ngrok
echo   (pour jouer a distance)
echo ========================================
echo.
echo ETAPE 1: Demarrer le serveur...
echo.

cd /d "%~dp0simple-server"
call npm install >nul 2>&1

start "Rami Server" cmd /c "node server.js"

echo Serveur demarre sur le port 3000.
echo.
echo ETAPE 2: Lancer ngrok pour rendre le serveur accessible...
echo.
echo Si ngrok n'est pas installe:
echo   1. Va sur https://ngrok.com et cree un compte gratuit
echo   2. Telecharge ngrok.exe
echo   3. Place-le dans ce dossier ou dans ton PATH
echo.

ngrok http 3000

pause

