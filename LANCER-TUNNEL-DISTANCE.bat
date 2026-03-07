@echo off
title Rami Tunisien - Tunnel ngrok
color 0B
echo.
echo ============================================
echo   RAMI TUNISIEN - Tunnel pour jeu a distance
echo ============================================
echo.
echo PREREQUIS: Le serveur doit deja tourner!
echo (Lance d'abord LANCER-SERVEUR.bat)
echo.
echo Si ngrok n'est pas installe:
echo   1. Va sur https://ngrok.com/download
echo   2. Cree un compte gratuit
echo   3. Telecharge ngrok.exe
echo   4. Place ngrok.exe dans ce dossier: %~dp0
echo   5. Relance ce script
echo.

:: Check if ngrok is available
where ngrok >nul 2>&1
if %ERRORLEVEL% neq 0 (
    if exist "%~dp0ngrok.exe" (
        echo Ngrok trouve dans le dossier courant.
        "%~dp0ngrok.exe" http 3000
    ) else (
        echo ERREUR: ngrok n'est pas installe!
        echo.
        echo Telecharge-le sur https://ngrok.com/download
        echo Place ngrok.exe dans: %~dp0
        echo.
        pause
        exit /b
    )
) else (
    echo Lancement de ngrok...
    echo.
    echo L'URL HTTPS qui s'affiche est celle a partager!
    echo Mets-la dans l'app: Jouer en ligne ^> Icone engrenage
    echo.
    ngrok http 3000
)

pause

