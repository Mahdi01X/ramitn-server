@echo off
title RamiTN - Push to GitHub
color 0E

echo ============================================
echo   RamiTN - Push serveur sur GitHub
echo ============================================
echo.

cd /d "%~dp0"

:: Check git
where git >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERREUR: Git n'est pas installe!
    echo Telecharge-le sur https://git-scm.com
    pause
    exit /b
)

echo Initialisation du repo git...
git init 2>nul

echo.
echo Ajout des fichiers du serveur...
git add simple-server/ render.yaml .gitignore

echo.
echo Commit...
git commit -m "RamiTN server - ready for Render deployment"

echo.
echo ============================================
echo   MAINTENANT :
echo   1. Cree un repo sur GitHub: https://github.com/new
echo      Nom: ramitn-server
echo.
echo   2. Copie la commande ci-dessous et colle-la:
echo.
echo   git remote add origin https://github.com/TON_USERNAME/ramitn-server.git
echo   git branch -M main
echo   git push -u origin main
echo.
echo   3. Va sur https://render.com
echo      New ^> Web Service ^> Connect GitHub
echo      Root Directory: simple-server
echo      Build: npm install
echo      Start: node server.js
echo ============================================

pause

