# Phase 1: Data Model & Entity Definitions

**Feature**: Multi-Tenant POS-First Super App Platform
**Created**: 2026-01-18
**Status**: Complete

## Overview

This document defines the complete data model for the multi-tenant POS platform including all entities, relationships, validation rules, and state transitions. The model supports offline-first architecture with Supabase PostgreSQL as the source of truth and SQLite/PowerSync for client-side persistence.

**Design Principles**:
- **Multi-tenant isolation**: All tenant-scoped tables include `tenant_id` with RLS policies
- **Multi-branch support**: Branch-scoped tables include `branch_id` for branch-level isolation
- **Offline-first**: All entities support local SQLite storage with sync metadata (paid tiers)
- **Audit trail**: Critical entities track creation, modification, and responsible user
- **Soft deletes**: Important records use `deleted_at` instead of hard deletion
- **Partitioning**: Large tables (sales, inventory_transactions) partitioned by date for performance

---

## Entity Definitions

### 1. Tenant

**Description**: Represents a business account on the platform with one or more branches.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique tenant identifier |
| `name` | VARCHAR(255) | NOT NULL | Business name |
| `slug` | VARCHAR(100) | UNIQUE, NOT NULL | URL-friendly identifier |
| `email` | VARCHAR(255) | UNIQUE | Primary contact email |
| `phone` | VARCHAR(20) | | Primary contact phone |
| `logo_url` | TEXT | | Tenant logo (Supabase Storage URL) |
| `brand_color` | VARCHAR(7) | | Primary brand color (hex code) |
| `subscription_id` | UUID | FK → Subscription | Current subscription plan |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Registration timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last modification |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

**Relationships**:
- `HAS MANY` → Branch (one tenant, multiple branches)
- `HAS MANY` → User (tenant staff members)
- `HAS ONE` → Subscription (current active subscription)

**RLS Policy**: Platform admins only (no RLS for tenants table)

**Indexes**:
- `idx_tenants_slug` on `slug` (unique lookups)
- `idx_tenants_subscription_id` on `subscription_id` (subscription queries)

---

### 2. Branch

**Description**: Physical or logical business location under a tenant.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique branch identifier |
| `tenant_id` | UUID | NOT NULL, FK → Tenant | Owning tenant |
| `name` | VARCHAR(255) | NOT NULL | Branch name |
| `slug` | VARCHAR(100) | NOT NULL | URL-friendly name for storefront |
| `business_type` | ENUM | NOT NULL | supermarket, pharmacy, grocery, mini-mart, restaurant |
| `address` | TEXT | | Physical address |
| `city` | VARCHAR(100) | | City name |
| `state` | VARCHAR(100) | | State/region |
| `country` | VARCHAR(2) | DEFAULT 'NG' | ISO country code |
| `latitude` | DECIMAL(10,8) | | GPS coordinate |
| `longitude` | DECIMAL(11,8) | | GPS coordinate |
| `phone` | VARCHAR(20) | | Branch contact |
| `email` | VARCHAR(255) | | Branch email |
| `tax_rate` | DECIMAL(5,2) | DEFAULT 7.5 | VAT percentage (Nigeria default: 7.5%) |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |
| `deleted_at` | TIMESTAMPTZ | | Soft delete |

**Relationships**:
- `BELONGS TO` → Tenant
- `HAS MANY` → Product
- `HAS MANY` → Sale
- `HAS MANY` → User (staff assignments)

**RLS Policy**: `tenant_id = auth.jwt() ->> 'tenant_id'`

**Indexes**:
- `idx_branches_tenant_id` on `tenant_id`
- `idx_branches_slug` on `(tenant_id, slug)` (unique within tenant)

**UNIQUE**: `(tenant_id, slug)`

---

### 3. User (Staff)

**Description**: Person using the system (staff member) belonging to a tenant.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Supabase Auth user ID |
| `tenant_id` | UUID | NOT NULL, FK → Tenant | |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL | |
| `phone` | VARCHAR(20) | UNIQUE | |
| `full_name` | VARCHAR(255) | NOT NULL | |
| `role` | ENUM | NOT NULL | platform_admin, tenant_admin, branch_manager, cashier, driver |
| `pin_code_hash` | VARCHAR(255) | | Hashed PIN for fallback auth |
| `passkeys` | JSONB | | Array of registered WebAuthn credentials |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |
| `deleted_at` | TIMESTAMPTZ | | Soft delete |

