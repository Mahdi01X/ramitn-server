@echo off
title RamiTN - Deployer sur Render
color 0B

echo ============================================
echo   RamiTN - Deploiement serveur permanent
echo ============================================
echo.
echo Pour avoir une URL FIXE (plus besoin de ngrok):
echo.
echo 1. Cree un repo GitHub avec le dossier simple-server/
echo    (ou push tout le projet)
echo.
echo 2. Va sur https://render.com (inscription gratuite)
echo.
echo 3. New ^> Web Service ^> Connect GitHub
echo.
echo 4. Configure:
echo    - Root Directory: simple-server
echo    - Build Command: npm install
echo    - Start Command: node server.js
echo    - Plan: Free
echo.
echo 5. Render te donne une URL permanente comme:
echo    https://ramitn-server.onrender.com
echo.
echo 6. Dans l'app: appui long sur le logo
echo    Entre cette URL ^> OK
echo.
echo 7. C'est tout ! Le serveur tourne 24/7.
echo.
echo ============================================
echo.
echo Alternative rapide avec ngrok:
echo   1. cd simple-server ^&^& node server.js
echo   2. (autre terminal) ngrok http 3000
echo   3. Copie l'URL ngrok dans l'app
echo.

pause

