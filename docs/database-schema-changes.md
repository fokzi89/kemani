# Database Schema Changes Summary

## Overview

This document summarizes all database schema changes made to support the multi-tenant POS platform with e-commerce capabilities.

## Migration Changes

### Migration 001: Extensions and Enums (UPDATED)

**Changed:**
```sql
-- BEFORE
CREATE TYPE plan_tier AS ENUM ('free', 'basic', 'pro', 'enterprise');

-- AFTER
CREATE TYPE plan_tier AS ENUM ('free', 'basic', 'pro', 'enterprise', 'enterprise_custom');
```

**Impact:** Adds support for Enterprise Custom plan tier with custom domain capability.

---

### Migration 007: Indexes (FIXED)

**Changed:**
```sql
-- BEFORE (Line 13)
CREATE INDEX idx_branches_location ON branches USING GIST(ST_MakePoint(longitude, latitude)::geography)

-- AFTER
CREATE INDEX idx_branches_location ON branches USING GIST(geography(ST_MakePoint(longitude, latitude)))
```

**Impact:** Fixes syntax error in PostGIS geography index creation.

---

### Migration 010: Seed Data (UPDATED)

**Major Changes:**

1. **Added all 5 subscription tiers** with proper feature flags
2. **Updated commission rates** to match business model:
   - Free: 0% (no e-commerce)
   - Basic: 0% (no e-commerce)
   - Pro: 1.5%
   - Enterprise: 1%
   - Enterprise Custom: 0.5% (negotiable)

3. **Comprehensive feature flags** for each tier:

#### Free Plan Features
```json
{
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
}
```

#### Basic Plan Features
```json
{
  "ai_chat": true,
  "ecommerce_chat": false,
  "ecommerce_enabled": false,
  "whatsapp_business_api": true,
  "inter_branch_transfers": true,
  "delivery_management": true
}
```

#### Pro Plan Features (E-Commerce Enabled)
```json
{
  "ai_chat": true,
  "ecommerce_chat": true,
  "ecommerce_enabled": true,
  "advanced_analytics": true,
  "api_access": true,
  "woocommerce_sync": true,
  "shopify_sync": true,
  "whatsapp_business_api": true,
  "inter_branch_transfers": true,
  "delivery_management": true,
  "bulk_import_export": true,
  "priority_support": true
}
```

#### Enterprise Plan Features
```json
{
  "ai_chat": true,
  "ecommerce_chat": true,
  "ecommerce_enabled": true,
  "advanced_analytics": true,
  "api_access": true,
  "multi_currency": true,
  "phone_support": true,
  "dedicated_account_manager": true,
  "custom_reporting": true,
  "sla_guarantees": true,
  "data_export": true
}
```

#### Enterprise Custom Features (Full White-Label)
```json
{
  "ai_chat": true,
  "ecommerce_chat": true,
  "ecommerce_enabled": true,
  "custom_domain": true,
  "white_label": true,
  "advanced_analytics": true,
  "api_access": true,
  "multi_currency": true,
  "custom_integrations": true,
  "phone_support": true,
  "dedicated_account_manager": true,
  "support_24_7": true,
  "custom_reporting": true,
  "sla_guarantees": true,
  "data_export": true,
  "custom_development": true,
  "on_premise_option": true
}
```

---

### Migration 011: Chat Enhancements (NEW)

**Purpose:** Extend chat system to support rich media and interactive elements

**New Enums:**
```sql
CREATE TYPE chat_message_type AS ENUM (
    'text', 'image', 'audio', 'video', 'location',
    'product_card', 'receipt', 'payment_confirmation',
    'discount_applied', 'system_action'
);

CREATE TYPE chat_action_type AS ENUM (
    'add_to_cart', 'apply_discount', 'view_product',
    'confirm_payment', 'update_delivery_address', 'request_human_agent'
);
```

**New Table Structure:**
```sql
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY,
    conversation_id UUID NOT NULL,
    sender_type sender_type NOT NULL,
    sender_id UUID,

    -- Message content
    message_type chat_message_type DEFAULT 'text',
    message_text TEXT,

    -- Media support
    media_url TEXT,
    media_size_bytes BIGINT,
    media_duration_seconds INTEGER,
    thumbnail_url TEXT,

    -- Structured data
    metadata JSONB DEFAULT '{}',

    -- Interactive actions
    action_type chat_action_type,
    action_data JSONB,
    action_completed_at TIMESTAMPTZ,
    action_completed_by UUID,

    -- AI intent detection
    intent VARCHAR(100),
    confidence_score DECIMAL(3,2),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**New Functions:**
- `has_chat_feature(tenant_id)` - Check if tenant can use chat
- `has_ecommerce_chat_feature(tenant_id)` - Check if tenant can use product chat

---

### Migration 012: E-Commerce Enhancements (NEW)

**Purpose:** Add e-commerce storefront support with custom domain capability

**Subscriptions Table Changes:**
```sql
ALTER TABLE subscriptions
ADD COLUMN commission_cap_amount DECIMAL(12,2) DEFAULT 500.00 CHECK (commission_cap_amount >= 0);
```

**Tenants Table Changes:**
```sql
ALTER TABLE tenants
ADD COLUMN ecommerce_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN custom_domain VARCHAR(255),
ADD COLUMN custom_domain_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN ecommerce_settings JSONB DEFAULT '{}';
```

**New Indexes:**
```sql
CREATE UNIQUE INDEX idx_tenants_custom_domain ON tenants(custom_domain)
    WHERE custom_domain IS NOT NULL AND deleted_at IS NULL;