**Relationships**:
- `BELONGS TO` → Tenant
- `HAS MANY` → UserBranchAssignment (branch access)
- `HAS MANY` → Sale (as cashier)
- `HAS MANY` → StaffAttendance (clock in/out records)

**RLS Policy**: `tenant_id = auth.jwt() ->> 'tenant_id'`

**Indexes**:
- `idx_users_tenant_id` on `tenant_id`
- `idx_users_email` on `email`
- `idx_users_role` on `role`

---

### 4. UserBranchAssignment

**Description**: Many-to-many relationship between users and branches.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | |
| `user_id` | UUID | NOT NULL, FK → User | |
| `branch_id` | UUID | NOT NULL, FK → Branch | |
| `tenant_id` | UUID | NOT NULL, FK → Tenant | Denormalized for RLS |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |

**RLS Policy**: `tenant_id = auth.jwt() ->> 'tenant_id'`

**UNIQUE**: `(user_id, branch_id)`

**Indexes**:
- `idx_user_branch_user_id` on `user_id`
- `idx_user_branch_branch_id` on `branch_id`

---

### 5. Product

**Description**: Sellable item belonging to a specific branch.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | |
| `tenant_id` | UUID | NOT NULL, FK → Tenant | |
| `branch_id` | UUID | NOT NULL, FK → Branch | |
| `name` | VARCHAR(255) | NOT NULL | |
| `description` | TEXT | | |
| `sku` | VARCHAR(100) | NOT NULL | Stock Keeping Unit |
| `barcode` | VARCHAR(100) | | EAN/UPC barcode |
| `category` | VARCHAR(100) | | Product category |
| `price` | DECIMAL(12,2) | NOT NULL | Current selling price |
| `cost` | DECIMAL(12,2) | | Merchant cost (for margin calc) |
| `quantity` | INTEGER | NOT NULL, DEFAULT 0 | Current stock level |
| `unit` | VARCHAR(50) | | Unit of measure (piece, kg, liter, etc.) |
| `reorder_level` | INTEGER | DEFAULT 10 | Minimum stock before alert |
| `expiry_date` | DATE | | Product expiry (for perishables) |
| `image_url` | TEXT | | Product image (Supabase Storage) |
| `is_active` | BOOLEAN | DEFAULT TRUE | Visibility on storefront |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |
| `deleted_at` | TIMESTAMPTZ | | Soft delete |

**Relationships**:
- `BELONGS TO` → Branch
- `HAS MANY` → SaleItem
- `HAS MANY` → InventoryTransaction

**RLS Policy**: `tenant_id = auth.jwt() ->> 'tenant_id'`

**Indexes**:
- `idx_products_tenant_id` on `tenant_id`
- `idx_products_branch_id` on `branch_id`
- `idx_products_sku` on `(branch_id, sku)` (unique SKU per branch)
- `idx_products_barcode` on `barcode`
- `idx_products_expiry_date` on `expiry_date` WHERE `expiry_date IS NOT NULL`
- `idx_products_is_active` on `is_active`

**UNIQUE**: `(branch_id, sku)`

---

### 6. Sale

**Description**: Completed transaction (in-store or online).

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | |
| `tenant_id` | UUID | NOT NULL, FK → Tenant | |
| `branch_id` | UUID | NOT NULL, FK → Branch | |
| `cashier_id` | UUID | NOT NULL, FK → User | Staff member who processed sale |
| `customer_id` | UUID | FK → Customer | Optional (walk-in vs. registered) |
| `subtotal` | DECIMAL(12,2) | NOT NULL | Before tax and discounts |
| `tax_amount` | DECIMAL(12,2) | DEFAULT 0 | VAT amount |
| `discount_amount` | DECIMAL(12,2) | DEFAULT 0 | Total discounts |
| `total` | DECIMAL(12,2) | NOT NULL | Final amount (subtotal + tax - discount) |
| `payment_method` | ENUM | NOT NULL | cash, card, mobile_money, bank_transfer |
| `payment_status` | ENUM | NOT NULL | pending, completed, failed, refunded |
| `notes` | TEXT | | Optional notes |
| `receipt_number` | VARCHAR(50) | UNIQUE, NOT NULL | Auto-generated |
| `sync_status` | ENUM | NOT NULL | pending, synced, failed | PowerSync status |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Transaction timestamp |
| `synced_at` | TIMESTAMPTZ | | When synced to cloud |

