@echo off
echo ========================================
echo   Rami Tunisien - Serveur en ligne
echo ========================================
echo.

cd /d "%~dp0simple-server"

echo Installation des dependances...
call npm install

echo.
echo Demarrage du serveur sur le port 3000...
echo Ton adresse locale:
ipconfig | findstr /i "IPv4"
echo.
echo Les joueurs sur le MEME WiFi peuvent utiliser ton IP locale.
echo Pour jouer a distance, utilise ngrok ou deploy sur un serveur.
echo.

node server.js

pause

