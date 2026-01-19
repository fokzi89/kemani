-- ============================================================
-- Database Update Script
-- ============================================================
-- Purpose: Update existing database with latest subscription data and apply new migrations
-- Run this in Supabase SQL Editor if you already have some migrations applied

-- Step 1: Delete old subscription data
DELETE FROM subscriptions;

-- Step 2: Update enum to include enterprise_custom (if not already there)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'enterprise_custom' AND enumtypid = 'plan_tier'::regtype) THEN
        ALTER TYPE plan_tier ADD VALUE 'enterprise_custom';
    END IF;
END $$;

-- Step 3: Add commission_cap_amount column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='subscriptions' AND column_name='commission_cap_amount') THEN
        ALTER TABLE subscriptions ADD COLUMN commission_cap_amount DECIMAL(12,2) DEFAULT 500.00 CHECK (commission_cap_amount >= 0);
    END IF;
END $$;

-- Step 4: Insert updated subscription plans with correct commission rates and cap
INSERT INTO subscriptions (plan_tier, monthly_fee, commission_rate, max_branches, max_staff_users, max_products, monthly_transaction_quota, features, billing_cycle_start, billing_cycle_end, status, commission_cap_amount) VALUES
    -- Free Plan (₦0/month, 0% commission - no e-commerce)
    (
        'free',
        0.00,
        0.00,
        1,
        3,
        100,
        500,
        '{
            "ai_chat": false,
            "ecommerce_chat": false,
            "ecommerce_enabled": false,
            "advanced_analytics": false,
            "api_access": false,
            "woocommerce_sync": false,
            "shopify_sync": false,
            "whatsapp_business_api": false,
            "multi_currency": false,
            "custom_integrations": false
        }'::jsonb,
        NOW(),
        NOW() + INTERVAL '1 month',
        'active',
        500.00
    ),

    -- Basic Plan (₦5,000/month, 0% commission - no e-commerce)
    (
        'basic',
        5000.00,
        0.00,
        3,
        10,
        1000,
        5000,
        '{
            "ai_chat": true,
            "ecommerce_chat": false,
            "ecommerce_enabled": false,
            "advanced_analytics": false,
            "api_access": false,
            "woocommerce_sync": false,
            "shopify_sync": false,
            "whatsapp_business_api": true,
            "multi_currency": false,
            "custom_integrations": false,
            "inter_branch_transfers": true,
            "delivery_management": true
        }'::jsonb,
        NOW(),
        NOW() + INTERVAL '1 month',
        'active',
        500.00
    ),

    -- Pro Plan (₦15,000/month, 1.5% commission)
    (
        'pro',
        15000.00,
        1.50,
        10,
        50,
        10000,
        50000,
        '{
            "ai_chat": true,
            "ecommerce_chat": true,
            "ecommerce_enabled": true,
            "advanced_analytics": true,
            "api_access": true,
            "woocommerce_sync": true,
            "shopify_sync": true,
            "whatsapp_business_api": true,
            "multi_currency": false,
            "custom_integrations": false,
            "inter_branch_transfers": true,
            "delivery_management": true,
            "bulk_import_export": true,
            "priority_support": true
        }'::jsonb,
        NOW(),
        NOW() + INTERVAL '1 month',
        'active',
        500.00
    ),

    -- Enterprise Plan (₦50,000/month, 1% commission)
    (
        'enterprise',
        50000.00,
        1.00,
        999999,
        999999,
        999999,
        999999,
        '{
            "ai_chat": true,
            "ecommerce_chat": true,
            "ecommerce_enabled": true,
            "advanced_analytics": true,
            "api_access": true,
            "woocommerce_sync": true,
            "shopify_sync": true,
            "whatsapp_business_api": true,
            "multi_currency": true,
            "custom_integrations": false,
            "inter_branch_transfers": true,
            "delivery_management": true,
            "bulk_import_export": true,
            "priority_support": true,
            "phone_support": true,
            "dedicated_account_manager": true,
            "custom_reporting": true,
            "sla_guarantees": true,
            "data_export": true
        }'::jsonb,
        NOW(),
        NOW() + INTERVAL '1 month',
        'active',
        500.00
    ),

    -- Enterprise Custom Plan (Contact Sales, 0.5% commission)
    (
        'enterprise_custom',
        0.00,
        0.50,
        999999,
        999999,
        999999,
        999999,
        '{
            "ai_chat": true,
            "ecommerce_chat": true,
            "ecommerce_enabled": true,
            "custom_domain": true,
            "white_label": true,
            "advanced_analytics": true,
            "api_access": true,
            "woocommerce_sync": true,
            "shopify_sync": true,
            "whatsapp_business_api": true,
            "multi_currency": true,
            "custom_integrations": true,
            "inter_branch_transfers": true,
            "delivery_management": true,
            "bulk_import_export": true,
            "priority_support": true,
            "phone_support": true,
            "dedicated_account_manager": true,
            "support_24_7": true,
            "custom_reporting": true,
            "sla_guarantees": true,
            "data_export": true,
            "custom_development": true,
            "on_premise_option": true,
            "dedicated_infrastructure": false
        }'::jsonb,
        NOW(),
        NOW() + INTERVAL '1 month',
        'active',
        500.00
    );

-- Step 5: Add e-commerce fields to tenants table if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='tenants' AND column_name='ecommerce_enabled') THEN
        ALTER TABLE tenants ADD COLUMN ecommerce_enabled BOOLEAN DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='tenants' AND column_name='custom_domain') THEN
        ALTER TABLE tenants ADD COLUMN custom_domain VARCHAR(255);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='tenants' AND column_name='custom_domain_verified') THEN
        ALTER TABLE tenants ADD COLUMN custom_domain_verified BOOLEAN DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='tenants' AND column_name='ecommerce_settings') THEN
        ALTER TABLE tenants ADD COLUMN ecommerce_settings JSONB DEFAULT '{}';
    END IF;
END $$;

-- Verify update
SELECT
    plan_tier,
    monthly_fee,
    commission_rate,
    commission_cap_amount,
    features->>'ecommerce_enabled' as ecommerce_enabled
FROM subscriptions
ORDER BY monthly_fee;