**Relationships**:
- `BELONGS TO` → Branch
- `BELONGS TO` → User (cashier)
- `BELONGS TO` → Customer (optional)
- `HAS MANY` → SaleItem

**RLS Policy**: `tenant_id = auth.jwt() ->> 'tenant_id'`

**Partitioning**: Monthly partitions by `created_at`

**Indexes**:
- `idx_sales_tenant_id` on `tenant_id`
- `idx_sales_branch_id` on `branch_id`
- `idx_sales_cashier_id` on `cashier_id`
- `idx_sales_customer_id` on `customer_id`
- `idx_sales_created_at` on `created_at` (for date-range queries)
- `idx_sales_sync_status` on `sync_status` WHERE `sync_status != 'synced'`

---

### 7. SaleItem

**Description**: Line item in a sale transaction.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | |
| `sale_id` | UUID | NOT NULL, FK → Sale | |
| `product_id` | UUID | NOT NULL, FK → Product | |
| `tenant_id` | UUID | NOT NULL, FK → Tenant | Denormalized for RLS |
| `quantity` | INTEGER | NOT NULL | Items sold |
| `unit_price` | DECIMAL(12,2) | NOT NULL | Price at time of sale |
| `discount` | DECIMAL(12,2) | DEFAULT 0 | Item-level discount |
| `subtotal` | DECIMAL(12,2) | NOT NULL | quantity * unit_price - discount |

**RLS Policy**: `tenant_id = auth.jwt() ->> 'tenant_id'`

**Indexes**:
- `idx_sale_items_sale_id` on `sale_id`
- `idx_sale_items_product_id` on `product_id`

---

### 8. Customer

**Description**: Person making purchases (walk-in or registered).

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | |
| `tenant_id` | UUID | NOT NULL, FK → Tenant | |
| `phone` | VARCHAR(20) | UNIQUE | Primary identifier |
| `email` | VARCHAR(255) | UNIQUE | |
| `full_name` | VARCHAR(255) | NOT NULL | |
| `whatsapp_number` | VARCHAR(20) | | For WhatsApp notifications |
| `approved_loyalty_points` | INTEGER | DEFAULT 0 | Available for redemption |
| `pending_loyalty_points` | INTEGER | DEFAULT 0 | Awaiting merchant approval |
| `total_spent` | DECIMAL(12,2) | DEFAULT 0 | Lifetime spend |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |
| `deleted_at` | TIMESTAMPTZ | | NDPR data deletion |

**Relationships**:
- `HAS MANY` → Sale
- `HAS MANY` → Order
- `HAS MANY` → LoyaltyPointsTransaction
- `HAS MANY` → CustomerAddress

**RLS Policy**: `tenant_id = auth.jwt() ->> 'tenant_id'`

**Indexes**:
- `idx_customers_tenant_id` on `tenant_id`
- `idx_customers_phone` on `phone`
- `idx_customers_email` on `email`

---

### 9. LoyaltyPointsTransaction

**Description**: Record of loyalty points earning, approval, redemption, or revocation.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | |
| `tenant_id` | UUID | NOT NULL, FK → Tenant | |
| `customer_id` | UUID | NOT NULL, FK → Customer | |
| `sale_id` | UUID | FK → Sale | Earning transaction |
| `order_id` | UUID | FK → Order | Earning transaction |
| `points_amount` | INTEGER | NOT NULL | Can be negative for redemption/revocation |
| `transaction_type` | ENUM | NOT NULL | earned, redeemed, revoked |
| `status` | ENUM | NOT NULL | pending_approval, approved, rejected, revoked |
| `approver_id` | UUID | FK → User | Staff who approved/rejected |
| `approval_timestamp` | TIMESTAMPTZ | | When approved/rejected |
| `rejection_reason` | TEXT | | Why rejected |
| `revocation_reason` | TEXT | | Why revoked |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |

**RLS Policy**: `tenant_id = auth.jwt() ->> 'tenant_id'`

**Indexes**:
- `idx_loyalty_customer_id` on `customer_id`
- `idx_loyalty_status` on `status` WHERE `status = 'pending_approval'`
- `idx_loyalty_created_at` on `created_at`

---

### 10. Order

