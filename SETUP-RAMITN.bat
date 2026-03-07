@echo off
title RamiTN - Setup complet
color 0E

echo ============================================
echo   RamiTN - Configuration complete
echo ============================================
echo.

cd /d "%~dp0mobile"

echo [1/4] Installation des dependances Flutter...
call flutter pub get
echo.

echo [2/4] Generation des icones du logo...
call dart run flutter_launcher_icons
echo.

echo [3/4] Nettoyage du build cache...
call flutter clean
call flutter pub get
echo.

echo [4/4] Verification que le serveur tourne...
cd /d "%~dp0simple-server"
echo Arret ancien serveur sur port 3000...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :3000 ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>&1
)
timeout /t 1 /nobreak >nul
echo Demarrage serveur...
start "RamiTN Server" /min cmd /c "node server.js"
echo Serveur demarre.
echo.

echo ============================================
echo   TOUT EST PRET !
echo ============================================
echo.
echo Pour lancer l'app:
echo   cd mobile
echo   flutter run
echo.
echo Pour changer l'URL du serveur:
echo   Appui LONG sur le logo dans l'app
echo.

pause

