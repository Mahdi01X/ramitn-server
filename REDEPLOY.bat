@echo off
cd /d "C:\Users\Karim\AndroidStudioProjects\MyApplication"

echo ============================================
echo   RamiTN - Re-deploy serveur
echo ============================================
echo.

echo Ajout des changements...
git add simple-server/server.js
git commit -m "Fix: add numPlayers to room events, fix join flow"

echo Push vers GitHub...
git push

echo.
echo ============================================
echo   PUSH FAIT !
echo   Render va automatiquement re-deployer.
echo   Attends 2-3 minutes puis reteste.
echo ============================================

pause

