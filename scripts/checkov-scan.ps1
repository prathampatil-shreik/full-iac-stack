# scripts/checkov-scan.ps1
#
# Stage 3 - Checkov IaC security scan.
# Run from the repository root: .\scripts\checkov-scan.ps1
#
# Requires: pip install checkov

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command checkov -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: checkov not found. Install with: pip install checkov" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Checkov scan ===" -ForegroundColor Cyan
Write-Host "  Root  : $RepoRoot"
Write-Host "  Config: .checkov.yaml"

Push-Location $RepoRoot
try {
    checkov --directory . --config-file .checkov.yaml --output cli --compact
    $exitCode = $LASTEXITCODE
} finally {
    Pop-Location
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($exitCode -eq 0) {
    Write-Host "Checkov: PASS (0 failures)" -ForegroundColor Green
} else {
    Write-Host "Checkov: FAIL - review output above and suppress with justification in .checkov.yaml" -ForegroundColor Red
}

exit $exitCode
