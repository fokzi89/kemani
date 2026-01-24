# Phase 2: Technical Research & Fixes

**Status**: Resolved
**Updated**: 2026-01-23

---

## User Role Enum Fix

### Problem Identified

When applying migration `016_create_brands_categories.sql`, encountered error:
```
ERROR: invalid input value for enum user_role: 'owner'
```

### Root Cause

**Mismatch between existing database schema and new migrations:**

**Existing Database Roles** (from `types/database.types.ts`):
```typescript
user_role: 'super_admin' | 'tenant_admin' | 'branch_manager' | 'staff' | 'rider'
```

**Proposed Migration Roles** (incorrect):
```sql
role IN ('owner', 'admin', 'manager', 'cashier', 'staff')
```

### Solution Applied

Updated all migrations and validation schemas to use existing database role names.

#### Role Mapping

| Proposed Role | Database Role   | Permission Level |
|---------------|----------------|------------------|
| ~~owner~~     | `tenant_admin` | 80 (Full tenant access) |
| ~~admin~~     | `tenant_admin` | 80 (Full tenant access) |
| ~~manager~~   | `branch_manager` | 60 (Branch-level access) |
| ~~cashier~~   | `staff` | 40 (Limited access) |
| `staff`       | `staff` | 40 (Limited access) |
| N/A           | `super_admin` | 100 (Platform-wide access) |
| N/A           | `rider` | 20 (Delivery-only access) |

### Files Updated

#### 1. **Migration 016: Brands & Categories**
- `supabase/migrations/016_create_brands_categories.sql`
- Changed role checks from `('owner', 'admin', 'manager')` to `('tenant_admin', 'branch_manager')`
- Affected policies:
  - "Managers can insert brands"
  - "Managers can update brands"
  - "Managers can delete brands"
  - "Managers can manage categories"
  - "Managers can manage price history"

#### 2. **Migration 019: RLS Helper Functions**
- `supabase/migrations/019_rls_helper_functions.sql`
- Updated `has_permission()` function role hierarchy:
  ```sql
  CASE v_user_role
      WHEN 'super_admin' THEN 100
      WHEN 'tenant_admin' THEN 80
      WHEN 'branch_manager' THEN 60
      WHEN 'staff' THEN 40
      WHEN 'rider' THEN 20
  END
  ```
- Updated permission check functions:
  - `can_access_branch()` - Uses `super_admin`, `tenant_admin`
  - `can_manage_users()` - Uses `super_admin`, `tenant_admin`, `branch_manager`
  - `can_manage_products()` - Uses `super_admin`, `tenant_admin`, `branch_manager`
  - `can_view_reports()` - Uses `super_admin`, `tenant_admin`, `branch_manager`
  - `can_void_sales()` - Uses `super_admin`, `tenant_admin`, `branch_manager`
  - `get_accessible_branches()` - Uses `super_admin`, `tenant_admin`

#### 3. **Migration 020: RLS Policies**
- `supabase/migrations/020_enable_rls_policies.sql`
- Updated all RLS policies to use correct role names:
  - Tenant updates: `tenant_admin` only
  - Branch management: `super_admin`, `tenant_admin`
  - User management: `super_admin`, `tenant_admin`, `branch_manager`
  - Product management: `super_admin`, `tenant_admin`, `branch_manager`
  - Sales voiding: `super_admin`, `tenant_admin`, `branch_manager`

#### 4. **Validation Schemas**
- `lib/validation/schemas.ts`
- Updated `userRoleSchema`:
  ```typescript
  export const userRoleSchema = z.enum([
    'super_admin',
    'tenant_admin',
    'branch_manager',
    'staff',
    'rider'
  ]);
  ```

---

## Missing tenant_id Column Fix

### Second Issue Identified

When applying migration `020_enable_rls_policies.sql`, encountered error:
```
ERROR: column "tenant_id" does not exist
```

### Root Cause

The `sale_items` table (created in migration 004) does NOT have a `tenant_id` column, but migration 020 creates RLS policies that require it:

```sql
CREATE POLICY "Users can view sale items in their tenant"
    ON sale_items FOR SELECT
    USING (tenant_id = current_tenant_id());
```

**Original schema** (migration 004):
- sale_items only has: `sale_id`, `product_id`, `product_name`, `quantity`, `unit_price`, etc.
- No `tenant_id` column for direct RLS enforcement

### Solution Applied

Updated migration 015 to add `tenant_id` to `sale_items` table:

