# Tenant-Scoped Products Migration Summary

## Overview
This migration transforms the database from **branch-scoped products** to **tenant-scoped products** with separate **branch inventory tracking**. This allows tenants to define products once and manage inventory levels independently at each branch.

## Key Changes

### 1. Database Schema Changes

#### New Table: `branch_inventory`
Tracks branch-specific inventory levels for tenant products.

**Fields that Branch Managers Can Manage:**
- `stock_quantity` - Current stock level at the branch
- `low_stock_threshold` - Alert threshold for low stock warnings
- `expiry_date` - Product expiry date (for perishable items)
- `expiry_alert_days` - Days before expiry to trigger alerts (default: 30)
- `is_active` - Enable/disable inventory tracking for this product at this branch

**System Fields:**
- `id`, `tenant_id`, `branch_id`, `product_id`
- `created_at`, `updated_at`
- Sync fields: `_sync_version`, `_sync_modified_at`, `_sync_client_id`, `_sync_is_deleted`

#### Updated Table: `products`
Now tenant-scoped instead of branch-scoped.

**Removed Fields:**
- `branch_id` - Products are now shared across all tenant branches
- `stock_quantity` - Moved to `branch_inventory`
- `low_stock_threshold` - Moved to `branch_inventory`
- `expiry_date` - Moved to `branch_inventory`
- `expiry_alert_days` - Moved to `branch_inventory`

**Retained Fields:**
- Product definition: `name`, `description`, `sku`, `barcode`, `category`
- Pricing: `unit_price`, `cost_price`
- Classification: `brand_id`, `category_id`
- Media: `image_url` (stored but not displayed in POS for performance)
- All system and sync fields

#### New View: `v_branch_products`
Convenient view that joins products with branch inventory.

```sql
SELECT * FROM v_branch_products
WHERE branch_id = 'xxx'
AND inventory_active = true;
```

Returns product details plus:
- Branch-specific `stock_quantity`, `low_stock_threshold`, etc.
- Computed fields: `is_low_stock`, `is_expiring_soon`

### 2. Access Control (RLS Policies)

#### For Tenant Admins
- **Full access** to all products and branch inventory across all branches
- Can view, create, update, and delete any inventory records

#### For Branch Managers
- **Full access** to their own branch's inventory
- Can manage all inventory fields: `stock_quantity`, `low_stock_threshold`, `expiry_date`, `expiry_alert_days`
- Can view all tenant products
- **Cannot** access other branches' inventory

#### For Staff (Cashier)
- **Can view** all products and inventory in their branch
- **Can update** inventory (stock levels) during sales transactions
- **Cannot** create or delete inventory records

### 3. API Updates

#### Products API (`/api/products`)

**GET**
```typescript
// Get products with branch inventory
GET /api/products?branchId=xxx

// Get all tenant products (without inventory)
GET /api/products?tenantId=xxx
```

**POST**
```typescript
// Create product and optionally initialize branch inventory
POST /api/products
{
  // Product fields (tenant-scoped)
  tenant_id: "...",
  name: "Product Name",
  sku: "SKU123",
  unit_price: 100.00,

  // Optional: Initialize inventory for a branch
  branch_id: "...",
  stock_quantity: 50,
  low_stock_threshold: 10,
  expiry_date: "2026-12-31",
  expiry_alert_days: 30
}
```

#### Branch Inventory API (`/api/branch-inventory`) **NEW**

**GET**
```typescript
// Get all inventory for a branch
GET /api/branch-inventory?branchId=xxx

// Get inventory for specific product at a branch
GET /api/branch-inventory?branchId=xxx&productId=yyy
```

**POST**
```typescript
// Add product inventory to a branch
POST /api/branch-inventory
{
  tenant_id: "...",
  branch_id: "...",
  product_id: "...",
  stock_quantity: 100,
  low_stock_threshold: 15,
  expiry_date: "2026-06-30",
  expiry_alert_days: 30
}
```

**PATCH**
```typescript
// Update inventory settings (Branch managers use this)
PATCH /api/branch-inventory
{
  id: "inventory_id",
  stock_quantity: 75,           // Optional
  low_stock_threshold: 20,      // Optional
  expiry_date: "2026-07-15",    // Optional
  expiry_alert_days: 45,        // Optional
  is_active: true               // Optional
}
```

**DELETE**
```typescript
// Soft delete inventory (sets is_active = false)
DELETE /api/branch-inventory?id=xxx
```

### 4. POS UI Changes

#### Product Selector
- **Removed product images** for faster load times
- Compact card design showing:
  - Product name
  - Price
  - Stock quantity
- Fixed height cards (h-28) for consistent layout
- Queries `v_branch_products` view for branch-specific data

#### Hooks (`hooks/use-pos.ts`)
- Updated to query `v_branch_products` view
- Sale processing updates `branch_inventory` instead of `products`
- Void/return operations restore stock to `branch_inventory`

## Data Migration

The migration automatically:
1. Creates `branch_inventory` table
2. Migrates existing product stock data to branch inventory
3. Merges duplicate products (same SKU/name) across branches into single tenant product
4. Updates all foreign key references (sale_items, transfer_items, order_items)
5. Removes duplicate products and branch-scoped columns
6. Updates RLS policies for new structure

## Branch Manager Workflow

### Managing Inventory Settings

Branch managers can adjust inventory parameters for their branch:

```typescript
// Example: Update low stock threshold for a product
await fetch('/api/branch-inventory', {
  method: 'PATCH',
  body: JSON.stringify({
    id: inventoryId,
    low_stock_threshold: 25,
    expiry_alert_days: 60
  })
});
```

### Adding New Product to Branch

When tenant admin creates a new product, branch managers can add it to their inventory:

```typescript
await fetch('/api/branch-inventory', {
  method: 'POST',
  body: JSON.stringify({
    tenant_id: tenantId,
    branch_id: branchId,
    product_id: newProductId,
    stock_quantity: 0,
    low_stock_threshold: 10
  })
});
```

### Adjusting Stock Levels

```typescript
// Manual stock adjustment (e.g., after physical count)
await fetch('/api/branch-inventory', {
  method: 'PATCH',
  body: JSON.stringify({
    id: inventoryId,
    stock_quantity: actualCount
  })
});
```

## Migration File Location

`supabase/migrations/20260223_tenant_scoped_products.sql`

## Known Conflicts and Resolutions

This migration required careful handling of several database dependencies. See `MIGRATION_CONFLICTS_RESOLVED.md` for detailed information on:

1. **Invalid enum value** - Fixed RLS policy using non-existent `sales_agent` role
2. **Column drop dependencies** - Dropped dependent views and indexes before removing columns
3. **Function overloading** - Used dynamic SQL to drop all `get_ecommerce_products` function variations

All conflicts have been resolved in the migration script.

## Next Steps

1. **Run the migration** against your Supabase database
2. **Test POS functionality** to ensure sales process works correctly
3. **Create admin UI** for branch managers to manage inventory settings
4. **Update any reports/analytics** to use `v_branch_products` view or join with `branch_inventory`
5. **Update mobile app** (if applicable) to sync new `branch_inventory` table

## Rollback Plan

If issues arise, you can:
1. Restore from database backup taken before migration
2. Re-add `branch_id` column to products table
3. Migrate data back from `branch_inventory` to `products`

**Important:** Always test migrations in a staging environment first!
