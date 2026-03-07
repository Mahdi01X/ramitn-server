@echo off
REM ================================================================
REM  RAMI TUNISIEN — Lancement sur emulateur
REM  Ouvrir un terminal (PowerShell ou CMD) dans le dossier du projet
REM  puis executer: .\run.bat
REM ================================================================

echo.
echo  ====================================================
echo        RAMI TUNISIEN - Lancement sur emulateur
echo  ====================================================
echo.

REM --- Verifier Flutter ---
flutter --version >nul 2>&1
if errorlevel 1 (
    echo  [ERREUR] Flutter non detecte dans le PATH.
    echo  Installez Flutter: https://docs.flutter.dev/get-started/install
    echo  Puis relancez ce script.
    pause
    exit /b 1
)
echo  [OK] Flutter detecte.
echo.

REM --- Aller dans le dossier mobile ---
cd /d "%~dp0mobile"

REM --- Verifier si le projet Flutter est initialise ---
if not exist "android\gradlew" (
    echo  [1/3] Initialisation du projet Flutter...
    echo        Cela peut prendre 1-2 minutes la premiere fois.
    echo.

    REM Sauvegarder nos fichiers
    cd /d "%~dp0"
    if not exist "_bak" mkdir "_bak"
    xcopy /E /I /Y /Q "mobile\lib" "_bak\lib" >nul 2>&1
    xcopy /E /I /Y /Q "mobile\test" "_bak\test" >nul 2>&1
    copy /Y "mobile\pubspec.yaml" "_bak\pubspec.yaml" >nul 2>&1
    copy /Y "mobile\analysis_options.yaml" "_bak\analysis_options.yaml" >nul 2>&1

    REM Supprimer l'ancien dossier mobile incomplet et recreer proprement
    rmdir /S /Q "mobile" 2>nul

    REM Creer un vrai projet Flutter
    flutter create --org com.ramitunisien --project-name rami_tunisien --platforms android,ios "mobile"

    REM Restaurer notre code
    xcopy /E /I /Y /Q "_bak\lib" "mobile\lib" >nul 2>&1
    xcopy /E /I /Y /Q "_bak\test" "mobile\test" >nul 2>&1
    copy /Y "_bak\pubspec.yaml" "mobile\pubspec.yaml" >nul 2>&1
    copy /Y "_bak\analysis_options.yaml" "mobile\analysis_options.yaml" >nul 2>&1

    REM Nettoyer
    rmdir /S /Q "_bak" 2>nul

    echo  [OK] Projet Flutter initialise.
    echo.
    cd /d "%~dp0mobile"
) else (
    echo  [OK] Projet Flutter deja initialise.
)

REM --- Installer les dependances ---
echo  [2/3] Installation des dependances...
call flutter pub get
if errorlevel 1 (
    echo.
    echo  [ERREUR] flutter pub get a echoue.
    echo  Verifiez votre connexion internet et relancez.
    pause
    exit /b 1
)
echo  [OK] Dependances installees.
echo.

REM --- Verifier les appareils ---
echo  [3/3] Appareils detectes:
echo  -----------------------------------------------
flutter devices
echo  -----------------------------------------------
echo.

REM --- Lancer ---
echo  Lancement de Rami Tunisien...
echo  (Ctrl+C pour arreter)
echo.
flutter run

pause

