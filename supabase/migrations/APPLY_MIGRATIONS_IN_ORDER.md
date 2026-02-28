# How to Apply Database Migrations

## ⚠️ IMPORTANT: Use the FIXED Version

Due to RLS policy dependencies, use the **FIXED** version of the first migration:

## Migration Order

Apply these migrations **in this exact order**:

### 1. Customer-Tenants Junction (FIXED VERSION) ✅
**File**: `20260228_create_customer_tenants_junction_FIXED.sql`

**What it does**:
- Drops existing RLS policies on customers table
- Creates customer_tenants junction table
- Migrates existing customer data
- Removes tenant_id from customers table
- Creates new global policies

**How to apply**:
```sql
-- Copy entire content of 20260228_create_customer_tenants_junction_FIXED.sql
-- Paste into Supabase Dashboard → SQL Editor
-- Click "Run"
```

**Verification**:
```sql
-- Should return customer_tenants table
SELECT table_name FROM information_schema.tables
WHERE table_name = 'customer_tenants';

-- Should return 0 rows (column no longer exists)
SELECT column_name FROM information_schema.columns
WHERE table_name = 'customers' AND column_name = 'tenant_id';

-- Check data migrated successfully
SELECT COUNT(*) FROM customer_tenants;
```

---

### 2. Loyalty Configuration
**File**: `20260228_create_loyalty_config.sql`

**What it does**:
- Creates loyalty_config table
- Adds helper functions for calculating loyalty points
- Seeds default (disabled) config for existing tenants

**Verification**:
```sql
SELECT COUNT(*) FROM loyalty_config;
-- Should match number of tenants

SELECT * FROM loyalty_config LIMIT 1;
-- Check structure
```

---

### 3. Delivery Types
**File**: `20260228_create_delivery_types.sql`

**What it does**:
- Creates delivery_types table
- Adds calculate_delivery_fee() function
- Seeds "Standard Delivery" and "Pickup" for existing tenants

**Verification**:
```sql
SELECT COUNT(*) FROM delivery_types;
-- Should be at least 2 * number_of_tenants

SELECT name, base_fee FROM delivery_types LIMIT 5;
```

---

### 4. Storefront Configuration
**File**: `20260228_create_storefront_config.sql`

**What it does**:
- Creates storefront_config table
- Adds is_storefront_open() function
- Seeds basic config for existing tenants

**Verification**:
```sql
SELECT COUNT(*) FROM storefront_config;
-- Should match number of tenants

SELECT is_active, minimum_order_value FROM storefront_config LIMIT 1;
```

---

### 5. Reserved Quantity for Branch Inventory
**File**: `20260228_add_reserved_quantity_to_branch_inventory.sql`

**What it does**:
- Adds reserved_quantity column to branch_inventory
- Creates inventory reservation functions (per branch)
- Creates product_stock_status view

**Verification**:
```sql
-- Check column exists
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'branch_inventory' AND column_name = 'reserved_quantity';

-- Check functions exist
SELECT routine_name FROM information_schema.routines
WHERE routine_name IN (
    'reserve_inventory',
    'release_reserved_inventory',
    'confirm_reservation',
    'get_available_stock'
);

-- Check view exists
SELECT * FROM product_stock_status LIMIT 1;
```

---

## Quick Apply (All at Once)

**Option A**: Apply one-by-one via Supabase Dashboard (Recommended)
1. Go to Supabase Dashboard → SQL Editor
2. Create new query for each migration
3. Copy/paste migration content
4. Run query
5. Verify with verification queries above

**Option B**: Apply via psql (if you have direct access)
```bash
psql $DATABASE_URL -f 20260228_create_customer_tenants_junction_FIXED.sql
psql $DATABASE_URL -f 20260228_create_loyalty_config.sql
psql $DATABASE_URL -f 20260228_create_delivery_types.sql
psql $DATABASE_URL -f 20260228_create_storefront_config.sql
psql $DATABASE_URL -f 20260228_add_reserved_quantity_to_branch_inventory.sql
```

---

## Post-Migration Checks

Run this comprehensive check after all migrations:

```sql
-- 1. Check all tables created
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
    'customer_tenants',
    'loyalty_config',
    'delivery_types',
    'storefront_config'
)
ORDER BY table_name;
-- Should return 4 rows

-- 2. Check reserved_quantity column added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'products'
AND column_name = 'reserved_quantity';
-- Should return 1 row

-- 3. Check all functions created
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
)
ORDER BY routine_name;
-- Should return 8 rows

-- 4. Check RLS policies
SELECT tablename, COUNT(*) as policy_count
FROM pg_policies
WHERE tablename IN (
    'customer_tenants',
    'loyalty_config',
    'delivery_types',
    'storefront_config',
    'customers',
    'customer_addresses'
)
GROUP BY tablename
ORDER BY tablename;

-- 5. Check data seeded
SELECT
    (SELECT COUNT(*) FROM loyalty_config) as loyalty_configs,
    (SELECT COUNT(*) FROM delivery_types) as delivery_types,
    (SELECT COUNT(*) FROM storefront_config) as storefront_configs,
    (SELECT COUNT(*) FROM customer_tenants) as customer_tenant_links;
```

---

## Troubleshooting

### Error: "relation already exists"
**Solution**: The migration creates tables with `IF NOT EXISTS`. This is safe to ignore.

### Error: "column already exists"
**Solution**: The migration adds columns with `IF NOT EXISTS`. This is safe to ignore.

### Error: "policy already exists"
**Solution**: Drop the existing policy first:
```sql
DROP POLICY IF EXISTS "policy_name" ON table_name;
```
Then re-run the migration.

### Error: "function already exists"
**Solution**: Use `CREATE OR REPLACE FUNCTION` (already in migrations) or drop first:
```sql
DROP FUNCTION IF EXISTS function_name CASCADE;
```

---

## Rollback (if needed)

⚠️ **WARNING**: This will delete data!

```sql
-- Rollback in reverse order
DROP VIEW IF EXISTS product_stock_status CASCADE;
ALTER TABLE branch_inventory DROP COLUMN IF EXISTS reserved_quantity CASCADE;
DROP FUNCTION IF EXISTS get_available_stock CASCADE;
DROP FUNCTION IF EXISTS reserve_inventory CASCADE;
DROP FUNCTION IF EXISTS release_reserved_inventory CASCADE;
DROP FUNCTION IF EXISTS confirm_reservation CASCADE;

DROP TABLE IF EXISTS storefront_config CASCADE;
DROP FUNCTION IF EXISTS is_storefront_open CASCADE;

DROP TABLE IF EXISTS delivery_types CASCADE;
DROP FUNCTION IF EXISTS calculate_delivery_fee CASCADE;

DROP TABLE IF EXISTS loyalty_config CASCADE;
DROP FUNCTION IF EXISTS calculate_loyalty_points CASCADE;
DROP FUNCTION IF EXISTS calculate_redemption_value CASCADE;

DROP TABLE IF EXISTS customer_tenants CASCADE;
-- Note: Cannot easily restore tenant_id to customers table
-- You would need to restore from backup
```

---

## Success!

After all migrations are applied successfully:

✅ Customers are now global (can order from multiple tenants)
✅ Loyalty points are tenant-configurable
✅ Delivery options are tenant-defined
✅ Storefront customization is available
✅ Inventory reservation prevents overselling

You can now proceed to test the POS Admin Dashboard!

