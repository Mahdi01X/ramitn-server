@echo off
setlocal enabledelayedexpansion
:: =========================================================================
:: RamiTN — Automated Test & Correction Loop
:: Runs all test layers, collects logs, reports divergences.
:: =========================================================================

set "ROOT=%~dp0"
set "LOGDIR=%ROOT%test-logs"
set "TIMESTAMP=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
set "TIMESTAMP=%TIMESTAMP: =0%"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

echo ============================================================
echo   RamiTN — AUTOMATED TEST SUITE
echo   %DATE% %TIME%
echo ============================================================
echo.

:: ─── Layer 1: Shared Engine Tests (Jest) ─────────────────────
echo [1/4] Running shared/ engine tests (Jest)...
cd /d "%ROOT%shared"
call npx jest --verbose --no-color 2>&1 > "%LOGDIR%\engine-%TIMESTAMP%.log"
if errorlevel 1 (
    echo   ^[FAIL^] Engine tests — see test-logs\engine-%TIMESTAMP%.log
    set "ENGINE_PASS=0"
) else (
    echo   ^[PASS^] Engine tests
    set "ENGINE_PASS=1"
)

:: ─── Layer 2: Cross-Engine Comparison Tests ──────────────────
echo [2/4] Running cross-engine comparison tests...
call npx jest --verbose --no-color cross-engine 2>&1 > "%LOGDIR%\cross-engine-%TIMESTAMP%.log"
if errorlevel 1 (
    echo   ^[FAIL^] Cross-engine tests — see test-logs\cross-engine-%TIMESTAMP%.log
    set "CROSS_PASS=0"
) else (
    echo   ^[PASS^] Cross-engine tests
    set "CROSS_PASS=1"
)

:: ─── Layer 3: Protocol Contract Tests ────────────────────────
echo [3/4] Running protocol contract tests...
call npx jest --verbose --no-color protocol 2>&1 > "%LOGDIR%\protocol-%TIMESTAMP%.log"
if errorlevel 1 (
    echo   ^[FAIL^] Protocol tests — see test-logs\protocol-%TIMESTAMP%.log
    set "PROTO_PASS=0"
) else (
    echo   ^[PASS^] Protocol tests
    set "PROTO_PASS=1"
)

:: ─── Layer 4: Maestro E2E (if maestro available) ─────────────
echo [4/4] Checking for Maestro E2E...
where maestro >nul 2>nul
if errorlevel 1 (
    echo   ^[SKIP^] Maestro not installed — skipping E2E tests
    echo   Install: curl -Ls https://get.maestro.mobile.dev ^| bash
    set "E2E_PASS=-1"
) else (
    cd /d "%ROOT%mobile"
    call maestro test .maestro/ 2>&1 > "%LOGDIR%\e2e-%TIMESTAMP%.log"
    if errorlevel 1 (
        echo   ^[FAIL^] Maestro E2E — see test-logs\e2e-%TIMESTAMP%.log
        set "E2E_PASS=0"
    ) else (
        echo   ^[PASS^] Maestro E2E
        set "E2E_PASS=1"
    )
)

:: ─── Summary ─────────────────────────────────────────────────
echo.
echo ============================================================
echo   SUMMARY
echo ============================================================

set "TOTAL_FAIL=0"

if "%ENGINE_PASS%"=="1" (echo   [PASS] Shared Engine) else (echo   [FAIL] Shared Engine & set /a TOTAL_FAIL+=1)
if "%CROSS_PASS%"=="1" (echo   [PASS] Cross-Engine) else (echo   [FAIL] Cross-Engine & set /a TOTAL_FAIL+=1)
if "%PROTO_PASS%"=="1" (echo   [PASS] Protocol Contract) else (echo   [FAIL] Protocol Contract & set /a TOTAL_FAIL+=1)
if "%E2E_PASS%"=="1" (echo   [PASS] Maestro E2E) else if "%E2E_PASS%"=="-1" (echo   [SKIP] Maestro E2E) else (echo   [FAIL] Maestro E2E & set /a TOTAL_FAIL+=1)

echo.
echo   Logs: %LOGDIR%
echo ============================================================

if %TOTAL_FAIL% gtr 0 (
    echo.
    echo   %TOTAL_FAIL% layer(s) failed. Review logs above.
    exit /b 1
) else (
    echo.
    echo   All layers passed!
    exit /b 0
)
