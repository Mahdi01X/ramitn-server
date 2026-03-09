# =========================================================================
# RamiTN — Automated Test & Correction Loop (PowerShell)
# Runs all test layers, collects logs, reports divergences.
# Usage: .\run-tests.ps1
# =========================================================================

$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogDir = Join-Path $Root "test-logs"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  RamiTN — AUTOMATED TEST SUITE" -ForegroundColor Cyan
Write-Host "  $(Get-Date)" -ForegroundColor DarkCyan
Write-Host "============================================================`n" -ForegroundColor Cyan

$Results = @{}

# ─── Layer 1: Shared Engine Tests (Jest) ─────────────────────
Write-Host "[1/4] Running shared/ engine tests (Jest)..." -ForegroundColor Yellow
Push-Location (Join-Path $Root "shared")
$engineLog = Join-Path $LogDir "engine-$Timestamp.log"
& npx jest --verbose --no-color 2>&1 | Out-File -FilePath $engineLog -Encoding UTF8
$Results["Engine"] = $LASTEXITCODE -eq 0
if ($Results["Engine"]) { Write-Host "  [PASS] Engine tests" -ForegroundColor Green }
else { Write-Host "  [FAIL] Engine tests — see $engineLog" -ForegroundColor Red }

# ─── Layer 2: Cross-Engine Comparison Tests ──────────────────
Write-Host "[2/4] Running cross-engine comparison tests..." -ForegroundColor Yellow
$crossLog = Join-Path $LogDir "cross-engine-$Timestamp.log"
& npx jest --verbose --no-color cross-engine 2>&1 | Out-File -FilePath $crossLog -Encoding UTF8
$Results["CrossEngine"] = $LASTEXITCODE -eq 0
if ($Results["CrossEngine"]) { Write-Host "  [PASS] Cross-engine tests" -ForegroundColor Green }
else { Write-Host "  [FAIL] Cross-engine tests — see $crossLog" -ForegroundColor Red }

# ─── Layer 3: Protocol Contract Tests ────────────────────────
Write-Host "[3/4] Running protocol contract tests..." -ForegroundColor Yellow
$protoLog = Join-Path $LogDir "protocol-$Timestamp.log"
& npx jest --verbose --no-color protocol 2>&1 | Out-File -FilePath $protoLog -Encoding UTF8
$Results["Protocol"] = $LASTEXITCODE -eq 0
if ($Results["Protocol"]) { Write-Host "  [PASS] Protocol tests" -ForegroundColor Green }
else { Write-Host "  [FAIL] Protocol tests — see $protoLog" -ForegroundColor Red }

Pop-Location

# ─── Layer 4: Maestro E2E (if maestro available) ─────────────
Write-Host "[4/4] Checking for Maestro E2E..." -ForegroundColor Yellow
$maestro = Get-Command maestro -ErrorAction SilentlyContinue
if ($null -eq $maestro) {
    Write-Host "  [SKIP] Maestro not installed — skipping E2E tests" -ForegroundColor DarkYellow
    Write-Host "  Install: curl -Ls https://get.maestro.mobile.dev | bash" -ForegroundColor DarkGray
    $Results["E2E"] = $null
} else {
    Push-Location (Join-Path $Root "mobile")
    $e2eLog = Join-Path $LogDir "e2e-$Timestamp.log"
    & maestro test .maestro/ 2>&1 | Out-File -FilePath $e2eLog -Encoding UTF8
    $Results["E2E"] = $LASTEXITCODE -eq 0
    if ($Results["E2E"]) { Write-Host "  [PASS] Maestro E2E" -ForegroundColor Green }
    else { Write-Host "  [FAIL] Maestro E2E — see $e2eLog" -ForegroundColor Red }
    Pop-Location
}

# ─── Summary ─────────────────────────────────────────────────
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$failed = 0
foreach ($key in $Results.Keys) {
    $val = $Results[$key]
    if ($null -eq $val) {
        Write-Host "  [SKIP] $key" -ForegroundColor DarkYellow
    } elseif ($val) {
        Write-Host "  [PASS] $key" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $key" -ForegroundColor Red
        $failed++
    }
}

Write-Host "`n  Logs: $LogDir" -ForegroundColor DarkGray
Write-Host "============================================================`n" -ForegroundColor Cyan

if ($failed -gt 0) {
    Write-Host "  $failed layer(s) failed. Review logs above." -ForegroundColor Red
    exit 1
} else {
    Write-Host "  All layers passed!" -ForegroundColor Green
    exit 0
}