```sql
-- Add tenant_id column
ALTER TABLE sale_items ADD COLUMN tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;

-- Populate from sales table
UPDATE sale_items si
SET tenant_id = s.tenant_id
FROM sales s
WHERE si.sale_id = s.id;

-- Make NOT NULL
ALTER TABLE sale_items ALTER COLUMN tenant_id SET NOT NULL;
```

Also updated the `populate_sale_item_details()` trigger to auto-populate `tenant_id` from the sales table.

### Quick Fix Migration

Created `015a_add_tenant_id_to_sale_items.sql` - a standalone migration that:
1. Adds tenant_id to sale_items
2. Populates it from the sales table
3. Updates the trigger

You can run this separately if you've already applied migration 015.

---

## Migration Application Instructions

Now that the role enum issue is fixed, apply migrations in order:

### Via Supabase Dashboard SQL Editor

1. Navigate to: https://supabase.com/dashboard/project/ykbpznoqebhopyqpoqaf/sql/new
2. Copy and paste each migration file in order:

```bash
# Order of execution:
1. ✅ supabase/migrations/014_enhance_sales_table.sql
2. ✅ supabase/migrations/015_enhance_sale_items_table.sql (UPDATED - adds tenant_id)
   OR run 015a_add_tenant_id_to_sale_items.sql if you already ran 015
3. ✅ supabase/migrations/016_create_brands_categories.sql (FIXED - role names)
4. supabase/migrations/017_analytics_dimensions.sql
5. supabase/migrations/018_analytics_fact_tables.sql
6. ✅ supabase/migrations/019_rls_helper_functions.sql (FIXED - drops existing first)
7. ✅ supabase/migrations/020_enable_rls_policies.sql (FIXED - role names)
```

### Option A: If you haven't run any migrations yet
Run migrations 014-020 in order. Migration 015 now includes tenant_id for sale_items.

### Option B: If you've already run migration 015
1. Run `015a_add_tenant_id_to_sale_items.sql` first
2. Then continue with 017, 018, 019, 020

3. Run each migration and verify success before proceeding to next
4. After migrations, seed dimension tables:
   - Run seed script for `dim_date` (2020-2030)
   - Run seed script for `dim_time` (00:00-23:59)

### Via Supabase CLI

```bash
# If using CLI
supabase db push
```

---

## Role Permission Matrix

| Role             | Access Level | Permissions |
|------------------|--------------|-------------|
| `super_admin`    | Platform     | Full platform access, manage all tenants |
| `tenant_admin`   | Tenant       | Full tenant access, manage branches, users, products, view reports |
| `branch_manager` | Branch       | Manage branch operations, staff, inventory, view branch reports |
| `staff`          | Limited      | Process sales, manage customers, basic product access |
| `rider`          | Delivery     | View assigned deliveries, update delivery status |

---

## RLS Policy Structure

All RLS policies now follow this pattern:

### Read Access
- All users can read data within their tenant
- Access scoped by `current_tenant_id()`

### Write Access
- `tenant_admin` + `branch_manager` can manage: products, brands, categories, price history
- `tenant_admin` + `branch_manager` + `super_admin` can manage users
- `tenant_admin` only can update tenant settings
- All staff can create sales for their branch
- Managers can void sales

### Branch Isolation
- `super_admin` and `tenant_admin` see all branches in their tenant
- Other roles see only their assigned branch

---

## Testing Checklist

After applying migrations:

- [ ] Verify all 7 migrations applied successfully
- [ ] Check `user_role` enum contains: `super_admin`, `tenant_admin`, `branch_manager`, `staff`, `rider`
- [ ] Test RLS policies with different role levels
- [ ] Verify `current_tenant_id()` function works correctly
- [ ] Verify `has_permission()` function role hierarchy
- [ ] Test branch access for different roles
- [ ] Verify all 12 RLS helper functions are created
- [ ] Test CRUD operations for brands, categories, products
- [ ] Verify price history tracking on product updates
- [ ] Check dimension tables (`dim_date`, `dim_time`) are seeded

---

## Next Steps

With migrations fixed and applied:

1. ✅ Complete remaining Phase 2 utilities (error handling, logging)
2. Implement OTP service with Termii (T021-T023)
3. Setup session management (T024)
4. Create API middleware (T025)
5. Initialize shadcn/ui (T026-T027)
6. Build layout components (T029-T030)
7. Integrate Paystack payment (T031, T034)

---

**Resolution**: All role enum mismatches have been corrected. Migrations are now safe to apply.