```

**New View:**
```sql
CREATE VIEW ecommerce_products AS
-- Aggregates products across all branches with stock and location info
```

**New Functions:**
1. `can_enable_ecommerce(tenant_id)` - Check if tenant plan allows e-commerce
2. `can_use_custom_domain(tenant_id)` - Check if tenant can use custom domain
3. `get_storefront_url(tenant_id, base_url)` - Get tenant's storefront URL
4. `get_ecommerce_products(...)` - Get products with advanced filtering
5. `calculate_commission(tenant_id, order_amount)` - Calculate commission with ₦500 cap

**E-Commerce Settings JSONB Schema:**
```json
{
  "show_out_of_stock": false,
  "enable_branch_filter": true,
  "enable_location_filter": true,
  "default_view": "category",
  "currency_display": "NGN",
  "delivery_enabled": true,
  "pickup_enabled": true,
  "min_order_amount": 1000,
  "seo": {
    "meta_title": "Shop at MyStore",
    "meta_description": "...",
    "og_image": "https://..."
  },
  "theme": {
    "primary_color": "#FF6B35",
    "secondary_color": "#004E89"
  }
}
```

---

## Complete Database Structure

### Plan Tiers (5 Total)

| Tier | Monthly Fee | Commission | Commission Cap | Branches | Staff | Products | Transactions |
|------|-------------|------------|----------------|----------|-------|----------|--------------|
| free | ₦0 | 0% | N/A | 1 | 3 | 100 | 500 |
| basic | ₦5,000 | 0% | N/A | 3 | 10 | 1,000 | 5,000 |
| pro | ₦15,000 | 1.5% | ₦500 | 10 | 50 | 10,000 | 50,000 |
| enterprise | ₦50,000 | 1% | ₦500 | Unlimited | Unlimited | Unlimited | Unlimited |
| enterprise_custom | Custom | 0.5% | ₦500 | Unlimited | Unlimited | Unlimited | Unlimited |

### E-Commerce URLs

| Plan | URL Structure | Example |
|------|---------------|---------|
| free | N/A (disabled) | N/A |
| basic | N/A (disabled) | N/A |
| pro | `/slug` | `yourplatform.com/acme-supermarket` |
| enterprise | `/slug` | `yourplatform.com/acme-supermarket` |
| enterprise_custom | Custom domain | `shop.acmestore.com` |

### Key Tables Updated

1. **tenants** - Added e-commerce fields
2. **chat_messages** - Dropped and recreated with rich media support
3. **subscriptions** - Updated seed data with 5 tiers

### New Database Objects

**Views:**
- `ecommerce_products` - Multi-branch product aggregation

**Functions:**
- `has_chat_feature(UUID)` - Plan feature check
- `has_ecommerce_chat_feature(UUID)` - Product chat availability
- `can_enable_ecommerce(UUID)` - E-commerce eligibility
- `can_use_custom_domain(UUID)` - Custom domain eligibility
- `get_storefront_url(UUID, TEXT)` - Storefront URL resolver
- `get_ecommerce_products(...)` - Advanced product filtering

**Indexes:**
- `idx_tenants_custom_domain` - Unique custom domain index
- `idx_chat_messages_conversation` - Chat message lookup
- `idx_chat_messages_type` - Message type filtering
- `idx_chat_messages_action` - Action tracking
- `idx_products_ecommerce` - E-commerce product queries

---

## Testing Queries

### Check All Subscription Plans
```sql
SELECT
    plan_tier,
    monthly_fee,
    commission_rate,
    max_branches,
    max_products,
    features->>'ecommerce_enabled' as ecommerce,
    features->>'custom_domain' as custom_domain,
    features->>'ai_chat' as ai_chat
FROM subscriptions
ORDER BY monthly_fee;
```

### Enable E-Commerce for a Tenant
```sql
-- First check if tenant can enable e-commerce
SELECT can_enable_ecommerce('tenant-uuid');

-- If true, enable it
UPDATE tenants
SET ecommerce_enabled = TRUE,
    ecommerce_settings = '{
        "enable_branch_filter": true,
        "enable_location_filter": true
    }'::jsonb
