# PowerShell script to combine all migration files for manual application
# Run this in PowerShell: .\supabase\apply_migrations.ps1

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Kemani POS - Database Migration Helper" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

$migrationsDir = "C:\Users\AFOKE\kemani\supabase\migrations"
$outputFile = "C:\Users\AFOKE\kemani\supabase\combined_migration.sql"

# Check if migrations directory exists
if (-not (Test-Path $migrationsDir)) {
    Write-Host "❌ Error: Migrations directory not found: $migrationsDir" -ForegroundColor Red
    exit 1
}

# Get all migration files in order
$migrationFiles = Get-ChildItem -Path $migrationsDir -Filter "*.sql" | Sort-Object Name

if ($migrationFiles.Count -eq 0) {
    Write-Host "❌ Error: No migration files found in $migrationsDir" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Found $($migrationFiles.Count) migration files:" -ForegroundColor Green
$migrationFiles | ForEach-Object { Write-Host "   - $($_.Name)" -ForegroundColor Gray }
Write-Host ""

# Combine all migrations
Write-Host "🔧 Combining migrations into: combined_migration.sql" -ForegroundColor Yellow

$combinedContent = @"
-- ============================================================
-- Kemani POS - Combined Database Migration
-- ============================================================
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- Total Migrations: $($migrationFiles.Count)
--
-- Instructions:
-- 1. Copy this entire file
-- 2. Open Supabase SQL Editor
-- 3. Paste and run
-- ============================================================

"@

foreach ($file in $migrationFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $combinedContent += "`n`n-- File: $($file.Name)`n"
    $combinedContent += $content
    $combinedContent += "`n-- End of $($file.Name)`n"
}

# Write combined file
$combinedContent | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "✅ Combined migration created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Open file: supabase\combined_migration.sql" -ForegroundColor White
Write-Host "   2. Copy all contents (Ctrl+A, Ctrl+C)" -ForegroundColor White
Write-Host "   3. Go to: https://app.supabase.com → Your Project → SQL Editor" -ForegroundColor White
Write-Host "   4. Paste and click 'Run'" -ForegroundColor White
Write-Host ""
Write-Host "Alternative: Apply migrations individually in order (001 → 010)" -ForegroundColor Yellow
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan

# Open the file in default text editor
if (Test-Path $outputFile) {
    Write-Host "📂 Opening combined migration file..." -ForegroundColor Green
    Start-Process $outputFile
}
