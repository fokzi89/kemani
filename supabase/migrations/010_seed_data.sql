-- ============================================================
-- Migration 010: Seed Data
-- ============================================================
-- Purpose: Insert default subscription plans and initial data

-- Insert default subscription plans
INSERT INTO subscriptions (plan_tier, monthly_fee, commission_rate, max_branches, max_staff_users, max_products, monthly_transaction_quota, features, billing_cycle_start, billing_cycle_end) VALUES
    ('free', 0, 5.0, 1, 3, 100, 500, '{"ai_chat": false, "analytics_basic": true, "whatsapp": false}'::jsonb, NOW(), NOW() + INTERVAL '1 month'),
    ('basic', 5000, 2.5, 3, 10, 1000, 2000, '{"ai_chat": false, "analytics_advanced": true, "whatsapp": true, "ecommerce_sync": true}'::jsonb, NOW(), NOW() + INTERVAL '1 month'),
    ('pro', 15000, 1.5, 10, 50, 10000, 10000, '{"ai_chat": true, "analytics_advanced": true, "whatsapp": true, "ecommerce_sync": true, "multi_branch": true}'::jsonb, NOW(), NOW() + INTERVAL '1 month'),
    ('enterprise', 50000, 1.0, 999, 999, 999999, 999999, '{"ai_chat": true, "analytics_advanced": true, "whatsapp": true, "ecommerce_sync": true, "multi_branch": true, "dedicated_support": true}'::jsonb, NOW(), NOW() + INTERVAL '1 month');