WHERE id = 'tenant-uuid';
```

### Set Custom Domain (Enterprise Custom Only)
```sql
-- Check if tenant can use custom domain
SELECT can_use_custom_domain('tenant-uuid');

-- If true, set custom domain
UPDATE tenants
SET custom_domain = 'shop.mystore.com',
    custom_domain_verified = FALSE
WHERE id = 'tenant-uuid';

-- After DNS verification
UPDATE tenants
SET custom_domain_verified = TRUE
WHERE id = 'tenant-uuid';
```

### Get Storefront URL
```sql
SELECT get_storefront_url('tenant-uuid', 'https://yourplatform.com');
-- Returns: 'https://yourplatform.com/tenant-slug' or 'https://custom-domain.com'
```

### Get E-Commerce Products with Filters
```sql
-- All products for tenant
SELECT * FROM get_ecommerce_products('tenant-uuid');

-- Beverages only, in stock, within 5km
SELECT * FROM get_ecommerce_products(
    p_tenant_id := 'tenant-uuid',
    p_category := 'Beverages',
    p_latitude := 6.5244,
    p_longitude := 3.3792,
    p_max_distance_km := 5.0,
    p_in_stock_only := TRUE
);

-- Specific branch only
SELECT * FROM get_ecommerce_products(
    p_tenant_id := 'tenant-uuid',
    p_branch_id := 'branch-uuid'
);
```

### Calculate Commission with Cap
```sql
-- Calculate commission for different order amounts (Pro plan: 1.5% rate, ₦500 cap)
SELECT calculate_commission('tenant-uuid', 10000);   -- Returns: 150.00
SELECT calculate_commission('tenant-uuid', 33333);   -- Returns: 500.00 (at cap)
SELECT calculate_commission('tenant-uuid', 50000);   -- Returns: 500.00 (capped)
SELECT calculate_commission('tenant-uuid', 100000);  -- Returns: 500.00 (capped)

-- Calculate commission for multiple orders
SELECT
    order_id,
    total_amount,
    calculate_commission(tenant_id, total_amount) as commission
FROM orders
WHERE tenant_id = 'tenant-uuid'
AND order_type = 'marketplace';
```

---

## Migration Order

Apply migrations in this exact order:

1. ✅ `001_extensions_and_enums.sql` (UPDATED - now includes enterprise_custom)
2. ✅ `002_core_tables.sql`
3. ✅ `003_product_inventory_tables.sql`
4. ✅ `004_customer_sales_tables.sql`
5. ✅ `005_order_delivery_tables.sql`
6. ✅ `006_additional_tables.sql`
7. ✅ `007_indexes.sql` (FIXED - geography syntax)
8. ✅ `008_rls_policies.sql`
9. ✅ `009_triggers.sql`
10. ✅ `010_seed_data.sql` (UPDATED - 5 tiers with features)
11. ✅ `011_chat_enhancements.sql` (NEW - rich media chat)
12. ✅ `012_ecommerce_enhancements.sql` (NEW - storefront support)

---

## Breaking Changes

### Migration 011
- **DROPS** `chat_messages` table and recreates it
- **Impact:** Any existing chat messages will be lost
- **Mitigation:** If you have production chat data, back it up first

### Migration 012
- **NON-BREAKING:** Only adds new columns to `tenants` table
- Existing tenants will have `ecommerce_enabled = FALSE` by default

---

## Feature Availability Matrix

| Feature | Free | Basic | Pro | Enterprise | E. Custom |
|---------|------|-------|-----|------------|-----------|
| POS System | ✅ | ✅ | ✅ | ✅ | ✅ |
| AI Chat | ❌ | ✅ | ✅ | ✅ | ✅ |
| E-Commerce | ❌ | ❌ | ✅ | ✅ | ✅ |
| E-Commerce Chat | ❌ | ❌ | ✅ | ✅ | ✅ |
| Custom Domain | ❌ | ❌ | ❌ | ❌ | ✅ |
| White Label | ❌ | ❌ | ❌ | ❌ | ✅ |
| API Access | ❌ | ❌ | ✅ | ✅ | ✅ |
| Multi-Currency | ❌ | ❌ | ❌ | ✅ | ✅ |
| Custom Integrations | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## Next Steps

1. **Apply all migrations** in order using `supabase db push`
2. **Verify subscription plans** are created correctly
3. **Test feature functions** with sample tenant IDs
4. **Set up RLS policies** for e-commerce data access
5. **Build frontend** for storefront and chat features
6. **Configure DNS** for Enterprise Custom customers

---

## Support

For questions about the database schema:
- See: `docs/ecommerce-storefront-guide.md`
- See: `docs/chat-system-guide.md`
- See: `docs/subscription-tiers.md`