**Description**: Customer order from marketplace or e-commerce sync.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | |
| `tenant_id` | UUID | NOT NULL, FK → Tenant | |
| `branch_id` | UUID | NOT NULL, FK → Branch | |
| `customer_id` | UUID | NOT NULL, FK → Customer | |
| `order_number` | VARCHAR(50) | UNIQUE, NOT NULL | Auto-generated |
| `subtotal` | DECIMAL(12,2) | NOT NULL | |
| `tax_amount` | DECIMAL(12,2) | DEFAULT 0 | |
| `discount_amount` | DECIMAL(12,2) | DEFAULT 0 | |
| `delivery_fee` | DECIMAL(12,2) | DEFAULT 0 | Calculated from distance |
| `delivery_distance_km` | DECIMAL(8,2) | | Calculated delivery distance |
| `total` | DECIMAL(12,2) | NOT NULL | |
| `payment_method` | ENUM | NOT NULL | |
| `payment_status` | ENUM | NOT NULL | pending, completed, failed, refunded |
| `order_status` | ENUM | NOT NULL | pending, confirmed, preparing, ready, out_for_delivery, delivered, cancelled |
| `fulfillment_type` | ENUM | NOT NULL | pickup, delivery |
| `delivery_address_id` | UUID | FK → CustomerAddress | |
| `notes` | TEXT | | Customer instructions |
| `source` | ENUM | NOT NULL | marketplace, woocommerce, shopify |
| `external_order_id` | VARCHAR(100) | | E-commerce platform order ID |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |

**Relationships**:
- `BELONGS TO` → Branch
- `BELONGS TO` → Customer
- `HAS MANY` → OrderItem
- `HAS ONE` → Delivery (if fulfillment_type = delivery)

**RLS Policy**: `tenant_id = auth.jwt() ->> 'tenant_id'`

**Indexes**:
- `idx_orders_tenant_id` on `tenant_id`
- `idx_orders_branch_id` on `branch_id`
- `idx_orders_customer_id` on `customer_id`
- `idx_orders_order_status` on `order_status`
- `idx_orders_created_at` on `created_at`
- `idx_orders_external_order_id` on `(source, external_order_id)` (prevent duplicate imports)

---

### 11. Delivery

**Description**: Delivery task for an order.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | |
| `tenant_id` | UUID | NOT NULL, FK → Tenant | |
| `order_id` | UUID | NOT NULL, FK → Order | |
| `delivery_type` | ENUM | NOT NULL | local_bike, inter_city |
| `rider_id` | UUID | FK → Rider | Assigned local rider |
| `tracking_number` | VARCHAR(100) | UNIQUE, NOT NULL | |
| `delivery_distance_km` | DECIMAL(8,2) | NOT NULL | |
| `delivery_fee_charged` | DECIMAL(12,2) | NOT NULL | |
| `estimated_delivery_time` | TIMESTAMPTZ | | |
| `status` | ENUM | NOT NULL | pending, assigned, picked_up, in_transit, delivered, failed, cancelled |
| `proof_of_delivery_url` | TEXT | | Photo or signature (Supabase Storage) |
| `delivered_at` | TIMESTAMPTZ | | |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |

**RLS Policy**: `tenant_id = auth.jwt() ->> 'tenant_id'`

**Indexes**:
- `idx_delivery_order_id` on `order_id`
- `idx_delivery_rider_id` on `rider_id`
- `idx_delivery_status` on `status`
- `idx_delivery_tracking_number` on `tracking_number`

---

### 12. DeliveryFeeConfig

**Description**: Tenant-level delivery fee distance ranges (admin-configured).

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | |
| `tenant_id` | UUID | NOT NULL, FK → Tenant | |
| `distance_ranges` | JSONB | NOT NULL | Array of {min_km, max_km, suggested_fee} |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |

**Example JSONB**:
```json
[
  {"min_km": 0, "max_km": 5, "suggested_fee": 300},
  {"min_km": 5, "max_km": 10, "suggested_fee": 500},
  {"min_km": 10, "max_km": 25, "suggested_fee": 800}
]
```

**RLS Policy**: `tenant_id = auth.jwt() ->> 'tenant_id'`

---

### 13. BranchDeliveryFee

**Description**: Branch-specific delivery fee overrides (merchant-configured).

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | |
| `tenant_id` | UUID | NOT NULL, FK → Tenant | |
| `branch_id` | UUID | NOT NULL, FK → Branch | |
| `min_km` | DECIMAL(8,2) | NOT NULL | |
| `max_km` | DECIMAL(8,2) | NOT NULL | |
| `fee_amount` | DECIMAL(12,2) | NOT NULL | Merchant-set fee |
| `is_active` | BOOLEAN | DEFAULT TRUE | |

