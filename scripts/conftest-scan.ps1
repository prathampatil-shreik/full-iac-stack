# scripts/conftest-scan.ps1
#
# Stage 3 — OPA/Conftest policy checks.
# Run from the repository root: .\scripts\conftest-scan.ps1
#
# Requires: conftest (https://www.conftest.dev)
# Install:  winget install open-policy-agent.conftest
#           or: choco install conftest
#
# Two modes:
#   1. Unit tests  — opa test policy/terraform (requires: opa CLI)
#   2. Plan tests  — conftest test against fixture JSON files

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$PolicyDir = Join-Path $RepoRoot "policy\terraform"
$TestdataDir = Join-Path $PolicyDir "testdata"

$Failures = @()

# ── 1. OPA unit tests (rego _test.rego files) ─────────────────────────────────
Write-Host "`n=== OPA unit tests (opa test) ===" -ForegroundColor Cyan

if (Get-Command opa -ErrorAction SilentlyContinue) {
    Push-Location $RepoRoot
    try {
        opa test policy/terraform --verbose
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  OPA unit tests: PASS" -ForegroundColor Green
        } else {
            Write-Host "  OPA unit tests: FAIL" -ForegroundColor Red
            $Failures += "opa test"
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "  SKIP: opa CLI not found. Install from https://www.openpolicyagent.org/docs/latest/#1-download-opa" -ForegroundColor Yellow
}

# ── 2. Conftest against fixture plans ─────────────────────────────────────────
Write-Host "`n=== Conftest plan tests ===" -ForegroundColor Cyan

if (-not (Get-Command conftest -ErrorAction SilentlyContinue)) {
    Write-Host "  ERROR: conftest not found. Install from https://www.conftest.dev" -ForegroundColor Red
    exit 1
}

# pass_plan.json — expect zero violations
Write-Host "  Testing pass_plan.json (expect: PASS)" -NoNewline
Push-Location $RepoRoot
try {
    $out = conftest test "$TestdataDir\pass_plan.json" --policy $PolicyDir --no-color 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " — PASS" -ForegroundColor Green
    } else {
        Write-Host " — FAIL (unexpected violations)" -ForegroundColor Red
        Write-Host $out
        $Failures += "conftest pass_plan"
    }
} finally {
    Pop-Location
}

# fail_plan.json — expect violations (non-zero exit is expected and correct)
Write-Host "  Testing fail_plan.json (expect: violations detected)" -NoNewline
Push-Location $RepoRoot
try {
    $out = conftest test "$TestdataDir\fail_plan.json" --policy $PolicyDir --no-color 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host " — PASS (violations correctly detected)" -ForegroundColor Green
        Write-Host "  Violations found:" -ForegroundColor DarkGray
        $out | Where-Object { $_ -match "FAIL" } | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    } else {
        Write-Host " — FAIL (expected violations but none found)" -ForegroundColor Red
        $Failures += "conftest fail_plan"
    }
} finally {
    Pop-Location
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($Failures.Count -eq 0) {
    Write-Host "All policy checks passed." -ForegroundColor Green
    exit 0
} else {
    Write-Host "Failures:" -ForegroundColor Red
    $Failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
