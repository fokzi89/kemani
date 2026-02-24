# Migration Conflicts Resolved

This document tracks all conflicts encountered during the tenant-scoped products migration and how they were resolved.

## Conflict 1: Invalid Enum Value
**Error:** `ERROR: 22P02: invalid input value for enum user_role: "sales_agent"`

**Root Cause:**
The RLS policy used `role IN ('cashier', 'sales_agent')` but `sales_agent` is not a valid value in the `user_role` enum.

**Valid user_role enum values:**
- `platform_admin`
- `tenant_admin`
- `branch_manager`
- `cashier`
- `driver`

**Resolution:**
Changed the policy to use only `role = 'cashier'` since cashiers are the staff members who process sales.

**File:** `supabase/migrations/20260223_tenant_scoped_products.sql:82-93`

---

## Conflict 2: Cannot Drop Column with Dependencies
**Error:** `ERROR: 2BP01: cannot drop column branch_id of table products because other objects depend on it`

**Dependent Objects:**
- View: `ecommerce_products` (defined in `024_ecommerce_enhancements.sql`)
- Indexes:
  - `idx_products_tenant_branch`
  - `idx_products_low_stock`
  - `idx_products_expiry`

**Resolution:**
Added STEP 4 and STEP 5 to the migration:

1. **STEP 4:** Drop dependent views and functions BEFORE removing columns
   - Drop `ecommerce_products` view with CASCADE
   - Drop all variations of `get_ecommerce_products` function

2. **STEP 5:** Drop dependent indexes
   - Drop `idx_products_tenant_branch` (uses branch_id)
   - Drop `idx_products_low_stock` (uses branch_id and stock_quantity)
   - Drop `idx_products_expiry` (uses expiry_date)

3. **STEP 7:** Recreate views with new schema
   - Recreate `ecommerce_products` view using `branch_inventory` table
   - Recreate `get_ecommerce_products` function with updated signature

**Files Modified:**
- `supabase/migrations/20260223_tenant_scoped_products.sql:248-284`
- `supabase/migrations/20260223_tenant_scoped_products.sql:327-442`

---

## Conflict 3: Function Name Not Unique
**Error:** `ERROR: 42725: function name "get_ecommerce_products" is not unique`

**Root Cause:**
PostgreSQL allows function overloading - multiple functions with the same name but different parameter signatures. Two versions existed:

1. **Original function** (from `024_ecommerce_enhancements.sql`):
   ```sql
   get_ecommerce_products(
       p_tenant_id UUID,
       p_category VARCHAR,
       p_branch_id UUID,
       p_latitude DECIMAL,
       p_longitude DECIMAL,
       p_max_distance_km DECIMAL,
       p_in_stock_only BOOLEAN
   )
   ```

2. **New function** (from this migration):
   ```sql
   get_ecommerce_products(
       p_tenant_id UUID,
       p_category VARCHAR,
       p_search VARCHAR,
       p_min_price DECIMAL,
       p_max_price DECIMAL
   )
   ```

**Resolution:**
Used dynamic SQL to query `pg_proc` system catalog and drop ALL functions named `get_ecommerce_products` regardless of signature:

```sql
DO $$
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN
        SELECT oid::regprocedure::text as func_signature
        FROM pg_proc
        WHERE proname = 'get_ecommerce_products'
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || func_record.func_signature || ' CASCADE';
        RAISE NOTICE 'Dropped function: %', func_record.func_signature;
    END LOOP;
END $$;
```

This approach:
- ✅ Drops all overloaded versions automatically
- ✅ Handles unknown variations from failed migration attempts
- ✅ Provides notice messages for debugging
- ✅ Uses CASCADE to drop dependent objects

**File:** `supabase/migrations/20260223_tenant_scoped_products.sql:255-274`

---

## Migration Execution Order (Final)

The migration now executes in this order:

1. **STEP 1:** Create `branch_inventory` table with RLS policies
2. **STEP 2:** Migrate existing product data to branch inventory
3. **STEP 3:** Clean up duplicate products (merge by SKU/name)
4. **STEP 4:** Drop dependent views and functions (with CASCADE)
5. **STEP 5:** Drop dependent indexes
6. **STEP 5.1:** Remove columns from products table
7. **STEP 6:** Update RLS policies for products
8. **STEP 7:** Recreate views (`v_branch_products`, `ecommerce_products`) and functions
9. **STEP 8:** Update inventory transaction trigger
10. **STEP 9:** Ensure image_url column exists

---

## Testing Checklist

After running the migration, verify:

- [ ] `branch_inventory` table exists with correct columns
- [ ] Products table no longer has `branch_id`, `stock_quantity`, etc.
- [ ] `v_branch_products` view returns data correctly
- [ ] `ecommerce_products` view returns data with branch aggregation
- [ ] `get_ecommerce_products()` function works with new signature
- [ ] RLS policies allow branch managers to manage their inventory
- [ ] POS can query products using `v_branch_products`
- [ ] Sales processing updates `branch_inventory` correctly
- [ ] No orphaned functions or views remain

---

## Rollback Strategy

If critical issues occur:

1. Restore database from pre-migration backup
2. Review error logs to identify the issue
3. Update migration script to handle the edge case
4. Test in staging environment
5. Re-run migration

**Backup Command (before migration):**
```bash
pg_dump -h <host> -U <user> -d <database> -f backup_before_tenant_products_$(date +%Y%m%d).sql
```
