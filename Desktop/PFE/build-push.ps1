# SkillSpace - Docker Build & Push Script
# Run this from the project root: .\build-push.ps1
# Requires: docker login funkid99 done beforehand

$ErrorActionPreference = "Stop"
$ROOT = $PSScriptRoot

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "  SkillSpace Docker Build & Push" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# ── Image definitions ──────────────────────────────────────────────────────────
$images = @(
    @{ name = "funkid99/skillspace-gateway:latest";   context = "$ROOT\Backend\api-gateway";            dockerfile = "" },
    @{ name = "funkid99/skillspace-login:latest";     context = "$ROOT\Backend\login-register-services"; dockerfile = "" },
    @{ name = "funkid99/skillspace-candidat:latest";  context = "$ROOT\Backend\candidat-service";        dockerfile = "" },
    @{ name = "funkid99/skillspace-recruiter:latest"; context = "$ROOT\Backend\recruter-service";        dockerfile = "" },
    @{ name = "funkid99/skillspace-offer:latest";     context = "$ROOT\Backend\offer-service";           dockerfile = "" },
    @{ name = "funkid99/skillspace-interview:latest"; context = "$ROOT\Backend\interview-service";       dockerfile = "" },
    @{ name = "funkid99/skillspace-trainer:latest";   context = "$ROOT\TrainerProfile-main\backend";     dockerfile = "" },
    @{ name = "funkid99/skillspace-frontend:latest";  context = "$ROOT";                                 dockerfile = "skillspace_front\Dockerfile" }
)

# ── Build all ──────────────────────────────────────────────────────────────────
Write-Host "[1/2] Building all images..." -ForegroundColor Yellow
foreach ($img in $images) {
    Write-Host "`n  >> Building $($img.name)" -ForegroundColor Green
    if ($img.dockerfile -ne "") {
        docker build -t $img.name -f "$($img.context)\$($img.dockerfile)" $img.context
    } else {
        docker build -t $img.name $img.context
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Build failed for $($img.name)" -ForegroundColor Red
        exit 1
    }
    Write-Host "  OK: $($img.name)" -ForegroundColor Green
}

# ── Push all ───────────────────────────────────────────────────────────────────
Write-Host "`n[2/2] Pushing all images to Docker Hub..." -ForegroundColor Yellow
foreach ($img in $images) {
    Write-Host "`n  >> Pushing $($img.name)" -ForegroundColor Green
    docker push $img.name
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Push failed for $($img.name)" -ForegroundColor Red
        exit 1
    }
    Write-Host "  OK: $($img.name)" -ForegroundColor Green
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "  All images pushed successfully!" -ForegroundColor Cyan
Write-Host "  Deploy with: docker compose pull && docker compose up -d" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan
