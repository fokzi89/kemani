# Phase 1: Data Model & Entity Definitions

**Feature**: Multi-Tenant POS-First Super App Platform
**Created**: 2026-01-17
**Status**: Complete

## Overview

This document defines the complete data model for the multi-tenant POS platform including all entities, relationships, validation rules, and state transitions. The model supports offline-first architecture with Supabase PostgreSQL as the source of truth and SQLite for client-side persistence.

**Design Principles**:
- **Multi-tenant isolation**: All tenant-scoped tables include `tenant_id` with RLS policies
- **Multi-branch support**: Branch-scoped tables include `branch_id` for branch-level isolation
- **Offline-first**: All entities support local SQLite storage with sync metadata
- **Audit trail**: Critical entities track creation, modification, and responsible user
- **Soft deletes**: Important records use `deleted_at` instead of hard deletion

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
- `HAS ONE` → Subscription (current plan)
- `HAS MANY` → ECommerceConnection (integrated platforms)

**Validation Rules**:
- `name`: 1-255 characters, required
- `slug`: lowercase, alphanumeric + hyphens, must be unique
- `email`: valid email format if provided
- `phone`: E.164 format (e.g., +2348012345678)
- `brand_color`: valid hex color (#RRGGBB)

**Indexes**:
```sql
CREATE INDEX idx_tenants_slug ON tenants(slug);
CREATE INDEX idx_tenants_email ON tenants(email) WHERE email IS NOT NULL;
CREATE INDEX idx_tenants_deleted ON tenants(deleted_at) WHERE deleted_at IS NULL;
```

---

### 2. Branch

**Description**: Physical or logical business location under a tenant (e.g., pharmacy location, supermarket outlet).

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique branch identifier |
| `tenant_id` | UUID | FK → Tenant, NOT NULL | Parent tenant |
| `name` | VARCHAR(255) | NOT NULL | Branch name |
| `business_type` | ENUM | NOT NULL | Type: supermarket, pharmacy, grocery, mini_mart, restaurant |
| `address` | TEXT | | Physical address |
| `latitude` | DECIMAL(10,8) | | GPS latitude |
| `longitude` | DECIMAL(11,8) | | GPS longitude |
| `phone` | VARCHAR(20) | | Branch contact phone |
| `tax_rate` | DECIMAL(5,2) | DEFAULT 0, CHECK >= 0 | Tax percentage (e.g., 7.5 for VAT) |
| `currency` | VARCHAR(3) | DEFAULT 'NGN' | Currency code (ISO 4217) |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last modification |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

**Relationships**:
- `BELONGS TO` → Tenant (many branches, one tenant)
- `HAS MANY` → Product (branch inventory)
- `HAS MANY` → User (branch staff assignments)
- `HAS MANY` → Sale (transactions at this branch)
- `HAS MANY` → InterBranchTransfer (as source or destination)

**Validation Rules**:
- `name`: 1-255 characters, required
- `business_type`: must be one of: supermarket, pharmacy, grocery, mini_mart, restaurant
- `tax_rate`: 0-100 (percentage)
- `currency`: ISO 4217 currency code
- `latitude`: -90 to 90 if provided
- `longitude`: -180 to 180 if provided

**Indexes**:
```sql
CREATE INDEX idx_branches_tenant ON branches(tenant_id, deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_branches_location ON branches USING GIST(ll_to_earth(latitude, longitude)) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
```

**RLS Policy**:
```sql
-- Users can only access branches within their tenant
CREATE POLICY "Tenant branch isolation" ON branches
  FOR ALL USING (tenant_id = current_tenant_id());
```

---

### 3. User

**Description**: Platform user including staff members (cashiers, managers) and platform admins.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique user identifier (auth.uid()) |
| `tenant_id` | UUID | FK → Tenant, NULLABLE | Tenant affiliation (null for platform admins) |
| `email` | VARCHAR(255) | UNIQUE | Email address (authentication) |
| `phone` | VARCHAR(20) | UNIQUE | Phone number (authentication) |
| `full_name` | VARCHAR(255) | NOT NULL | User full name |
| `role` | ENUM | NOT NULL | Role: platform_admin, tenant_admin, branch_manager, cashier, driver |
| `branch_id` | UUID | FK → Branch, NULLABLE | Primary branch assignment |
| `avatar_url` | TEXT | | Profile picture URL |
| `last_login_at` | TIMESTAMPTZ | | Last login timestamp |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Account creation |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last modification |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

**Relationships**:
- `BELONGS TO` → Tenant (staff member of tenant)
- `BELONGS TO` → Branch (primary branch assignment)
- `HAS MANY` → Sale (as cashier)
- `HAS MANY` → StaffAttendance (clock in/out records)
- `HAS MANY` → Delivery (as assigned rider)

**Validation Rules**:
- `email` OR `phone`: at least one required for authentication
- `email`: valid email format if provided
- `phone`: E.164 format if provided
- `full_name`: 1-255 characters, required
- `role`: must be one of: platform_admin, tenant_admin, branch_manager, cashier, driver

**Role Permissions**:
| Role | Permissions |
|------|-------------|
| `platform_admin` | Full system access, all tenants |
| `tenant_admin` | Full access to own tenant, all branches |
| `branch_manager` | Full access to assigned branch |
| `cashier` | POS operations, read products, create sales |
| `driver` | View assigned deliveries, update delivery status |

**Indexes**:
```sql
CREATE INDEX idx_users_tenant ON users(tenant_id, deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_branch ON users(branch_id, deleted_at) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL AND deleted_at IS NULL;
CREATE UNIQUE INDEX idx_users_phone ON users(phone) WHERE phone IS NOT NULL AND deleted_at IS NULL;
```

**RLS Policy**:
```sql
-- Branch managers see only their branch users, tenant admins see all tenant users
CREATE POLICY "User access control" ON users
  FOR SELECT USING (
    tenant_id = current_tenant_id() AND (
      current_user_role() = 'tenant_admin' OR
      branch_id = current_user_branch_id()
    )
  );
```

---

### 4. Product

**Description**: Sellable item in branch inventory with stock tracking and expiry management.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique product identifier |
| `tenant_id` | UUID | FK → Tenant, NOT NULL | Tenant ownership |
| `branch_id` | UUID | FK → Branch, NOT NULL | Branch inventory |
| `name` | VARCHAR(255) | NOT NULL | Product name |
| `description` | TEXT | | Product description |
| `sku` | VARCHAR(100) | | Stock Keeping Unit |
| `barcode` | VARCHAR(100) | | Barcode/UPC/EAN |
| `category` | VARCHAR(100) | | Product category |
| `unit_price` | DECIMAL(12,2) | NOT NULL, CHECK > 0 | Selling price (in cents) |
| `cost_price` | DECIMAL(12,2) | CHECK >= 0 | Purchase cost |
| `stock_quantity` | INTEGER | NOT NULL, DEFAULT 0, CHECK >= 0 | Current stock level |
| `low_stock_threshold` | INTEGER | DEFAULT 10, CHECK >= 0 | Reorder threshold |
| `expiry_date` | DATE | | Product expiry (for perishables) |
| `expiry_alert_days` | INTEGER | DEFAULT 30, CHECK >= 0 | Alert threshold (days before expiry) |
| `image_url` | TEXT | | Product image (Supabase Storage) |
| `is_active` | BOOLEAN | DEFAULT TRUE | Available for sale |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Product creation |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last modification |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

**Relationships**:
- `BELONGS TO` → Tenant
- `BELONGS TO` → Branch (branch-specific inventory)
- `HAS MANY` → SaleItem (sales history)
- `HAS MANY` → InventoryTransaction (stock movements)
- `HAS MANY` → InterBranchTransfer (via transfer line items)

**Validation Rules**:
- `name`: 1-255 characters, required
- `sku`: unique within tenant if provided
- `barcode`: unique within tenant if provided
- `unit_price`: > 0, stored in cents (e.g., ₦1,500 = 150000)
- `cost_price`: >= 0 if provided
- `stock_quantity`: >= 0 (cannot go negative)
- `expiry_date`: must be future date if provided

**Computed Fields**:
- `is_low_stock`: `stock_quantity <= low_stock_threshold`
- `is_expiring_soon`: `expiry_date <= CURRENT_DATE + expiry_alert_days`
- `days_until_expiry`: `expiry_date - CURRENT_DATE`

**Indexes**:
```sql
CREATE INDEX idx_products_tenant_branch ON products(tenant_id, branch_id, deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_sku ON products(tenant_id, sku) WHERE sku IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_products_barcode ON products(tenant_id, barcode) WHERE barcode IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_products_expiry ON products(expiry_date) WHERE expiry_date IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_products_low_stock ON products(branch_id) WHERE stock_quantity <= low_stock_threshold AND deleted_at IS NULL;
```

**RLS Policy**:
```sql
CREATE POLICY "Branch product isolation" ON products
  FOR ALL USING (
    tenant_id = current_tenant_id() AND (
      current_user_role() = 'tenant_admin' OR
      branch_id = current_user_branch_id()
    )
  );
```

---

### 5. InventoryTransaction

**Description**: Audit trail of all inventory changes (sales, restocks, adjustments, transfers, expiry).

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique transaction identifier |
| `tenant_id` | UUID | FK → Tenant, NOT NULL | Tenant ownership |
| `branch_id` | UUID | FK → Branch, NOT NULL | Branch where change occurred |
| `product_id` | UUID | FK → Product, NOT NULL | Affected product |
| `transaction_type` | ENUM | NOT NULL | Type: sale, restock, adjustment, expiry, transfer_out, transfer_in |
| `quantity_delta` | INTEGER | NOT NULL | Stock change (+ or -) |
| `previous_quantity` | INTEGER | NOT NULL | Stock before change |
| `new_quantity` | INTEGER | NOT NULL | Stock after change |
| `unit_cost` | DECIMAL(12,2) | | Cost per unit (for restock) |
| `reference_id` | UUID | | Related entity (Sale, InterBranchTransfer) |
| `reference_type` | VARCHAR(50) | | Entity type (Sale, Transfer) |
| `notes` | TEXT | | Transaction notes |
| `staff_id` | UUID | FK → User, NOT NULL | Responsible staff |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Transaction timestamp |

**Relationships**:
- `BELONGS TO` → Tenant
- `BELONGS TO` → Branch
- `BELONGS TO` → Product
- `BELONGS TO` → User (staff member)
- `REFERENCES` → Sale OR InterBranchTransfer (polymorphic)

**Validation Rules**:
- `quantity_delta`: non-zero integer
- `new_quantity`: must equal `previous_quantity + quantity_delta`
- `new_quantity`: >= 0 (cannot create negative stock)
- `unit_cost`: >= 0 if provided (for restock transactions)

**Transaction Types**:
| Type | Description | Quantity Delta |
|------|-------------|----------------|
| `sale` | Product sold to customer | Negative |
| `restock` | Stock replenishment | Positive |
| `adjustment` | Manual stock correction | Positive or Negative |
| `expiry` | Expired products removed | Negative |
| `transfer_out` | Sent to another branch | Negative |
| `transfer_in` | Received from another branch | Positive |

**Indexes**:
```sql
CREATE INDEX idx_inventory_txn_branch_product ON inventory_transactions(branch_id, product_id, created_at DESC);
CREATE INDEX idx_inventory_txn_reference ON inventory_transactions(reference_type, reference_id);
CREATE INDEX idx_inventory_txn_type ON inventory_transactions(transaction_type, created_at DESC);
```

**Trigger**: Update `products.stock_quantity` on INSERT

---

### 6. InterBranchTransfer

**Description**: Transfer of inventory between branches within same tenant.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique transfer identifier |
| `tenant_id` | UUID | FK → Tenant, NOT NULL | Tenant ownership |
| `source_branch_id` | UUID | FK → Branch, NOT NULL | Sending branch |
| `destination_branch_id` | UUID | FK → Branch, NOT NULL | Receiving branch |
| `transfer_date` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Transfer initiation date |
| `status` | ENUM | NOT NULL, DEFAULT 'pending' | Status: pending, in_transit, completed, cancelled |
| `notes` | TEXT | | Transfer notes |
| `authorized_by_id` | UUID | FK → User, NOT NULL | Authorizing staff (manager/admin) |
| `received_by_id` | UUID | FK → User | Staff who received transfer |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last modification |

**Transfer Items** (separate table for line items):
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique line item identifier |
| `transfer_id` | UUID | FK → InterBranchTransfer, NOT NULL | Parent transfer |
| `product_id` | UUID | FK → Product, NOT NULL | Transferred product |
| `quantity` | INTEGER | NOT NULL, CHECK > 0 | Quantity transferred |

**Relationships**:
- `BELONGS TO` → Tenant
- `BELONGS TO` → Branch (source)
- `BELONGS TO` → Branch (destination)
- `BELONGS TO` → User (authorized_by)
- `BELONGS TO` → User (received_by)
- `HAS MANY` → TransferItem (line items)

**Validation Rules**:
- `source_branch_id` ≠ `destination_branch_id` (cannot transfer to same branch)
- Both branches must belong to same `tenant_id`
- Source branch must have sufficient stock for all transfer items
- Only `tenant_admin` or `branch_manager` can authorize transfers

**State Transitions**:
```
pending → in_transit → completed
pending → cancelled
```

**Indexes**:
```sql
CREATE INDEX idx_transfers_tenant ON inter_branch_transfers(tenant_id, created_at DESC);
CREATE INDEX idx_transfers_source ON inter_branch_transfers(source_branch_id, status);
CREATE INDEX idx_transfers_destination ON inter_branch_transfers(destination_branch_id, status);
```

**Trigger**: Create `InventoryTransaction` records on status change to `completed`

---

### 7. Sale

**Description**: Completed point-of-sale transaction with payment and items sold.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique sale identifier |
| `tenant_id` | UUID | FK → Tenant, NOT NULL | Tenant ownership |
| `branch_id` | UUID | FK → Branch, NOT NULL | Branch where sale occurred |
| `sale_number` | VARCHAR(50) | UNIQUE, NOT NULL | Human-readable sale reference |
| `cashier_id` | UUID | FK → User, NOT NULL | Staff who processed sale |
| `customer_id` | UUID | FK → Customer | Registered customer (optional) |
| `subtotal` | DECIMAL(12,2) | NOT NULL, CHECK >= 0 | Sum of line items |
| `tax_amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0, CHECK >= 0 | Tax charged |
| `discount_amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0, CHECK >= 0 | Discounts applied |
| `total_amount` | DECIMAL(12,2) | NOT NULL, CHECK > 0 | Final amount paid |
| `payment_method` | ENUM | NOT NULL | Method: cash, card, bank_transfer, mobile_money |
| `payment_reference` | VARCHAR(255) | | External payment reference (card transactions) |
| `status` | ENUM | NOT NULL, DEFAULT 'completed' | Status: completed, voided, refunded |
| `voided_at` | TIMESTAMPTZ | | Void timestamp |
| `voided_by_id` | UUID | FK → User | Staff who voided sale |
| `void_reason` | TEXT | | Reason for voiding |
| `is_synced` | BOOLEAN | DEFAULT FALSE | Synced to cloud |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Sale timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last modification |

**Relationships**:
- `BELONGS TO` → Tenant
- `BELONGS TO` → Branch
- `BELONGS TO` → User (cashier)
- `BELONGS TO` → Customer (optional)
- `HAS MANY` → SaleItem (line items)
- `HAS ONE` → Receipt

**Validation Rules**:
- `sale_number`: unique within tenant, format: `{branch_code}-{YYYYMMDD}-{sequence}`
- `total_amount`: must equal `subtotal + tax_amount - discount_amount`
- `subtotal`: must equal sum of all `SaleItem.subtotal`
- Voided sales cannot be modified

**Indexes**:
```sql
CREATE INDEX idx_sales_tenant_branch ON sales(tenant_id, branch_id, created_at DESC);
CREATE INDEX idx_sales_cashier ON sales(cashier_id, created_at DESC);
CREATE INDEX idx_sales_customer ON sales(customer_id, created_at DESC) WHERE customer_id IS NOT NULL;
CREATE INDEX idx_sales_status ON sales(status, created_at DESC);
CREATE INDEX idx_sales_sync ON sales(is_synced) WHERE is_synced = FALSE;
CREATE UNIQUE INDEX idx_sales_number ON sales(tenant_id, sale_number);
```

**Trigger**: Create `InventoryTransaction` records on INSERT (transaction_type='sale')

---

### 8. SaleItem

**Description**: Line item in a sale representing a product sold.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique line item identifier |
| `sale_id` | UUID | FK → Sale, NOT NULL | Parent sale |
| `product_id` | UUID | FK → Product, NOT NULL | Product sold |
| `product_name` | VARCHAR(255) | NOT NULL | Product name at time of sale |
| `quantity` | INTEGER | NOT NULL, CHECK > 0 | Quantity sold |
| `unit_price` | DECIMAL(12,2) | NOT NULL, CHECK > 0 | Price per unit at sale |
| `discount_percent` | DECIMAL(5,2) | DEFAULT 0, CHECK >= 0 AND <= 100 | Discount percentage |
| `discount_amount` | DECIMAL(12,2) | DEFAULT 0, CHECK >= 0 | Discount in currency |
| `subtotal` | DECIMAL(12,2) | NOT NULL, CHECK >= 0 | Line total (qty × price - discount) |

**Relationships**:
- `BELONGS TO` → Sale
- `BELONGS TO` → Product

**Validation Rules**:
- `quantity`: > 0
- `subtotal`: must equal `(unit_price * quantity) - discount_amount`
- `product_name`: snapshot of product name at sale time (for historical accuracy)

**Indexes**:
```sql
CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX idx_sale_items_product ON sale_items(product_id);
```

---

### 9. Customer

**Description**: Customer profile with purchase history and loyalty tracking.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique customer identifier |
| `tenant_id` | UUID | FK → Tenant, NOT NULL | Tenant ownership (shared across branches) |
| `phone` | VARCHAR(20) | UNIQUE, NOT NULL | Primary identifier (E.164) |
| `email` | VARCHAR(255) | | Email address |
| `full_name` | VARCHAR(255) | NOT NULL | Customer name |
| `whatsapp_number` | VARCHAR(20) | | WhatsApp contact (E.164) |
| `loyalty_points` | INTEGER | NOT NULL, DEFAULT 0, CHECK >= 0 | Accumulated points |
| `total_purchases` | DECIMAL(12,2) | DEFAULT 0, CHECK >= 0 | Lifetime spend |
| `purchase_count` | INTEGER | DEFAULT 0, CHECK >= 0 | Number of purchases |
| `last_purchase_at` | TIMESTAMPTZ | | Last purchase timestamp |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Registration date |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last modification |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

**Delivery Addresses** (separate table):
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique address identifier |
| `customer_id` | UUID | FK → Customer, NOT NULL | Customer reference |
| `label` | VARCHAR(50) | | Address label (Home, Office) |
| `address_line` | TEXT | NOT NULL | Full address |
| `latitude` | DECIMAL(10,8) | | GPS latitude |
| `longitude` | DECIMAL(11,8) | | GPS longitude |
| `is_default` | BOOLEAN | DEFAULT FALSE | Default delivery address |

**Relationships**:
- `BELONGS TO` → Tenant (shared across all tenant branches)
- `HAS MANY` → Sale (purchase history)
- `HAS MANY` → Order (marketplace orders)
- `HAS MANY` → CustomerAddress (delivery addresses)
- `HAS MANY` → ChatConversation (AI chat sessions)

**Validation Rules**:
- `phone`: required, E.164 format, unique within tenant
- `email`: valid email format if provided
- `loyalty_points`: >= 0 (cannot go negative)
- `total_purchases`: >= 0
- Loyalty rate: 1 point per ₦100 spent (from clarifications)

**Indexes**:
```sql
CREATE UNIQUE INDEX idx_customers_tenant_phone ON customers(tenant_id, phone) WHERE deleted_at IS NULL;
CREATE INDEX idx_customers_email ON customers(email) WHERE email IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_customers_loyalty ON customers(tenant_id, loyalty_points DESC);
```

**Trigger**: Update `loyalty_points`, `total_purchases`, `purchase_count`, `last_purchase_at` on Sale INSERT

---

### 10. Order

**Description**: Customer order from marketplace or synced from e-commerce platform.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique order identifier |
| `tenant_id` | UUID | FK → Tenant, NOT NULL | Tenant ownership |
| `branch_id` | UUID | FK → Branch, NOT NULL | Fulfillment branch |
| `order_number` | VARCHAR(50) | UNIQUE, NOT NULL | Human-readable order reference |
| `customer_id` | UUID | FK → Customer, NOT NULL | Ordering customer |
| `order_type` | ENUM | NOT NULL | Type: marketplace, ecommerce_sync, ai_chat |
| `order_status` | ENUM | NOT NULL, DEFAULT 'pending' | Status: pending, confirmed, preparing, ready, completed, cancelled |
| `payment_status` | ENUM | NOT NULL, DEFAULT 'unpaid' | Status: unpaid, paid, refunded |
| `payment_method` | ENUM | | Method: cash, card, bank_transfer, mobile_money |
| `payment_reference` | VARCHAR(255) | | Payment gateway reference |
| `subtotal` | DECIMAL(12,2) | NOT NULL, CHECK >= 0 | Sum of items |
| `delivery_fee` | DECIMAL(12,2) | DEFAULT 0, CHECK >= 0 | Delivery charge |
| `tax_amount` | DECIMAL(12,2) | DEFAULT 0, CHECK >= 0 | Tax charged |
| `total_amount` | DECIMAL(12,2) | NOT NULL, CHECK >= 0 | Final amount |
| `fulfillment_type` | ENUM | NOT NULL | Type: pickup, delivery |
| `delivery_address_id` | UUID | FK → CustomerAddress | Delivery destination |
| `special_instructions` | TEXT | | Customer notes |
| `ecommerce_platform` | VARCHAR(50) | | Source platform (WooCommerce, Shopify) |
| `ecommerce_order_id` | VARCHAR(255) | | External order ID |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Order placement |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last modification |

**Order Items** (separate table):
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Line item identifier |
| `order_id` | UUID | FK → Order, NOT NULL | Parent order |
| `product_id` | UUID | FK → Product, NOT NULL | Ordered product |
| `product_name` | VARCHAR(255) | NOT NULL | Product name snapshot |
| `quantity` | INTEGER | NOT NULL, CHECK > 0 | Quantity ordered |
| `unit_price` | DECIMAL(12,2) | NOT NULL, CHECK > 0 | Price per unit |
| `subtotal` | DECIMAL(12,2) | NOT NULL, CHECK >= 0 | Line total |

**Relationships**:
- `BELONGS TO` → Tenant
- `BELONGS TO` → Branch (fulfillment branch)
- `BELONGS TO` → Customer
- `BELONGS TO` → CustomerAddress (if delivery)
- `HAS MANY` → OrderItem (line items)
- `HAS ONE` → Delivery (if fulfillment_type = delivery)

**Validation Rules**:
- `total_amount`: must equal `subtotal + delivery_fee + tax_amount`
- `delivery_address_id`: required if `fulfillment_type = delivery`
- `payment_reference`: required if `payment_status = paid`

**State Transitions**:
```
pending → confirmed → preparing → ready → completed
pending → cancelled
confirmed → cancelled
```

**Indexes**:
```sql
CREATE INDEX idx_orders_tenant_branch ON orders(tenant_id, branch_id, created_at DESC);
CREATE INDEX idx_orders_customer ON orders(customer_id, created_at DESC);
CREATE INDEX idx_orders_status ON orders(order_status, created_at DESC);
CREATE UNIQUE INDEX idx_orders_number ON orders(tenant_id, order_number);
CREATE INDEX idx_orders_ecommerce ON orders(ecommerce_platform, ecommerce_order_id) WHERE ecommerce_platform IS NOT NULL;
```

---

### 11. Delivery

**Description**: Delivery task for order fulfillment via local rider or inter-city service.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique delivery identifier |
| `tenant_id` | UUID | FK → Tenant, NOT NULL | Tenant ownership |
| `branch_id` | UUID | FK → Branch, NOT NULL | Originating branch |
| `order_id` | UUID | FK → Order, NOT NULL, UNIQUE | Associated order |
| `tracking_number` | VARCHAR(50) | UNIQUE, NOT NULL | Public tracking reference |
| `delivery_type` | ENUM | NOT NULL | Type: local_bike, local_bicycle, intercity |
| `rider_id` | UUID | FK → Rider | Assigned local rider (null for intercity) |
| `delivery_status` | ENUM | NOT NULL, DEFAULT 'pending' | Status: pending, assigned, picked_up, in_transit, delivered, failed, cancelled |
| `customer_address` | TEXT | NOT NULL | Delivery destination |
| `customer_phone` | VARCHAR(20) | NOT NULL | Contact number |
| `customer_latitude` | DECIMAL(10,8) | | GPS latitude |
| `customer_longitude` | DECIMAL(11,8) | | GPS longitude |
| `distance_km` | DECIMAL(8,2) | | Delivery distance |
| `estimated_delivery_time` | TIMESTAMPTZ | | ETA |
| `actual_delivery_time` | TIMESTAMPTZ | | Actual delivery timestamp |
| `proof_type` | ENUM | | Proof: photo, signature, recipient_name |
| `proof_data` | TEXT | | Proof content (URL or text) |
| `failure_reason` | TEXT | | Reason for failed delivery |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Delivery creation |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last modification |

**Relationships**:
- `BELONGS TO` → Tenant
- `BELONGS TO` → Branch
- `BELONGS TO` → Order (one-to-one)
- `BELONGS TO` → Rider (if local delivery)

**Validation Rules**:
- `delivery_type`: local_bike/local_bicycle if distance <= 25km, intercity if > 25km (from clarifications)
- `rider_id`: required if delivery_type in (local_bike, local_bicycle)
- `proof_type` and `proof_data`: required when delivery_status = delivered
- `actual_delivery_time`: required when delivery_status = delivered

**State Transitions**:
```
pending → assigned → picked_up → in_transit → delivered
pending → cancelled
assigned → failed
in_transit → failed
```

**Indexes**:
```sql
CREATE UNIQUE INDEX idx_deliveries_tracking ON deliveries(tracking_number);
CREATE INDEX idx_deliveries_tenant_branch ON deliveries(tenant_id, branch_id, delivery_status);
CREATE INDEX idx_deliveries_rider ON deliveries(rider_id, delivery_status) WHERE rider_id IS NOT NULL;
CREATE INDEX idx_deliveries_status ON deliveries(delivery_status, created_at DESC);
```

**Public Tracking**:
- `tracking_number` accessible via public API without authentication
- Track status updates, ETA, and rider contact (if local)

---

### 12. Rider

**Description**: Delivery personnel (bike/bicycle rider) for local deliveries.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique rider identifier |
| `tenant_id` | UUID | FK → Tenant, NOT NULL | Tenant ownership |
| `user_id` | UUID | FK → User, UNIQUE, NOT NULL | Associated user account |
| `vehicle_type` | ENUM | NOT NULL | Type: bike, bicycle |
| `license_number` | VARCHAR(50) | | Vehicle license/registration |
| `phone` | VARCHAR(20) | NOT NULL | Contact number |
| `is_available` | BOOLEAN | DEFAULT TRUE | Available for assignments |
| `total_deliveries` | INTEGER | DEFAULT 0, CHECK >= 0 | Completed deliveries |
| `successful_deliveries` | INTEGER | DEFAULT 0, CHECK >= 0 | Successfully delivered |
| `average_delivery_time_minutes` | DECIMAL(8,2) | | Avg time per delivery |
| `rating` | DECIMAL(3,2) | CHECK >= 0 AND <= 5 | Customer rating (0-5) |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Rider registration |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last modification |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

**Relationships**:
- `BELONGS TO` → Tenant
- `BELONGS TO` → User (rider account)
- `HAS MANY` → Delivery (assigned deliveries)

**Validation Rules**:
- `vehicle_type`: must be bike or bicycle
- `successful_deliveries`: <= `total_deliveries`
- `rating`: 0-5 scale

**Computed Fields**:
- `success_rate`: `successful_deliveries / total_deliveries * 100`

**Indexes**:
```sql
CREATE INDEX idx_riders_tenant ON riders(tenant_id, deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_riders_availability ON riders(is_available) WHERE is_available = TRUE AND deleted_at IS NULL;
```

**Trigger**: Update `total_deliveries`, `successful_deliveries`, `average_delivery_time_minutes` on Delivery status change

---

### 13. StaffAttendance

**Description**: Time tracking record for staff clock in/out.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique attendance identifier |
| `tenant_id` | UUID | FK → Tenant, NOT NULL | Tenant ownership |
| `branch_id` | UUID | FK → Branch, NOT NULL | Branch location |
| `staff_id` | UUID | FK → User, NOT NULL | Staff member |
| `clock_in_at` | TIMESTAMPTZ | NOT NULL | Clock in timestamp |
| `clock_out_at` | TIMESTAMPTZ | | Clock out timestamp (null if still clocked in) |
| `total_hours` | DECIMAL(8,2) | | Total hours worked |
| `shift_date` | DATE | NOT NULL | Shift date (for grouping) |
| `notes` | TEXT | | Attendance notes |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record creation |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last modification |

**Relationships**:
- `BELONGS TO` → Tenant
- `BELONGS TO` → Branch
- `BELONGS TO` → User (staff member)

**Validation Rules**:
- `clock_out_at`: must be > `clock_in_at` if provided
- `total_hours`: calculated as `(clock_out_at - clock_in_at) / 3600` when clock_out_at is set
- `shift_date`: extracted from `clock_in_at` (date part)
- Staff can only have one open (clock_out_at IS NULL) attendance record at a time

**Indexes**:
```sql
CREATE INDEX idx_attendance_staff ON staff_attendance(staff_id, shift_date DESC);
CREATE INDEX idx_attendance_branch ON staff_attendance(branch_id, shift_date DESC);
CREATE INDEX idx_attendance_open ON staff_attendance(staff_id) WHERE clock_out_at IS NULL;
```

**Alert Logic**:
- If `clock_out_at IS NULL` and `clock_in_at < NOW() - INTERVAL '12 hours'`, alert admin (from clarifications)

---

### 14. ECommerceConnection

**Description**: Integration configuration with third-party e-commerce platforms.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique connection identifier |
| `tenant_id` | UUID | FK → Tenant, NOT NULL | Tenant ownership |
| `platform_type` | ENUM | NOT NULL | Platform: woocommerce, shopify, custom |
| `platform_name` | VARCHAR(100) | | Store name |
| `store_url` | TEXT | NOT NULL | E-commerce store URL |
| `api_key` | TEXT | NOT NULL | API credentials (encrypted) |
| `api_secret` | TEXT | | API secret (encrypted) |
| `sync_enabled` | BOOLEAN | DEFAULT TRUE | Auto-sync enabled |
| `sync_interval_minutes` | INTEGER | DEFAULT 15, CHECK > 0 | Sync frequency |
| `last_sync_at` | TIMESTAMPTZ | | Last successful sync |
| `sync_status` | ENUM | DEFAULT 'pending' | Status: pending, syncing, success, error |
| `sync_error` | TEXT | | Last sync error message |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Connection creation |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last modification |

**Relationships**:
- `BELONGS TO` → Tenant

**Validation Rules**:
- `store_url`: valid HTTPS URL
- `api_key`: required, encrypted at rest
- Credentials validated on creation via test API call

**Indexes**:
```sql
CREATE INDEX idx_ecommerce_tenant ON ecommerce_connections(tenant_id);
CREATE INDEX idx_ecommerce_sync ON ecommerce_connections(sync_enabled, last_sync_at) WHERE sync_enabled = TRUE;
```

**Security**:
- Encrypt `api_key` and `api_secret` using Supabase Vault or application-level encryption

---

### 15. ChatConversation

**Description**: AI chat session with customer for remote purchases.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique conversation identifier |
| `tenant_id` | UUID | FK → Tenant, NOT NULL | Tenant ownership |
| `branch_id` | UUID | FK → Branch, NOT NULL | Serving branch |
| `customer_id` | UUID | FK → Customer, NOT NULL | Customer participant |
| `order_id` | UUID | FK → Order | Order created from chat |
| `status` | ENUM | DEFAULT 'active' | Status: active, completed, escalated, abandoned |
| `escalated_to_user_id` | UUID | FK → User | Staff member (if escalated) |
| `started_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Chat start time |
| `ended_at` | TIMESTAMPTZ | | Chat end time |

**Chat Messages** (separate table):
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Message identifier |
| `conversation_id` | UUID | FK → ChatConversation, NOT NULL | Parent conversation |
| `sender_type` | ENUM | NOT NULL | Sender: customer, ai_agent, staff |
| `sender_id` | UUID | | User ID (if sender_type = staff) |
| `message_text` | TEXT | NOT NULL | Message content |
| `intent` | VARCHAR(100) | | Detected intent (browse, check_stock, create_order) |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Message timestamp |

**Relationships**:
- `BELONGS TO` → Tenant
- `BELONGS TO` → Branch
- `BELONGS TO` → Customer
- `BELONGS TO` → Order (if created)
- `BELONGS TO` → User (if escalated)
- `HAS MANY` → ChatMessage

**Validation Rules**:
- `escalated_to_user_id`: required if status = escalated
- `order_id`: set when AI successfully creates order

**Indexes**:
```sql
CREATE INDEX idx_chat_tenant_branch ON chat_conversations(tenant_id, branch_id, started_at DESC);
CREATE INDEX idx_chat_customer ON chat_conversations(customer_id, started_at DESC);
CREATE INDEX idx_chat_status ON chat_conversations(status) WHERE status = 'active';
```

---

### 16. Subscription

**Description**: Tenant subscription plan with feature limits and commission rates.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique subscription identifier |
| `tenant_id` | UUID | FK → Tenant, UNIQUE, NOT NULL | Tenant with subscription |
| `plan_tier` | ENUM | NOT NULL | Tier: free, basic, pro, enterprise |
| `monthly_fee` | DECIMAL(12,2) | NOT NULL, CHECK >= 0 | Subscription cost (₦) |
| `commission_rate` | DECIMAL(5,2) | NOT NULL, CHECK >= 0 AND <= 100 | Marketplace commission (%) |
| `max_branches` | INTEGER | NOT NULL, CHECK > 0 | Branch limit |
| `max_staff_users` | INTEGER | NOT NULL, CHECK > 0 | Staff user limit |
| `max_products` | INTEGER | NOT NULL, CHECK > 0 | Product limit |
| `monthly_transaction_quota` | INTEGER | NOT NULL, CHECK > 0 | Transaction limit per month |
| `features` | JSONB | DEFAULT '{}' | Feature flags (e.g., {"ai_chat": true, "analytics": true}) |
| `billing_cycle_start` | TIMESTAMPTZ | NOT NULL | Current cycle start |
| `billing_cycle_end` | TIMESTAMPTZ | NOT NULL | Current cycle end |
| `status` | ENUM | DEFAULT 'active' | Status: active, suspended, cancelled |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Subscription start |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last modification |

**Plan Tiers** (Example):
| Tier | Monthly Fee | Commission | Branches | Staff | Products | Transactions |
|------|-------------|------------|----------|-------|----------|--------------|
| `free` | ₦0 | 5% | 1 | 3 | 100 | 500 |
| `basic` | ₦5,000 | 2.5% | 3 | 10 | 1,000 | 2,000 |
| `pro` | ₦15,000 | 1.5% | 10 | 50 | 10,000 | 10,000 |
| `enterprise` | Custom | 1% | Unlimited | Unlimited | Unlimited | Unlimited |

**Relationships**:
- `BELONGS TO` → Tenant (one-to-one)

**Validation Rules**:
- `billing_cycle_end`: must be > `billing_cycle_start`
- `monthly_fee`: >= 0 (free tier is 0)
- `commission_rate`: 0-100 (percentage)

**Indexes**:
```sql
CREATE UNIQUE INDEX idx_subscriptions_tenant ON subscriptions(tenant_id);
CREATE INDEX idx_subscriptions_billing ON subscriptions(billing_cycle_end) WHERE status = 'active';
```

**Enforcement**:
- Check limits before allowing tenant to create branches, users, products
- Block new transactions if monthly quota exceeded (with upgrade prompt)

---

### 17. Commission

**Description**: Platform commission record for marketplace sales.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique commission identifier |
| `tenant_id` | UUID | FK → Tenant, NOT NULL | Tenant owing commission |
| `order_id` | UUID | FK → Order, NOT NULL, UNIQUE | Order that generated commission |
| `sale_amount` | DECIMAL(12,2) | NOT NULL, CHECK > 0 | Order total |
| `commission_rate` | DECIMAL(5,2) | NOT NULL, CHECK >= 0 AND <= 100 | Rate applied (%) |
| `commission_amount` | DECIMAL(12,2) | NOT NULL, CHECK >= 0 | Commission earned |
| `settlement_status` | ENUM | DEFAULT 'pending' | Status: pending, invoiced, paid |
| `settlement_date` | DATE | | Date settled |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Commission creation |

**Relationships**:
- `BELONGS TO` → Tenant
- `BELONGS TO` → Order (one-to-one)

**Validation Rules**:
- `commission_amount`: must equal `sale_amount * (commission_rate / 100)`
- `commission_rate`: should match tenant's subscription plan rate

**Indexes**:
```sql
CREATE INDEX idx_commissions_tenant ON commissions(tenant_id, settlement_status);
CREATE INDEX idx_commissions_settlement ON commissions(settlement_status, created_at DESC);
```

**Trigger**: Create Commission record on Order completion (order_status = completed AND order_type = marketplace)

---

### 18. WhatsAppMessage

**Description**: WhatsApp communication record with customers.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique message identifier |
| `tenant_id` | UUID | FK → Tenant, NOT NULL | Tenant ownership |
| `customer_id` | UUID | FK → Customer, NOT NULL | Customer recipient/sender |
| `order_id` | UUID | FK → Order | Related order (if applicable) |
| `direction` | ENUM | NOT NULL | Direction: outbound, inbound |
| `message_type` | ENUM | NOT NULL | Type: text, template, media |
| `message_content` | TEXT | NOT NULL | Message body |
| `template_name` | VARCHAR(100) | | WhatsApp template used |
| `media_url` | TEXT | | Media attachment URL |
| `whatsapp_message_id` | VARCHAR(255) | UNIQUE | WhatsApp API message ID |
| `delivery_status` | ENUM | DEFAULT 'pending' | Status: pending, sent, delivered, read, failed |
| `error_message` | TEXT | | Failure reason |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Message timestamp |

**Relationships**:
- `BELONGS TO` → Tenant
- `BELONGS TO` → Customer
- `BELONGS TO` → Order (if applicable)

**Validation Rules**:
- `template_name`: required if `message_type = template`
- `media_url`: required if `message_type = media`

**Indexes**:
```sql
CREATE INDEX idx_whatsapp_tenant_customer ON whatsapp_messages(tenant_id, customer_id, created_at DESC);
CREATE INDEX idx_whatsapp_order ON whatsapp_messages(order_id) WHERE order_id IS NOT NULL;
CREATE INDEX idx_whatsapp_delivery ON whatsapp_messages(delivery_status, created_at DESC);
```

---

### 19. Receipt

**Description**: Transaction receipt for sales.

**Attributes**:
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique receipt identifier |
| `sale_id` | UUID | FK → Sale, UNIQUE, NOT NULL | Associated sale |
| `receipt_number` | VARCHAR(50) | UNIQUE, NOT NULL | Human-readable receipt number |
| `format` | ENUM | DEFAULT 'pdf' | Format: pdf, thermal_print, email |
| `content` | TEXT | | Receipt content (HTML or plain text) |
| `file_url` | TEXT | | Stored receipt file (Supabase Storage) |
| `email_sent_to` | VARCHAR(255) | | Email recipient |
| `email_sent_at` | TIMESTAMPTZ | | Email send timestamp |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Receipt generation time |

**Relationships**:
- `BELONGS TO` → Sale (one-to-one)

**Indexes**:
```sql
CREATE UNIQUE INDEX idx_receipts_sale ON receipts(sale_id);
CREATE UNIQUE INDEX idx_receipts_number ON receipts(receipt_number);
```

---

## Relationships Summary

```
Tenant (1) ----< (M) Branch
Tenant (1) ----< (M) User
Tenant (1) ----< (M) Product
Tenant (1) ----< (M) Customer
Tenant (1) ---- (1) Subscription

Branch (1) ----< (M) Product
Branch (1) ----< (M) Sale
Branch (1) ----< (M) User
Branch (1) ----< (M) Order

User (1) ----< (M) Sale (as cashier)
User (1) ----< (M) StaffAttendance
User (1) ---- (1) Rider (optional)

Product (1) ----< (M) SaleItem
Product (1) ----< (M) InventoryTransaction

Sale (1) ----< (M) SaleItem
Sale (1) ---- (1) Receipt

Customer (1) ----< (M) Order
Customer (1) ----< (M) Sale
Customer (1) ----< (M) CustomerAddress
Customer (1) ----< (M) ChatConversation

Order (1) ----< (M) OrderItem
Order (1) ---- (1) Delivery
Order (1) ---- (1) Commission

Delivery (M) ----< (1) Rider

InterBranchTransfer (1) ----< (M) TransferItem
```

---

## Offline Sync Strategy

**Sync Metadata** (added to all synced tables):
| Field | Type | Description |
|-------|------|-------------|
| `_sync_version` | BIGINT | Version number for conflict resolution |
| `_sync_modified_at` | TIMESTAMPTZ | Last modification timestamp |
| `_sync_client_id` | UUID | Device that made last change |
| `_sync_is_deleted` | BOOLEAN | Soft delete flag for sync |

**Sync Rules**:
1. **Branch-scoped sync**: Clients sync only their assigned branch data (+ tenant-wide data like customers)
2. **CRDT conflict resolution**: Use PowerSync CRDT for inventory operations (FR-002)
3. **Bidirectional sync**: Changes flow client ↔ Supabase in both directions
4. **Background sync**: Queue changes when offline, auto-sync on reconnection
5. **Selective sync**: Large tables (e.g., historical sales) use pagination/lazy loading

**Synced Tables**:
- ✅ Product (branch-specific)
- ✅ Sale, SaleItem (branch-specific)
- ✅ Customer (tenant-wide, shared across branches)
- ✅ Order, OrderItem (branch-specific)
- ✅ Delivery (branch-specific)
- ✅ InventoryTransaction (branch-specific)
- ❌ Subscription (cloud-only, admin-managed)
- ❌ Commission (cloud-only, platform-managed)

---

## Security Considerations

**Row Level Security (RLS) Policies**:
```sql
-- Example: Products table
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Tenant isolation
CREATE POLICY "Tenant isolation" ON products
  FOR ALL USING (tenant_id = current_tenant_id());

-- Branch-level access control
CREATE POLICY "Branch access control" ON products
  FOR SELECT USING (
    current_user_role() = 'tenant_admin' OR
    branch_id = current_user_branch_id()
  );

-- Write restrictions (only managers can modify)
CREATE POLICY "Manager write access" ON products
  FOR INSERT WITH CHECK (
    current_user_role() IN ('tenant_admin', 'branch_manager')
  );
```

**Encryption**:
- API credentials in `ECommerceConnection`: encrypt using Supabase Vault
- Payment references: do NOT store full card numbers (PCI compliance)
- Customer data: encrypt PII at rest (email, phone, address)

**Audit Trail**:
- All sensitive operations logged with timestamp, user, action
- Immutable audit logs (append-only table)

---

## Performance Optimization

**Composite Indexes**:
```sql
-- Common query: Get branch products with low stock
CREATE INDEX idx_products_branch_low_stock
  ON products(branch_id, stock_quantity)
  WHERE stock_quantity <= low_stock_threshold AND deleted_at IS NULL;

-- Common query: Sales by branch and date range
CREATE INDEX idx_sales_branch_date
  ON sales(branch_id, created_at DESC)
  WHERE status = 'completed';

-- Common query: Active deliveries per rider
CREATE INDEX idx_deliveries_rider_active
  ON deliveries(rider_id, delivery_status)
  WHERE delivery_status NOT IN ('delivered', 'cancelled', 'failed');
```

**Materialized Views** (for analytics):
```sql
-- Daily sales summary per branch
CREATE MATERIALIZED VIEW daily_sales_summary AS
  SELECT
    branch_id,
    DATE(created_at) as sale_date,
    COUNT(*) as transaction_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value
  FROM sales
  WHERE status = 'completed'
  GROUP BY branch_id, DATE(created_at);

-- Refresh strategy: REFRESH MATERIALIZED VIEW CONCURRENTLY daily_sales_summary;
```

---

## Data Migration & Seeding

**Initial Seed Data**:
1. Subscription plans (free, basic, pro, enterprise)
2. System user (platform admin)
3. Example tenant (for demo/testing)

**CSV Import Schema** (for bulk product import, FR-005):
```csv
name,sku,barcode,category,unit_price,stock_quantity,expiry_date
Paracetamol 500mg,PAR-500,5012345678901,Medication,500.00,100,2025-12-31
Coca-Cola 50cl,COKE-50,5449000131805,Beverage,200.00,50,
```

---

## Status: ✅ Phase 1 Data Model Complete

**Next Steps**:
- Generate API contracts (OpenAPI schema) in `/contracts/` directory
- Generate quickstart.md with development setup guide
- Update agent context with data model decisions
