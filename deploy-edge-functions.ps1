# ============================================================
# Deploy Supabase Edge Functions for Healthcare App
# ============================================================
# This script deploys the Agora token generation edge function

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Healthcare App - Edge Function Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Supabase CLI is installed
Write-Host "Checking Supabase CLI..." -ForegroundColor Yellow
$supabaseVersion = & supabase --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Supabase CLI not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Supabase CLI first:" -ForegroundColor Yellow
    Write-Host "  npm install -g supabase" -ForegroundColor White
    Write-Host "  OR" -ForegroundColor White
    Write-Host "  scoop install supabase" -ForegroundColor White
    Write-Host ""
    Write-Host "Then run 'supabase login' to authenticate" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ Supabase CLI installed: $supabaseVersion" -ForegroundColor Green
Write-Host ""

# Check if logged in
Write-Host "Checking Supabase authentication..." -ForegroundColor Yellow
$loginCheck = & supabase projects list 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Not logged in to Supabase!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run:" -ForegroundColor Yellow
    Write-Host "  supabase login" -ForegroundColor White
    Write-Host ""
    exit 1
}
Write-Host "✓ Logged in to Supabase" -ForegroundColor Green
Write-Host ""

# Link to project (if not already linked)
Write-Host "Linking to Supabase project..." -ForegroundColor Yellow
$projectRef = "ykbpznoqebhopyqpoqaf"
Write-Host "  Project: $projectRef" -ForegroundColor White

# Try to link (will skip if already linked)
& supabase link --project-ref $projectRef 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Linked to project" -ForegroundColor Green
} else {
    Write-Host "⚠ Already linked or link failed (continuing anyway)" -ForegroundColor Yellow
}
Write-Host ""

# Prompt for Agora credentials
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Agora Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Get your Agora credentials from:" -ForegroundColor Yellow
Write-Host "  https://console.agora.io/" -ForegroundColor White
Write-Host ""

# Ask if user wants to set Agora secrets
$setSecrets = Read-Host "Do you want to set Agora secrets now? (y/n)"
if ($setSecrets -eq "y" -or $setSecrets -eq "Y") {
    Write-Host ""
    $agoraAppId = Read-Host "Enter your Agora App ID"
    $agoraAppCert = Read-Host "Enter your Agora App Certificate"

    if ($agoraAppId -and $agoraAppCert) {
        Write-Host ""
        Write-Host "Setting Agora secrets..." -ForegroundColor Yellow

        & supabase secrets set "AGORA_APP_ID=$agoraAppId"
        & supabase secrets set "AGORA_APP_CERTIFICATE=$agoraAppCert"

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Agora secrets set successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠ Failed to set secrets (you can set them manually later)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠ Skipping secret configuration" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ Skipping Agora configuration" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You can set secrets later with:" -ForegroundColor Yellow
    Write-Host "  supabase secrets set AGORA_APP_ID=your-app-id" -ForegroundColor White
    Write-Host "  supabase secrets set AGORA_APP_CERTIFICATE=your-certificate" -ForegroundColor White
}
Write-Host ""

# Deploy the edge function
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying Edge Function" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Deploying generate-agora-token function..." -ForegroundColor Yellow

& supabase functions deploy generate-agora-token --no-verify-jwt

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✓ DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Edge function deployed at:" -ForegroundColor White
    Write-Host "  https://ykbpznoqebhopyqpoqaf.supabase.co/functions/v1/generate-agora-token" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Test the function in Supabase Dashboard" -ForegroundColor White
    Write-Host "  2. Start the healthcare app: cd apps/healthcare_customer && npm run dev" -ForegroundColor White
    Write-Host "  3. Test video consultations!" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "✗ DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check if you're logged in: supabase login" -ForegroundColor White
    Write-Host "  2. Verify project link: supabase link --project-ref ykbpznoqebhopyqpoqaf" -ForegroundColor White
    Write-Host "  3. Check function code in: supabase/functions/generate-agora-token/" -ForegroundColor White
    Write-Host ""
    exit 1
}
