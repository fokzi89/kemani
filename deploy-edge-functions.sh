#!/bin/bash

# ============================================================
# Deploy Supabase Edge Functions for Healthcare App
# ============================================================
# This script deploys the Agora token generation edge function

set -e  # Exit on error

echo "========================================"
echo "Healthcare App - Edge Function Deployment"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if Supabase CLI is installed
echo -e "${YELLOW}Checking Supabase CLI...${NC}"
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}ERROR: Supabase CLI not found!${NC}"
    echo ""
    echo -e "${YELLOW}Please install Supabase CLI first:${NC}"
    echo "  npm install -g supabase"
    echo "  OR"
    echo "  brew install supabase/tap/supabase  # macOS"
    echo ""
    echo -e "${YELLOW}Then run 'supabase login' to authenticate${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Supabase CLI installed: $(supabase --version)${NC}"
echo ""

# Check if logged in
echo -e "${YELLOW}Checking Supabase authentication...${NC}"
if ! supabase projects list &> /dev/null; then
    echo -e "${RED}ERROR: Not logged in to Supabase!${NC}"
    echo ""
    echo -e "${YELLOW}Please run:${NC}"
    echo "  supabase login"
    echo ""
    exit 1
fi
echo -e "${GREEN}✓ Logged in to Supabase${NC}"
echo ""

# Link to project (if not already linked)
echo -e "${YELLOW}Linking to Supabase project...${NC}"
PROJECT_REF="ykbpznoqebhopyqpoqaf"
echo "  Project: $PROJECT_REF"

# Try to link (will skip if already linked)
if supabase link --project-ref $PROJECT_REF 2>&1 | grep -q "already linked\|Finished"; then
    echo -e "${GREEN}✓ Linked to project${NC}"
else
    echo -e "${YELLOW}⚠ Already linked or link failed (continuing anyway)${NC}"
fi
echo ""

# Prompt for Agora credentials
echo "========================================"
echo "Agora Configuration"
echo "========================================"
echo ""
echo -e "${YELLOW}Get your Agora credentials from:${NC}"
echo "  https://console.agora.io/"
echo ""

read -p "Do you want to set Agora secrets now? (y/n): " SET_SECRETS
if [[ $SET_SECRETS =~ ^[Yy]$ ]]; then
    echo ""
    read -p "Enter your Agora App ID: " AGORA_APP_ID
    read -p "Enter your Agora App Certificate: " AGORA_APP_CERT

    if [ -n "$AGORA_APP_ID" ] && [ -n "$AGORA_APP_CERT" ]; then
        echo ""
        echo -e "${YELLOW}Setting Agora secrets...${NC}"

        supabase secrets set "AGORA_APP_ID=$AGORA_APP_ID"
        supabase secrets set "AGORA_APP_CERTIFICATE=$AGORA_APP_CERT"

        echo -e "${GREEN}✓ Agora secrets set successfully${NC}"
    else
        echo -e "${YELLOW}⚠ Skipping secret configuration${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Skipping Agora configuration${NC}"
    echo ""
    echo -e "${YELLOW}You can set secrets later with:${NC}"
    echo "  supabase secrets set AGORA_APP_ID=your-app-id"
    echo "  supabase secrets set AGORA_APP_CERTIFICATE=your-certificate"
fi
echo ""

# Deploy the edge function
echo "========================================"
echo "Deploying Edge Function"
echo "========================================"
echo ""
echo -e "${YELLOW}Deploying generate-agora-token function...${NC}"

if supabase functions deploy generate-agora-token --no-verify-jwt; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ DEPLOYMENT SUCCESSFUL!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Edge function deployed at:"
    echo -e "${CYAN}  https://ykbpznoqebhopyqpoqaf.supabase.co/functions/v1/generate-agora-token${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Test the function in Supabase Dashboard"
    echo "  2. Start the healthcare app: cd apps/healthcare_customer && npm run dev"
    echo "  3. Test video consultations!"
    echo ""
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ DEPLOYMENT FAILED${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "  1. Check if you're logged in: supabase login"
    echo "  2. Verify project link: supabase link --project-ref ykbpznoqebhopyqpoqaf"
    echo "  3. Check function code in: supabase/functions/generate-agora-token/"
    echo ""
    exit 1
fi
