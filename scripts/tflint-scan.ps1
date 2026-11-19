# scripts/tflint-scan.ps1
#
# Stage 3 — TFLint static analysis across all modules and environments.
# Run from the repository root: .\scripts\tflint-scan.ps1
#
# Requires: tflint (https://github.com/terraform-linters/tflint)
# Install:  winget install TerraformLinters.tflint
#           or: choco install tflint

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

# Verify tflint is available
if (-not (Get-Command tflint -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: tflint not found. Install from https://github.com/terraform-linters/tflint" -ForegroundColor Red
    exit 1
}

$ScanDirs = @(
    "modules\vpc",
    "modules\compute",
    "modules\database",
    "modules\storage",
    "envs\dev",
    "envs\prod"
)

$Failures = @()

# Install plugins once from repo root (reads .tflint.hcl)
Write-Host "`n=== tflint --init ===" -ForegroundColor Cyan
Push-Location $RepoRoot
try {
    tflint --init
    if ($LASTEXITCODE -ne 0) {
        Write-Host "tflint init failed" -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}

Write-Host "`n=== tflint scan ===" -ForegroundColor Cyan

foreach ($Dir in $ScanDirs) {
    $FullPath = Join-Path $RepoRoot $Dir
    if (-not (Test-Path $FullPath)) {
        Write-Host "  SKIP (not found): $Dir" -ForegroundColor Yellow
        continue
    }

    Write-Host "  Scanning: $Dir" -NoNewline
    Push-Location $FullPath
    try {
        # --config points back to the root .tflint.hcl
        $output = tflint --config="$RepoRoot\.tflint.hcl" --no-color 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host " — PASS" -ForegroundColor Green
        } else {
            Write-Host " — FAIL" -ForegroundColor Red
            Write-Host $output
            $Failures += $Dir
        }
    } finally {
        Pop-Location
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($Failures.Count -eq 0) {
    Write-Host "TFLint: all directories passed." -ForegroundColor Green
    exit 0
} else {
    Write-Host "TFLint failures in:" -ForegroundColor Red
    $Failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
