-- ============================================================
-- Migration 010: Seed Data
-- ============================================================
-- Purpose: Insert default subscription plans and initial data

-- Insert default subscription plans
-- Note: commission_cap_amount defaults to ₦500 for all plans (set in migration 012)
INSERT INTO subscriptions (plan_tier, monthly_fee, commission_rate, max_branches, max_staff_users, max_products, monthly_transaction_quota, features, billing_cycle_start, billing_cycle_end, status) VALUES
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
        'active'
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
        'active'
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
        'active'
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
        'active'
    ),

    -- Enterprise Custom Plan (Contact Sales, 0.5% commission)
    (
        'enterprise_custom',
        0.00,  -- Pricing is custom, set per tenant
        0.50,  -- Default negotiable commission
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
        'active'
    );
