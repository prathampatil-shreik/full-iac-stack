# scripts/checkov-scan.ps1
#
# Stage 3 — Checkov IaC security scan.
# Run from the repository root: .\scripts\checkov-scan.ps1
#
# Requires: checkov (pip install checkov  OR  brew install checkov)
# Windows:  pip install checkov
#
# Scans all Terraform under the repo root, excluding .terraform dirs,
# state files, plan files, and local tfvars (see .checkov.yaml).

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command checkov -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: checkov not found. Install with: pip install checkov" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Checkov scan ===" -ForegroundColor Cyan
Write-Host "  Root : $RepoRoot"
Write-Host "  Config: .checkov.yaml"

Push-Location $RepoRoot
try {
    checkov `
        --directory . `
        --config-file .checkov.yaml `
        --output cli `
        --soft-fail-on MEDIUM

    $exitCode = $LASTEXITCODE
} finally {
    Pop-Location
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($exitCode -eq 0) {
    Write-Host "Checkov: PASS (no HIGH/CRITICAL findings)" -ForegroundColor Green
} else {
    Write-Host "Checkov: findings detected — review output above." -ForegroundColor Yellow
    Write-Host "  HIGH/CRITICAL findings must be resolved or explicitly suppressed in .checkov.yaml with justification."
}

exit $exitCode
