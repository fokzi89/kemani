# Deploy Flutter POS Admin to Marketing SvelteKit Site
# This script builds the Flutter app and copies it to the SvelteKit static directory

Write-Host "Building Flutter web app..." -ForegroundColor Cyan
Set-Location $PSScriptRoot
flutter build web --base-href "/pos-admin/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`nCopying build files to marketing site..." -ForegroundColor Cyan
$sourcePath = "build\web\*"
$destPath = "..\..\apps\marketing_sveltekit\static\pos-admin"

# Remove old files
if (Test-Path $destPath) {
    Remove-Item -Path $destPath -Recurse -Force
}

# Create directory and copy files
New-Item -ItemType Directory -Path $destPath -Force | Out-Null
Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force

Write-Host "`nDeployment complete! ✓" -ForegroundColor Green
Write-Host "Flutter app is now available at: http://localhost:5174/pos-admin" -ForegroundColor Cyan