**RLS Policy**: `tenant_id = auth.jwt() ->> 'tenant_id'`

**Indexes**:
- `idx_branch_delivery_fee_branch_id` on `branch_id`

---

### 14. Subscription

**Description**: Tenant subscription plan state.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | |
| `tenant_id` | UUID | NOT NULL, FK → Tenant | |
| `tier` | ENUM | NOT NULL | free, basic, pro, enterprise, enterprise_custom |
| `monthly_fee` | DECIMAL(12,2) | NOT NULL | Monthly subscription cost (₦) |
| `commission_rate` | DECIMAL(5,2) | NOT NULL | Marketplace commission percentage |
| `commission_cap_amount` | DECIMAL(12,2) | DEFAULT 500.00 | Maximum commission per order (₦) |
| `billing_cycle` | ENUM | NOT NULL | monthly, annual |
| `status` | ENUM | NOT NULL | active, suspended, cancelled |
| `max_branches` | INTEGER | NOT NULL | |
| `max_staff_users` | INTEGER | NOT NULL | Tier limit |
| `max_products` | INTEGER | NOT NULL | |
| `monthly_transaction_quota` | INTEGER | NOT NULL | |
| `features` | JSONB | NOT NULL | Feature flags JSON (ai_chat, ecommerce_enabled, etc.) |
| `billing_cycle_start` | TIMESTAMPTZ | NOT NULL | Current billing period start |
| `billing_cycle_end` | TIMESTAMPTZ | NOT NULL | Current billing period end |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |

**RLS Policy**: `tenant_id = auth.jwt() ->> 'tenant_id'`

**Indexes**:
- `idx_subscription_tenant_id` on `tenant_id`
- `idx_subscription_status` on `status`
- `idx_subscription_next_billing_date` on `next_billing_date`

---

### 15. SupportTicket

**Description**: Customer support request with SLA tracking.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | |
| `tenant_id` | UUID | NOT NULL, FK → Tenant | |
| `requester_id` | UUID | NOT NULL, FK → User | |
| `ticket_number` | VARCHAR(50) | UNIQUE, NOT NULL | Auto-generated |
| `subject` | VARCHAR(255) | NOT NULL | |
| `description` | TEXT | NOT NULL | |
| `category` | ENUM | NOT NULL | technical, billing, feature_request, other |
| `priority` | ENUM | NOT NULL | low, medium, high, critical |
| `status` | ENUM | NOT NULL | open, pending, resolved, closed |
| `assigned_agent_id` | UUID | FK → User | Support agent |
| `sla_deadline` | TIMESTAMPTZ | NOT NULL | Calculated based on tier and business hours |
| `first_response_at` | TIMESTAMPTZ | | |
| `resolved_at` | TIMESTAMPTZ | | |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |

**RLS Policy**: `tenant_id = auth.jwt() ->> 'tenant_id'`

**Indexes**:
- `idx_support_tenant_id` on `tenant_id`
- `idx_support_status` on `status`
- `idx_support_sla_deadline` on `sla_deadline` WHERE `status != 'resolved' AND status != 'closed'`

---

### 16. CustomerDataDeletionRequest

**Description**: NDPR compliance - customer data deletion requests.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | |
| `tenant_id` | UUID | NOT NULL, FK → Tenant | |
| `customer_id` | UUID | NOT NULL, FK → Customer | |
| `request_timestamp` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | |
| `merchant_review_status` | ENUM | NOT NULL | pending, approved, rejected |
| `reviewer_id` | UUID | FK → User | |
| `review_timestamp` | TIMESTAMPTZ | | |
| `deletion_execution_timestamp` | TIMESTAMPTZ | | |
| `scope_of_deletion` | TEXT | | What data was deleted |
| `audit_trail` | JSONB | | Log of deletion actions |

**RLS Policy**: `tenant_id = auth.jwt() ->> 'tenant_id'`

---

## State Transitions

### Order Status Flow

```
pending → confirmed → preparing → ready → out_for_delivery → delivered
   ↓          ↓           ↓          ↓             ↓
 cancelled  cancelled  cancelled  cancelled    cancelled
```

### Delivery Status Flow

