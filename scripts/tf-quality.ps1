# scripts/tf-quality.ps1
#
# Stage 3 — Terraform quality checks: fmt and validate.
# Run from the repository root: .\scripts\tf-quality.ps1
#
# Does NOT run terraform apply or terraform destroy.
# Requires: terraform >= 1.10.0, AWS credentials (for validate with S3 backend
#           the -backend=false flag is used to skip backend initialisation).

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

# Directories to validate (relative to repo root)
$ValidateDirs = @(
    "modules\vpc",
    "modules\compute",
    "modules\database",
    "modules\storage",
    "modules\vpc\examples\basic",
    "modules\compute\examples\basic",
    "modules\database\examples\basic",
    "modules\storage\examples\basic",
    "envs\dev",
    "envs\prod",
    "bootstrap\state-bucket"
)

$Failures = @()

# ── 1. terraform fmt -check (recursive from root) ────────────────────────────
Write-Host "`n=== terraform fmt -check ===" -ForegroundColor Cyan
Push-Location $RepoRoot
try {
    terraform fmt -check -recursive -diff
    Write-Host "  fmt: PASS" -ForegroundColor Green
} catch {
    Write-Host "  fmt: FAIL — run 'terraform fmt -recursive' to fix" -ForegroundColor Red
    $Failures += "terraform fmt"
} finally {
    Pop-Location
}

# ── 2. terraform validate ─────────────────────────────────────────────────────
Write-Host "`n=== terraform validate ===" -ForegroundColor Cyan

foreach ($Dir in $ValidateDirs) {
    $FullPath = Join-Path $RepoRoot $Dir
    if (-not (Test-Path $FullPath)) {
        Write-Host "  SKIP (not found): $Dir" -ForegroundColor Yellow
        continue
    }

    Push-Location $FullPath
    try {
        Write-Host "  Validating: $Dir" -NoNewline

        # Init with -backend=false avoids needing AWS credentials for S3 backend
        $initOut = terraform init -backend=false -input=false -no-color 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host " — INIT FAIL" -ForegroundColor Red
            $Failures += "init: $Dir"
            continue
        }

        $validateOut = terraform validate -no-color 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host " — PASS" -ForegroundColor Green
        } else {
            Write-Host " — FAIL" -ForegroundColor Red
            Write-Host $validateOut
            $Failures += "validate: $Dir"
        }
    } finally {
        Pop-Location
    }
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($Failures.Count -eq 0) {
    Write-Host "All checks passed." -ForegroundColor Green
    exit 0
} else {
    Write-Host "Failures:" -ForegroundColor Red
    $Failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
