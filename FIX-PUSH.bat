@echo off
cd /d "C:\Users\Karim\AndroidStudioProjects\MyApplication"

echo ============================================
echo   RamiTN - Push vers GitHub
echo ============================================
echo.
echo Tu es connecte avec le compte: miraxsd
echo.
echo   1. Va sur https://github.com/new
echo   2. Repository name: ramitn-server
echo   3. NE COCHE RIEN
echo   4. Clique "Create repository"
echo   5. Reviens ici et appuie sur une touche
echo.
pause

echo.
echo Mise a jour du remote vers miraxsd...
git remote remove origin 2>nul
git remote add origin https://github.com/miraxsd/ramitn-server.git

echo Push vers GitHub...
git push -u origin main

echo.
if %ERRORLEVEL% equ 0 (
    echo ============================================
    echo   PUSH REUSSI !
    echo   https://github.com/miraxsd/ramitn-server
    echo.
    echo   MAINTENANT: va sur https://render.com
    echo   New+ ^> Web Service ^> Connect GitHub
    echo   Repo: miraxsd/ramitn-server
    echo   Root Directory: simple-server
    echo   Build: npm install
    echo   Start: node server.js
    echo ============================================
) else (
    echo PUSH ECHOUE
)

pause
