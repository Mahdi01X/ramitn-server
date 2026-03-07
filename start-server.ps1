Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  Rami Tunisien - Serveur En Ligne" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

$serverDir = Join-Path $PSScriptRoot "simple-server"
Set-Location $serverDir

# Check node
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "ERREUR: Node.js n'est pas installe!" -ForegroundColor Red
    Write-Host "Telecharge-le sur https://nodejs.org" -ForegroundColor Red
    pause
    exit
}

# Install deps if needed
if (-not (Test-Path "node_modules")) {
    Write-Host "Installation des dependances..." -ForegroundColor Cyan
    npm install
}

# Get local IP
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch "Loopback" -and $_.IPAddress -notmatch "^169" } | Select-Object -First 1).IPAddress

Write-Host ""
Write-Host "Ton adresse IP locale: $ip" -ForegroundColor Green
Write-Host ""
Write-Host "MEME WIFI: Dans l'app, mets: http://${ip}:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "A DISTANCE: Installe ngrok (https://ngrok.com)" -ForegroundColor Cyan
Write-Host "  Puis dans un autre terminal: ngrok http 3000" -ForegroundColor Cyan
Write-Host "  Et mets l'URL ngrok dans l'app (ex: https://xxxx.ngrok-free.app)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Demarrage du serveur..." -ForegroundColor Green
Write-Host ""

node server.js

