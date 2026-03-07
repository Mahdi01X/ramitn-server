@echo off
echo ======================================
echo  Rami Tunisien - Setup Script
echo ======================================
echo.

echo [1/4] Installing shared dependencies...
cd shared
call npm install
call npm run build
cd ..

echo [2/4] Installing server dependencies...
cd server
call npm install
cd ..

echo [3/4] Setting up server .env...
if not exist server\.env (
    copy server\.env.example server\.env
    echo Created server/.env from .env.example
) else (
    echo server/.env already exists
)

echo [4/4] Installing Flutter dependencies...
cd mobile
call flutter pub get
cd ..

echo.
echo ======================================
echo  Setup complete!
echo ======================================
echo.
echo To start the backend:
echo   docker compose up -d
echo   OR
echo   cd server ^&^& npm run start:dev
echo.
echo To start the mobile app:
echo   cd mobile ^&^& flutter run
echo.

