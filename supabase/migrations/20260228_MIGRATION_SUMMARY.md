# Database Migrations - February 28, 2026

## Summary

Created 5 new migrations to support User Story 3 (Customer Management & Marketplace) and enhance the POS Admin dashboard functionality.

## Migrations Created

### 1. `20260228_create_customer_tenants_junction_FIXED.sql`
**Purpose**: Support customers ordering from multiple tenants with tenant-scoped data

**Note**: Use the FIXED version which drops RLS policies before removing tenant_id column

**Changes**:
- Makes `customers` table global (removes `tenant_id`)
- Moves tenant-specific fields to new `customer_tenants` junction table
- Adds smart email detection support (one customer, multiple tenants)
- Tenant-scoped loyalty points and purchase history

**Tables**:
- Modifies: `customers` (removes tenant_id, loyalty_points, total_purchases, purchase_count, last_purchase_at)
- Creates: `customer_tenants` (customer_id, tenant_id, loyalty_points, total_purchases, purchase_count)

**RLS Policies**: Tenant isolation on `customer_tenants`, global access to `customers`

---

### 2. `20260228_create_loyalty_config.sql`
**Purpose**: Tenant-configurable loyalty points system

**Changes**:
- Each tenant can activate/deactivate loyalty program
- Flexible configuration for earning and redeeming points
- Helper functions for calculating points and redemption values

**Tables**:
- Creates: `loyalty_config` (tenant_id, is_enabled, points_per_currency_unit, currency_unit, min_redemption_points, allow_partial_payment, allow_full_payment, redemption_value_per_point, max_points_per_order, points_expiry_days)

**Functions**:
- `calculate_loyalty_points(tenant_id, purchase_amount)` - Calculates points earned
- `calculate_redemption_value(tenant_id, points)` - Calculates currency value of points

**Default Config**: Creates disabled loyalty config for all existing tenants
- 1 point per NGN 100 spent
- Minimum 100 points to redeem
- 1 point = NGN 1 when redeemed

---

### 3. `20260228_create_delivery_types.sql`
**Purpose**: Tenant-defined delivery options with flexible pricing

**Changes**:
- Tenants create custom delivery types (Van, Motorbike, Bicycle, Trek, etc.)
- Flexible pricing: base fee + per-km fee + free distance
- Service constraints: max distance, minimum order value

**Tables**:
- Creates: `delivery_types` (tenant_id, name, description, base_fee, per_km_fee, free_distance_km, min_order_value, max_distance_km, estimated_minutes, is_active, display_order)

**Functions**:
- `calculate_delivery_fee(delivery_type_id, distance_km, order_value)` - Calculates delivery fee

**Default Types**: Creates "Standard Delivery" and "Pickup" for all existing tenants

---

### 4. `20260228_create_storefront_config.sql`
**Purpose**: Marketplace storefront customization

**Changes**:
- Tenant storefront appearance and settings
- Plan-based features (paid plans get customization)
- Operating hours, contact info, order settings

**Tables**:
- Creates: `storefront_config` (tenant_id, banner_url, about_text, welcome_message, operating_hours, contact_email, contact_phone, contact_whatsapp, minimum_order_value, accept_online_orders, allow_guest_checkout, show_stock_quantity, is_active)

**Functions**:
- `is_storefront_open(tenant_id, check_time)` - Checks if storefront is currently open

**Default Config**: Creates inactive basic storefronts for all existing tenants
- Operating hours: Mon-Fri 8am-6pm, Sat 9am-5pm, Sun closed
- Guest checkout enabled
- No minimum order value

---

### 5. `20260228_add_reserved_quantity_to_branch_inventory.sql`
**Purpose**: Inventory reservation for pending orders (per branch)

**Changes**:
- Adds `reserved_quantity` field to branch_inventory
- Reserves inventory on order placement at specific branch
- Deducts on payment confirmation
- Prevents overselling

**Tables**:
- Modifies: `branch_inventory` (adds reserved_quantity INTEGER DEFAULT 0)
- Creates: VIEW `product_stock_status` (joins products with branch_inventory, shows available_quantity, stock_status, expiry_status)

**Functions**:
- `get_available_stock(branch_id, product_id)` - Returns stock_quantity - reserved_quantity for a branch
- `reserve_inventory(branch_id, product_id, quantity)` - Reserves inventory for order at specific branch
- `release_reserved_inventory(branch_id, product_id, quantity)` - Releases reservation (order cancelled)
- `confirm_reservation(branch_id, product_id, quantity)` - Confirms reservation (payment succeeded)

**Constraints**:
- `check_stock_available`: Ensures stock_quantity >= reserved_quantity

**Triggers**:
- Low stock alerts when available quantity <= reorder_level

---

## Migration Order

Apply migrations in this exact order:

```bash
# 1. Customer-tenants junction (modifies customers table) - USE FIXED VERSION
psql -f 20260228_create_customer_tenants_junction_FIXED.sql

# 2. Loyalty configuration
psql -f 20260228_create_loyalty_config.sql

# 3. Delivery types
psql -f 20260228_create_delivery_types.sql

# 4. Storefront configuration
psql -f 20260228_create_storefront_config.sql

# 5. Reserved quantity for branch inventory
psql -f 20260228_add_reserved_quantity_to_branch_inventory.sql
```

## Via Supabase Dashboard

1. Go to Supabase Dashboard → SQL Editor
2. Create new query
3. Paste migration content
4. Run query
5. Repeat for each migration in order

## Post-Migration Verification

### Verify Tables Created
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
    'customer_tenants',
    'loyalty_config',
    'delivery_types',
    'storefront_config'
);
```

### Verify Columns Added
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'branch_inventory'
AND column_name = 'reserved_quantity';
```

### Verify Functions Created
```sql
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'calculate_loyalty_points',
    'calculate_redemption_value',
    'calculate_delivery_fee',
    'is_storefront_open',
    'get_available_stock',
    'reserve_inventory',
    'release_reserved_inventory',
    'confirm_reservation'
);
```

### Verify RLS Policies
```sql
SELECT tablename, policyname
FROM pg_policies
WHERE tablename IN (
    'customer_tenants',
    'loyalty_config',
    'delivery_types',
    'storefront_config'
);
```

### Verify Default Data Created
```sql
-- Check loyalty configs created for tenants
SELECT COUNT(*) FROM loyalty_config;

-- Check delivery types created for tenants
SELECT COUNT(*) FROM delivery_types;

-- Check storefront configs created for tenants
SELECT COUNT(*) FROM storefront_config;
```

## Rollback Instructions

If you need to rollback these migrations:

```sql
-- WARNING: This will delete data!

-- Drop in reverse order
DROP VIEW IF EXISTS product_stock_status CASCADE;
DROP FUNCTION IF EXISTS confirm_reservation CASCADE;
DROP FUNCTION IF EXISTS release_reserved_inventory CASCADE;
DROP FUNCTION IF EXISTS reserve_inventory CASCADE;
DROP FUNCTION IF EXISTS get_available_stock CASCADE;
ALTER TABLE branch_inventory DROP COLUMN IF EXISTS reserved_quantity;
ALTER TABLE branch_inventory DROP CONSTRAINT IF EXISTS check_stock_available;

DROP TABLE IF EXISTS storefront_config CASCADE;
DROP FUNCTION IF EXISTS is_storefront_open CASCADE;

DROP TABLE IF EXISTS delivery_types CASCADE;
DROP FUNCTION IF EXISTS calculate_delivery_fee CASCADE;

DROP TABLE IF EXISTS loyalty_config CASCADE;
DROP FUNCTION IF EXISTS calculate_loyalty_points CASCADE;
DROP FUNCTION IF EXISTS calculate_redemption_value CASCADE;

DROP TABLE IF EXISTS customer_tenants CASCADE;
-- Note: Customers table modifications are harder to rollback
-- You would need to re-add tenant_id and migrate data back
```

## Impact Analysis

### Customer Data Migration

**IMPORTANT**: The `customers` table structure has changed significantly. If you have existing customer data with `tenant_id`, you need to migrate it to the new `customer_tenants` junction table:

```sql
-- Backup existing customer data
CREATE TABLE customers_backup AS SELECT * FROM customers;

-- Migrate to customer_tenants (if customers had tenant_id before)
-- INSERT INTO customer_tenants (customer_id, tenant_id, loyalty_points, total_purchases, purchase_count, last_purchase_at)
-- SELECT id, tenant_id, loyalty_points, total_purchases, purchase_count, last_purchase_at
-- FROM customers_backup;
```

### Breaking Changes

1. **Customers Table**: `tenant_id` removed - customers are now global
2. **Loyalty Points**: Moved from `customers` to `customer_tenants` - tenant-specific
3. **Orders Table**: Should now reference `customer_tenants` for tenant-scoped customer relationships

### New Features Enabled

1. ✅ Smart customer detection (auto-login if email exists across tenants)
2. ✅ Tenant-scoped order history
3. ✅ Configurable loyalty programs per tenant
4. ✅ Custom delivery types per tenant
5. ✅ Marketplace storefront customization
6. ✅ Inventory reservation (prevent overselling)
7. ✅ Real-time available stock calculations

## Next Steps

1. **Apply Migrations**: Run migrations in order via Supabase Dashboard
2. **Verify**: Run verification queries above
3. **Test**: Test customer creation, loyalty points, delivery fee calculation
4. **Update App**: Update Flutter app to use new tables and functions
5. **Documentation**: Update API documentation with new endpoints

---

**Created**: 2026-02-28
**Status**: Ready to apply
**Review Required**: Yes (breaking changes to customers table)