```
pending → assigned → picked_up → in_transit → delivered
   ↓         ↓           ↓            ↓
 cancelled cancelled  cancelled    failed
```

### Payment Status Flow

```
pending → completed
   ↓
 failed → refunded (if initially completed)
```

### Support Ticket Status Flow

```
open → pending → resolved → closed
```

---

## Validation Rules

### Product
- `price >= 0`
- `quantity >= 0`
- `expiry_date >= CURRENT_DATE` (if set)
- `reorder_level >= 0`

### Sale
- `total = subtotal + tax_amount - discount_amount`
- `tax_amount >= 0`
- `discount_amount >= 0 AND discount_amount <= subtotal`
- `receipt_number` must be unique per tenant

### SaleItem
- `quantity > 0`
- `unit_price >= 0`
- `subtotal = quantity * unit_price - discount`

### Order
- `total = subtotal + tax_amount + delivery_fee - discount_amount`
- `delivery_fee >= 0`
- If `fulfillment_type = 'delivery'`, `delivery_address_id` must be set

### LoyaltyPointsTransaction
- Default earning rate: 1 point per ₦100 spent (configurable per tenant)
- Points cannot be redeemed if `status != 'approved'`

### Subscription Limits Enforcement
- Application must check limits before operations:
  - Creating user: `COUNT(users WHERE tenant_id = X) < subscription.max_users`
  - Creating branch: `COUNT(branches WHERE tenant_id = X) < subscription.max_branches`
  - Creating product: `COUNT(products WHERE tenant_id = X) < subscription.max_products`
  - Creating sale/order: `COUNT(sales WHERE tenant_id = X AND created_at >= period_start) < subscription.max_transactions_per_month`

---

## Indexes Strategy

**Critical for Performance**:
1. **tenant_id** on all tenant-scoped tables (multi-tenant isolation)
2. **branch_id** on branch-scoped tables
3. **created_at** on time-series tables (sales, orders, inventory_transactions)
4. **status** fields (order_status, payment_status, sync_status) - filtered queries
5. Composite indexes for common query patterns

**PowerSync Considerations**:
- All tables synced offline need `updated_at` for incremental sync
- Compound index on `(tenant_id, updated_at)` for sync queries

---

## Partitioning Strategy

### Sales Table (Monthly Partitions)

```sql
CREATE TABLE sales_parent (
  -- all columns
) PARTITION BY RANGE (created_at);

CREATE TABLE sales_2026_01 PARTITION OF sales_parent
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE sales_2026_02 PARTITION OF sales_parent
FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
-- etc.
```

**Benefits**:
- Faster queries (partition pruning)
- Easier archival (detach old partitions)
- Better vacuum performance

**Auto-create partitions**: Implement cron job to create next month's partition

---

## RLS Policies Examples

### Tenant-Scoped Table (e.g., Branch)

```sql
CREATE POLICY "Users can only access their tenant's branches"
ON branches FOR ALL
USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);
```

### Branch-Scoped Table (e.g., Product)

```sql
CREATE POLICY "Users can only access products from their assigned branches"
ON products FOR ALL
USING (
  branch_id IN (
    SELECT branch_id FROM user_branch_assignments
    WHERE user_id = auth.uid() AND tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  )
);
```

### Role-Based (e.g., Platform Admin)

```sql
CREATE POLICY "Platform admins can access all tenants"
ON tenants FOR ALL
USING (
  (auth.jwt() ->> 'role')::text = 'platform_admin'
);
```

---

## Sync Metadata (PowerSync)

All synced tables include:
- `created_at`: Initial creation
- `updated_at`: Last modification (trigger-updated)
- `sync_status`: For tracking sync state

**Trigger Example**:
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
```

---

## Summary

**Total Tables**: 16 core entities + additional supporting tables (addresses, staff attendance, inventory transactions, etc.)

**Multi-Tenancy**: Enforced via `tenant_id` + RLS policies on all scoped tables

**Offline Support**: PowerSync syncs all tenant-scoped data to SQLite (paid tiers)

**Performance**: Partitioning on sales, indexes on all foreign keys and filter columns

**Compliance**: NDPR data deletion via CustomerDataDeletionRequest workflow

**Scalability**: Designed for 10,000 tenants, 1M transactions/month, indefinite retention with archival

---

**Phase 1 Status**: ✅ Data Model Complete

Ready to proceed to API contract definitions and quickstart guide.
