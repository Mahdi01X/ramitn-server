@echo off
REM ──────────────────────────────────────────────
REM  Initialise la structure Flutter native
REM  (android/, ios/, web/) en préservant le code Dart
REM ──────────────────────────────────────────────

echo [1/5] Sauvegarde du code Dart existant...
if not exist _backup mkdir _backup
xcopy /E /I /Y /Q mobile\lib _backup\lib >nul 2>&1
xcopy /E /I /Y /Q mobile\test _backup\test >nul 2>&1
copy /Y mobile\pubspec.yaml _backup\pubspec.yaml >nul 2>&1
copy /Y mobile\analysis_options.yaml _backup\analysis_options.yaml >nul 2>&1

echo [2/5] Creation du projet Flutter temporaire...
flutter create --org com.example --project-name rami_tunisien _flutter_tmp

echo [3/5] Copie des fichiers natifs dans mobile/...
xcopy /E /I /Y /Q _flutter_tmp\android mobile\android >nul 2>&1
xcopy /E /I /Y /Q _flutter_tmp\ios mobile\ios >nul 2>&1
xcopy /E /I /Y /Q _flutter_tmp\web mobile\web >nul 2>&1
xcopy /E /I /Y /Q _flutter_tmp\windows mobile\windows >nul 2>&1
xcopy /E /I /Y /Q _flutter_tmp\linux mobile\linux >nul 2>&1
xcopy /E /I /Y /Q _flutter_tmp\macos mobile\macos >nul 2>&1

echo [4/5] Restauration du code Dart...
xcopy /E /I /Y /Q _backup\lib mobile\lib >nul 2>&1
xcopy /E /I /Y /Q _backup\test mobile\test >nul 2>&1
copy /Y _backup\pubspec.yaml mobile\pubspec.yaml >nul 2>&1
copy /Y _backup\analysis_options.yaml mobile\analysis_options.yaml >nul 2>&1

echo [5/5] Nettoyage et installation des deps...
rmdir /S /Q _flutter_tmp 2>nul
rmdir /S /Q _backup 2>nul
cd mobile
call flutter pub get
cd ..

echo.
echo ========================================
echo  Flutter initialise avec succes !
echo  Lancez : cd mobile ^&^& flutter run
echo ========================================
