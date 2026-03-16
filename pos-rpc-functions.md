# POS System - RPC Functions & Helper Functions Guide

**Complete SQL Functions for Supabase Backend**
**Integration Guide for FlutterFlow**
**Last Updated:** March 10, 2026

---

## Table of Contents

1. [Overview](#overview)
2. [⚡ NEW: Automatic Database Triggers](#-new-automatic-database-triggers)
3. [Setup Instructions](#setup-instructions)
4. [Dashboard Functions](#dashboard-functions)
5. [POS Sale Functions](#pos-sale-functions)
6. [Product & Inventory Functions](#product--inventory-functions)
7. [Sales History Functions](#sales-history-functions)
8. [Customer Functions](#customer-functions)
9. [Reports Functions](#reports-functions)
10. [Staff & Branch Functions](#staff--branch-functions)
11. [Utility Functions](#utility-functions)
12. [FlutterFlow Integration Examples](#flutterflow-integration-examples)

---

## Overview

This document contains all RPC (Remote Procedure Call) functions and helper functions needed for the POS system. Each function includes:

- **Purpose**: What the function does
- **SQL Definition**: Complete function code to run in Supabase SQL Editor
- **Parameters**: Input parameters with types
- **Returns**: Return type and structure
- **Usage**: How to call from FlutterFlow
- **Example**: Sample implementation

---

## ⚡ NEW: Automatic Database Triggers

### Important Change (March 10, 2026)

The database now has **automatic triggers** for real-time inventory synchronization. This significantly simplifies your FlutterFlow code!

### What's Changed:

**BEFORE (Old Way - Don't Do This):**
```dart
// ❌ OLD: Manual inventory updates after sale
await Supabase.instance.client.from('sales').insert(sale Data);
await Supabase.instance.client.from('sale_items').insert(items);

// Manual update (NO LONGER NEEDED!)
await Supabase.instance.client
  .from('branch_inventory')
  .update({'stock_quantity': newQuantity});

await Supabase.instance.client
  .from('products')
  .update({'stock_quantity': totalStock});
```

**NOW (New Way - Automatic):**
```dart
// ✅ NEW: Just insert the sale - triggers handle the rest!
await Supabase.instance.client.from('sales').insert({
  'status': 'completed',  // This triggers automatic inventory update
  'total_amount': totalAmount,
  'branch_id': branchId,
  // ... other fields
});

await Supabase.instance.client.from('sale_items').insert(saleItems);

// That's it! Triggers automatically:
// 1. Deduct from branch_inventory
// 2. Update products.stock_quantity
// 3. Sync to marketplace
```

### Active Triggers:

| Trigger Name | Table | Event | Purpose |
|--------------|-------|-------|---------|
| `auto_sync_inventory_on_sale` | `sales` | INSERT/UPDATE (status='completed') | Deducts inventory when sale completes |
| `auto_sync_product_stock` | `branch_inventory` | INSERT/UPDATE/DELETE | Recalculates total product stock |
| `auto_reserve_inventory_on_order` | `orders` | INSERT | Reserves inventory for marketplace orders |
| `auto_order_inventory_sync` | `orders` | UPDATE (status) | Manages inventory on order status changes |

### New Database Views:

Use these views instead of direct table queries for real-time data:

```dart
// Get products with real-time stock (total across all branches)
final products = await Supabase.instance.client
  .from('marketplace_products_with_stock')
  .select()
  .eq('tenant_id', tenantId);

// Get detailed stock status per branch (includes reserved quantities)
final stockStatus = await Supabase.instance.client
  .from('product_stock_status')
  .select()
  .eq('branch_id', branchId);
```

### New Helper Functions (Optional):

These are available but usually **not needed** (triggers handle most cases):

```dart
// Check product availability (useful before large orders)
final check = await Supabase.instance.client.rpc(
  'check_product_availability',
  {
    'p_product_id': productId,
    'p_quantity': 10,
    'p_tenant_id': tenantId
  }
);
// Returns: {is_available: true, available_stock: 85, message: "..."}

// Get real-time stock for a product
final stock = await Supabase.instance.client.rpc(
  'get_marketplace_stock',
  {
    'p_product_id': productId,
    'p_tenant_id': tenantId
  }
);
// Returns: {total_stock: 100, reserved_stock: 15, available_stock: 85}
```

### Impact on Your Code:

**Pages Affected:**
- ✅ **POS Sale Screen (Page 8)** - Remove manual inventory updates
- ✅ **Adjust Stock (Page 13)** - Just update `branch_inventory`, triggers sync to `products`
- ✅ **All Product Queries** - Use `marketplace_products_with_stock` view

**What to Remove:**
- ❌ Manual updates to `products.stock_quantity`
- ❌ Custom sync code between `branch_inventory` and `products`
- ❌ Manual marketplace stock calculations

**What to Add:**
- ✅ Query `marketplace_products_with_stock` view for display
- ✅ Query `product_stock_status` view for detailed branch stock
- ✅ Trust the triggers to handle inventory sync

**📖 Complete Documentation**: See [AUTOMATIC_DATABASE_TRIGGERS.md](./AUTOMATIC_DATABASE_TRIGGERS.md)

---

## Setup Instructions

### Step 1: Run All SQL Definitions

Copy and paste all SQL function definitions into the Supabase SQL Editor and execute them.

### Step 2: Configure in FlutterFlow

1. Go to **Backend Query** → **Supabase**
2. Add **RPC Call** for each function
3. Map parameters to app state or page parameters
4. Configure response parsing

### Step 3: Test Functions

Use Supabase SQL Editor to test functions with sample parameters.

---

## Dashboard Functions

### 1. get_daily_sales_summary

**Purpose**: Get today's sales summary for dashboard.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_daily_sales_summary(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_date DATE
)
RETURNS TABLE (
    total_amount DECIMAL,
    transaction_count BIGINT,
    avg_transaction DECIMAL,
    cash_sales DECIMAL,
    card_sales DECIMAL,
    transfer_sales DECIMAL,
    items_sold BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(s.total_amount), 0) as total_amount,
        COUNT(s.id) as transaction_count,
        COALESCE(AVG(s.total_amount), 0) as avg_transaction,
        COALESCE(SUM(CASE WHEN s.payment_method = 'cash' THEN s.total_amount ELSE 0 END), 0) as cash_sales,
        COALESCE(SUM(CASE WHEN s.payment_method = 'card' THEN s.total_amount ELSE 0 END), 0) as card_sales,
        COALESCE(SUM(CASE WHEN s.payment_method = 'bank_transfer' THEN s.total_amount ELSE 0 END), 0) as transfer_sales,
        COALESCE(SUM(si.quantity), 0)::BIGINT as items_sold
    FROM sales s
    LEFT JOIN sale_items si ON si.sale_id = s.id
    WHERE s.tenant_id = p_tenant_id
        AND s.branch_id = p_branch_id
        AND DATE(s.created_at) = p_date
        AND s.status = 'completed';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Parameters**:
- `p_tenant_id` (UUID): Tenant ID
- `p_branch_id` (UUID): Branch ID
- `p_date` (DATE): Date to query (format: 'YYYY-MM-DD')

**Returns**:
```json
{
  "total_amount": 45000.00,
  "transaction_count": 23,
  "avg_transaction": 1956.52,
  "cash_sales": 25000.00,
  "card_sales": 15000.00,
  "transfer_sales": 5000.00,
  "items_sold": 87
}
```

**FlutterFlow Usage**:
```dart
// Backend Query → Supabase RPC → get_daily_sales_summary
// Parameters:
Map<String, dynamic> params = {
  'p_tenant_id': FFAppState().tenantId,
  'p_branch_id': FFAppState().branchId,
  'p_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
};
```

---

### 2. get_recent_sales

**Purpose**: Get recent sales for dashboard quick view.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_recent_sales(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
    sale_id UUID,
    sale_number VARCHAR,
    total_amount DECIMAL,
    payment_method payment_method,
    customer_name TEXT,
    created_at TIMESTAMPTZ,
    items_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id as sale_id,
        s.sale_number,
        s.total_amount,
        s.payment_method,
        c.full_name as customer_name,
        s.created_at,
        COUNT(si.id) as items_count
    FROM sales s
    LEFT JOIN customers c ON c.id = s.customer_id
    LEFT JOIN sale_items si ON si.sale_id = s.id
    WHERE s.tenant_id = p_tenant_id
        AND s.branch_id = p_branch_id
        AND s.status = 'completed'
    GROUP BY s.id, s.sale_number, s.total_amount, s.payment_method, c.full_name, s.created_at
    ORDER BY s.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Parameters**:
- `p_tenant_id` (UUID): Tenant ID
- `p_branch_id` (UUID): Branch ID
- `p_limit` (INTEGER): Number of sales to return (default 5)

**Returns**: Array of recent sales

---

### 3. get_low_stock_count

**Purpose**: Get count of low stock items for alert badge.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_low_stock_count(
    p_tenant_id UUID,
    p_branch_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*)::INTEGER INTO v_count
    FROM product_stock_status
    WHERE tenant_id = p_tenant_id
        AND branch_id = p_branch_id
        AND stock_status IN ('low_stock', 'out_of_stock');

    RETURN COALESCE(v_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Parameters**:
- `p_tenant_id` (UUID): Tenant ID
- `p_branch_id` (UUID): Branch ID

**Returns**: Integer count

---

## POS Sale Functions

### 4. search_products_for_pos

**Purpose**: Search products with stock availability for POS.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION search_products_for_pos(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_search_term TEXT,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    product_id UUID,
    product_name VARCHAR,
    sku VARCHAR,
    barcode VARCHAR,
    category VARCHAR,
    unit_price DECIMAL,
    cost_price DECIMAL,
    image_url TEXT,
    stock_quantity INTEGER,
    reserved_quantity INTEGER,
    available_quantity INTEGER,
    low_stock_threshold INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id as product_id,
        p.name as product_name,
        p.sku,
        p.barcode,
        p.category,
        p.unit_price,
        p.cost_price,
        p.image_url,
        bi.stock_quantity,
        bi.reserved_quantity,
        (bi.stock_quantity - bi.reserved_quantity) as available_quantity,
        bi.low_stock_threshold
    FROM products p
    INNER JOIN branch_inventory bi ON bi.product_id = p.id
    WHERE p.tenant_id = p_tenant_id
        AND bi.branch_id = p_branch_id
        AND p.is_active = TRUE
        AND bi.is_active = TRUE
        AND p._sync_is_deleted = FALSE
        AND (bi.stock_quantity - bi.reserved_quantity) > 0
        AND (
            p.name ILIKE '%' || p_search_term || '%'
            OR p.sku ILIKE '%' || p_search_term || '%'
            OR p.barcode = p_search_term
        )
    ORDER BY p.name
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Parameters**:
- `p_tenant_id` (UUID): Tenant ID
- `p_branch_id` (UUID): Branch ID
- `p_search_term` (TEXT): Search query (name/SKU/barcode)
- `p_limit` (INTEGER): Max results (default 20)

**Returns**: Array of products with stock info

---

### 5. complete_sale_transaction

**Purpose**: Complete a sale transaction (atomic operation).

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION complete_sale_transaction(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_cashier_id UUID,
    p_customer_id UUID,
    p_cart_items JSONB,
    p_subtotal DECIMAL,
    p_tax_amount DECIMAL,
    p_discount_amount DECIMAL,
    p_total_amount DECIMAL,
    p_payment_method payment_method,
    p_payment_reference TEXT DEFAULT NULL
)
RETURNS TABLE (
    sale_id UUID,
    sale_number VARCHAR,
    success BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    v_sale_id UUID;
    v_sale_number VARCHAR;
    v_item JSONB;
    v_product_id UUID;
    v_quantity INTEGER;
    v_available_stock INTEGER;
BEGIN
    -- Start transaction
    BEGIN
        -- Verify stock availability for all items
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_cart_items)
        LOOP
            v_product_id := (v_item->>'product_id')::UUID;
            v_quantity := (v_item->>'quantity')::INTEGER;

            -- Check available stock
            SELECT (stock_quantity - reserved_quantity) INTO v_available_stock
            FROM branch_inventory
            WHERE tenant_id = p_tenant_id
                AND branch_id = p_branch_id
                AND product_id = v_product_id;

            IF v_available_stock IS NULL OR v_available_stock < v_quantity THEN
                RETURN QUERY SELECT
                    NULL::UUID as sale_id,
                    NULL::VARCHAR as sale_number,
                    FALSE as success,
                    'Insufficient stock for product: ' || (v_item->>'product_name') as error_message;
                RETURN;
            END IF;
        END LOOP;

        -- Create sale record
        INSERT INTO sales (
            tenant_id,
            branch_id,
            cashier_id,
            customer_id,
            subtotal,
            tax_amount,
            discount_amount,
            total_amount,
            payment_method,
            payment_reference,
            status
        ) VALUES (
            p_tenant_id,
            p_branch_id,
            p_cashier_id,
            p_customer_id,
            p_subtotal,
            p_tax_amount,
            p_discount_amount,
            p_total_amount,
            p_payment_method,
            p_payment_reference,
            'completed'
        )
        RETURNING id, sale_number INTO v_sale_id, v_sale_number;

        -- Insert sale items
        INSERT INTO sale_items (
            sale_id,
            tenant_id,
            product_id,
            product_name,
            quantity,
            unit_price,
            discount_amount,
            subtotal
        )
        SELECT
            v_sale_id,
            p_tenant_id,
            (item->>'product_id')::UUID,
            item->>'product_name',
            (item->>'quantity')::INTEGER,
            (item->>'unit_price')::DECIMAL,
            COALESCE((item->>'discount_amount')::DECIMAL, 0),
            (item->>'subtotal')::DECIMAL
        FROM jsonb_array_elements(p_cart_items) AS item;

        -- Deduct stock for each item
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_cart_items)
        LOOP
            v_product_id := (v_item->>'product_id')::UUID;
            v_quantity := (v_item->>'quantity')::INTEGER;

            -- Create inventory transaction
            INSERT INTO inventory_transactions (
                tenant_id,
                branch_id,
                product_id,
                transaction_type,
                quantity_delta,
                previous_quantity,
                new_quantity,
                reference_id,
                reference_type,
                staff_id
            )
            SELECT
                p_tenant_id,
                p_branch_id,
                v_product_id,
                'sale'::transaction_type,
                -v_quantity,
                bi.stock_quantity,
                bi.stock_quantity - v_quantity,
                v_sale_id,
                'sale',
                p_cashier_id
            FROM branch_inventory bi
            WHERE bi.tenant_id = p_tenant_id
                AND bi.branch_id = p_branch_id
                AND bi.product_id = v_product_id;
        END LOOP;

        -- Return success
        RETURN QUERY SELECT
            v_sale_id as sale_id,
            v_sale_number as sale_number,
            TRUE as success,
            NULL::TEXT as error_message;

    EXCEPTION WHEN OTHERS THEN
        -- Return error
        RETURN QUERY SELECT
            NULL::UUID as sale_id,
            NULL::VARCHAR as sale_number,
            FALSE as success,
            SQLERRM as error_message;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Parameters**:
- `p_tenant_id` (UUID): Tenant ID
- `p_branch_id` (UUID): Branch ID
- `p_cashier_id` (UUID): Cashier user ID
- `p_customer_id` (UUID): Customer ID (nullable)
- `p_cart_items` (JSONB): Array of cart items
- `p_subtotal` (DECIMAL): Subtotal amount
- `p_tax_amount` (DECIMAL): Tax amount
- `p_discount_amount` (DECIMAL): Discount amount
- `p_total_amount` (DECIMAL): Total amount
- `p_payment_method` (payment_method): Payment method enum
- `p_payment_reference` (TEXT): Payment reference (optional)

**Cart Items JSON Format**:
```json
[
  {
    "product_id": "uuid",
    "product_name": "Product Name",
    "quantity": 2,
    "unit_price": 1500.00,
    "discount_amount": 0,
    "subtotal": 3000.00
  }
]
```

**Returns**:
```json
{
  "sale_id": "uuid",
  "sale_number": "BRA-20260305-0001",
  "success": true,
  "error_message": null
}
```

---

### 6. void_sale

**Purpose**: Void a sale and restore inventory.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION void_sale(
    p_sale_id UUID,
    p_voided_by_id UUID,
    p_void_reason TEXT
)
RETURNS TABLE (
    success BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    v_sale RECORD;
    v_item RECORD;
BEGIN
    -- Get sale details
    SELECT * INTO v_sale FROM sales WHERE id = p_sale_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE as success, 'Sale not found'::TEXT as error_message;
        RETURN;
    END IF;

    IF v_sale.status = 'voided' THEN
        RETURN QUERY SELECT FALSE as success, 'Sale already voided'::TEXT as error_message;
        RETURN;
    END IF;

    BEGIN
        -- Update sale status
        UPDATE sales
        SET status = 'voided',
            voided_at = NOW(),
            voided_by_id = p_voided_by_id,
            void_reason = p_void_reason
        WHERE id = p_sale_id;

        -- Restore inventory for each item
        FOR v_item IN
            SELECT * FROM sale_items WHERE sale_id = p_sale_id
        LOOP
            -- Create reverse inventory transaction
            INSERT INTO inventory_transactions (
                tenant_id,
                branch_id,
                product_id,
                transaction_type,
                quantity_delta,
                previous_quantity,
                new_quantity,
                reference_id,
                reference_type,
                notes,
                staff_id
            )
            SELECT
                v_sale.tenant_id,
                v_sale.branch_id,
                v_item.product_id,
                'adjustment'::transaction_type,
                v_item.quantity,
                bi.stock_quantity,
                bi.stock_quantity + v_item.quantity,
                p_sale_id,
                'void_sale',
                'Voided sale: ' || v_sale.sale_number,
                p_voided_by_id
            FROM branch_inventory bi
            WHERE bi.tenant_id = v_sale.tenant_id
                AND bi.branch_id = v_sale.branch_id
                AND bi.product_id = v_item.product_id;
        END LOOP;

        -- Reverse customer loyalty points if applicable
        IF v_sale.customer_id IS NOT NULL THEN
            UPDATE customers
            SET loyalty_points = GREATEST(loyalty_points - FLOOR(v_sale.total_amount / 100), 0),
                total_purchases = GREATEST(total_purchases - v_sale.total_amount, 0),
                purchase_count = GREATEST(purchase_count - 1, 0)
            WHERE id = v_sale.customer_id;
        END IF;

        RETURN QUERY SELECT TRUE as success, NULL::TEXT as error_message;

    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT FALSE as success, SQLERRM as error_message;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Parameters**:
- `p_sale_id` (UUID): Sale ID to void
- `p_voided_by_id` (UUID): User ID performing void
- `p_void_reason` (TEXT): Reason for voiding

**Returns**:
```json
{
  "success": true,
  "error_message": null
}
```

---

## Product & Inventory Functions

### 7. get_products_with_stock

**Purpose**: Get all products with stock levels for management.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_products_with_stock(
    p_tenant_id UUID,
    p_branch_id UUID DEFAULT NULL,
    p_category VARCHAR DEFAULT NULL,
    p_search_term TEXT DEFAULT NULL,
    p_stock_filter TEXT DEFAULT 'all', -- 'all', 'in_stock', 'low_stock', 'out_of_stock'
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    product_id UUID,
    product_name VARCHAR,
    sku VARCHAR,
    barcode VARCHAR,
    category VARCHAR,
    unit_price DECIMAL,
    cost_price DECIMAL,
    image_url TEXT,
    is_active BOOLEAN,
    total_stock BIGINT,
    branches_count BIGINT,
    stock_value DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id as product_id,
        p.name as product_name,
        p.sku,
        p.barcode,
        p.category,
        p.unit_price,
        p.cost_price,
        p.image_url,
        p.is_active,
        COALESCE(SUM(bi.stock_quantity), 0) as total_stock,
        COUNT(DISTINCT bi.branch_id) as branches_count,
        COALESCE(SUM(bi.stock_quantity * p.cost_price), 0) as stock_value
    FROM products p
    LEFT JOIN branch_inventory bi ON bi.product_id = p.id
        AND bi.is_active = TRUE
        AND (p_branch_id IS NULL OR bi.branch_id = p_branch_id)
    WHERE p.tenant_id = p_tenant_id
        AND p._sync_is_deleted = FALSE
        AND (p_category IS NULL OR p.category = p_category)
        AND (
            p_search_term IS NULL
            OR p.name ILIKE '%' || p_search_term || '%'
            OR p.sku ILIKE '%' || p_search_term || '%'
            OR p.barcode ILIKE '%' || p_search_term || '%'
        )
    GROUP BY p.id, p.name, p.sku, p.barcode, p.category, p.unit_price, p.cost_price, p.image_url, p.is_active
    HAVING (
        p_stock_filter = 'all'
        OR (p_stock_filter = 'in_stock' AND COALESCE(SUM(bi.stock_quantity), 0) > 0)
        OR (p_stock_filter = 'low_stock' AND COALESCE(SUM(bi.stock_quantity), 0) > 0 AND COALESCE(SUM(bi.stock_quantity), 0) <= COALESCE(MIN(bi.low_stock_threshold), 10))
        OR (p_stock_filter = 'out_of_stock' AND COALESCE(SUM(bi.stock_quantity), 0) = 0)
    )
    ORDER BY p.name
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Parameters**:
- `p_tenant_id` (UUID): Tenant ID
- `p_branch_id` (UUID): Branch ID (optional, null for all branches)
- `p_category` (VARCHAR): Category filter (optional)
- `p_search_term` (TEXT): Search query (optional)
- `p_stock_filter` (TEXT): 'all', 'in_stock', 'low_stock', 'out_of_stock'
- `p_limit` (INTEGER): Pagination limit
- `p_offset` (INTEGER): Pagination offset

**Returns**: Array of products with aggregated stock

---

### 8. adjust_stock

**Purpose**: Adjust inventory stock levels.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION adjust_stock(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_product_id UUID,
    p_adjustment_type transaction_type,
    p_quantity_delta INTEGER,
    p_notes TEXT,
    p_staff_id UUID
)
RETURNS TABLE (
    success BOOLEAN,
    new_quantity INTEGER,
    error_message TEXT
) AS $$
DECLARE
    v_current_stock INTEGER;
    v_new_stock INTEGER;
BEGIN
    -- Get current stock
    SELECT stock_quantity INTO v_current_stock
    FROM branch_inventory
    WHERE tenant_id = p_tenant_id
        AND branch_id = p_branch_id
        AND product_id = p_product_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT
            FALSE as success,
            0 as new_quantity,
            'Product not found in branch inventory'::TEXT as error_message;
        RETURN;
    END IF;

    -- Calculate new stock
    v_new_stock := v_current_stock + p_quantity_delta;

    IF v_new_stock < 0 THEN
        RETURN QUERY SELECT
            FALSE as success,
            v_current_stock as new_quantity,
            'Stock cannot be negative'::TEXT as error_message;
        RETURN;
    END IF;

    BEGIN
        -- Create inventory transaction
        INSERT INTO inventory_transactions (
            tenant_id,
            branch_id,
            product_id,
            transaction_type,
            quantity_delta,
            previous_quantity,
            new_quantity,
            notes,
            staff_id
        ) VALUES (
            p_tenant_id,
            p_branch_id,
            p_product_id,
            p_adjustment_type,
            p_quantity_delta,
            v_current_stock,
            v_new_stock,
            p_notes,
            p_staff_id
        );

        -- Update will happen via trigger

        RETURN QUERY SELECT
            TRUE as success,
            v_new_stock as new_quantity,
            NULL::TEXT as error_message;

    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT
            FALSE as success,
            v_current_stock as new_quantity,
            SQLERRM as error_message;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Parameters**:
- `p_tenant_id` (UUID): Tenant ID
- `p_branch_id` (UUID): Branch ID
- `p_product_id` (UUID): Product ID
- `p_adjustment_type` (transaction_type): 'restock', 'adjustment', 'expiry'
- `p_quantity_delta` (INTEGER): Quantity change (+10, -5, etc.)
- `p_notes` (TEXT): Adjustment reason/notes
- `p_staff_id` (UUID): Staff member ID

**Returns**:
```json
{
  "success": true,
  "new_quantity": 45,
  "error_message": null
}
```

---

## Sales History Functions

### 9. get_sales_with_filters

**Purpose**: Get sales history with advanced filters.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_sales_with_filters(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_start_date DATE,
    p_end_date DATE,
    p_payment_method payment_method DEFAULT NULL,
    p_cashier_id UUID DEFAULT NULL,
    p_customer_id UUID DEFAULT NULL,
    p_status sale_status DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    sale_id UUID,
    sale_number VARCHAR,
    customer_name TEXT,
    cashier_name TEXT,
    total_amount DECIMAL,
    payment_method payment_method,
    status sale_status,
    items_count BIGINT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id as sale_id,
        s.sale_number,
        c.full_name as customer_name,
        u.full_name as cashier_name,
        s.total_amount,
        s.payment_method,
        s.status,
        COUNT(si.id) as items_count,
        s.created_at
    FROM sales s
    LEFT JOIN customers c ON c.id = s.customer_id
    INNER JOIN users u ON u.id = s.cashier_id
    LEFT JOIN sale_items si ON si.sale_id = s.id
    WHERE s.tenant_id = p_tenant_id
        AND s.branch_id = p_branch_id
        AND DATE(s.created_at) >= p_start_date
        AND DATE(s.created_at) <= p_end_date
        AND (p_payment_method IS NULL OR s.payment_method = p_payment_method)
        AND (p_cashier_id IS NULL OR s.cashier_id = p_cashier_id)
        AND (p_customer_id IS NULL OR s.customer_id = p_customer_id)
        AND (p_status IS NULL OR s.status = p_status)
    GROUP BY s.id, s.sale_number, c.full_name, u.full_name, s.total_amount, s.payment_method, s.status, s.created_at
    ORDER BY s.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

### 10. get_sales_summary

**Purpose**: Get sales summary for a date range.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_sales_summary(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    total_sales DECIMAL,
    total_transactions BIGINT,
    avg_transaction DECIMAL,
    total_cash DECIMAL,
    total_card DECIMAL,
    total_transfer DECIMAL,
    total_mobile_money DECIMAL,
    total_tax DECIMAL,
    total_discount DECIMAL,
    total_items_sold BIGINT,
    unique_customers BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(s.total_amount), 0) as total_sales,
        COUNT(s.id) as total_transactions,
        COALESCE(AVG(s.total_amount), 0) as avg_transaction,
        COALESCE(SUM(CASE WHEN s.payment_method = 'cash' THEN s.total_amount ELSE 0 END), 0) as total_cash,
        COALESCE(SUM(CASE WHEN s.payment_method = 'card' THEN s.total_amount ELSE 0 END), 0) as total_card,
        COALESCE(SUM(CASE WHEN s.payment_method = 'bank_transfer' THEN s.total_amount ELSE 0 END), 0) as total_transfer,
        COALESCE(SUM(CASE WHEN s.payment_method = 'mobile_money' THEN s.total_amount ELSE 0 END), 0) as total_mobile_money,
        COALESCE(SUM(s.tax_amount), 0) as total_tax,
        COALESCE(SUM(s.discount_amount), 0) as total_discount,
        COALESCE(SUM(si.quantity), 0)::BIGINT as total_items_sold,
        COUNT(DISTINCT s.customer_id) as unique_customers
    FROM sales s
    LEFT JOIN sale_items si ON si.sale_id = s.id
    WHERE s.tenant_id = p_tenant_id
        AND s.branch_id = p_branch_id
        AND DATE(s.created_at) >= p_start_date
        AND DATE(s.created_at) <= p_end_date
        AND s.status = 'completed';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Customer Functions

### 11. search_customers

**Purpose**: Search customers with fuzzy matching.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION search_customers(
    p_tenant_id UUID,
    p_search_term TEXT,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    customer_id UUID,
    full_name VARCHAR,
    phone VARCHAR,
    email VARCHAR,
    loyalty_points INTEGER,
    total_purchases DECIMAL,
    purchase_count INTEGER,
    last_purchase_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id as customer_id,
        c.full_name,
        c.phone,
        c.email,
        c.loyalty_points,
        c.total_purchases,
        c.purchase_count,
        c.last_purchase_at
    FROM customers c
    WHERE c.tenant_id = p_tenant_id
        AND c._sync_is_deleted = FALSE
        AND (
            c.full_name ILIKE '%' || p_search_term || '%'
            OR c.phone ILIKE '%' || p_search_term || '%'
            OR c.email ILIKE '%' || p_search_term || '%'
        )
    ORDER BY c.full_name
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

### 12. get_customer_stats

**Purpose**: Get detailed customer statistics.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_customer_stats(
    p_customer_id UUID
)
RETURNS TABLE (
    total_spent DECIMAL,
    total_purchases INTEGER,
    avg_transaction DECIMAL,
    loyalty_points INTEGER,
    last_purchase_at TIMESTAMPTZ,
    favorite_payment_method payment_method,
    most_purchased_category VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.total_purchases as total_spent,
        c.purchase_count as total_purchases,
        CASE WHEN c.purchase_count > 0 THEN c.total_purchases / c.purchase_count ELSE 0 END as avg_transaction,
        c.loyalty_points,
        c.last_purchase_at,
        (
            SELECT s.payment_method
            FROM sales s
            WHERE s.customer_id = p_customer_id
            GROUP BY s.payment_method
            ORDER BY COUNT(*) DESC
            LIMIT 1
        ) as favorite_payment_method,
        (
            SELECT p.category
            FROM sale_items si
            INNER JOIN sales s ON s.id = si.sale_id
            INNER JOIN products p ON p.id = si.product_id
            WHERE s.customer_id = p_customer_id
            GROUP BY p.category
            ORDER BY SUM(si.quantity) DESC
            LIMIT 1
        ) as most_purchased_category
    FROM customers c
    WHERE c.id = p_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Reports Functions

### 13. get_daily_sales_trend

**Purpose**: Get daily sales data for trend charts.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_daily_sales_trend(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    sale_date DATE,
    total_sales DECIMAL,
    transaction_count BIGINT,
    avg_transaction DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        DATE(s.created_at) as sale_date,
        COALESCE(SUM(s.total_amount), 0) as total_sales,
        COUNT(s.id) as transaction_count,
        COALESCE(AVG(s.total_amount), 0) as avg_transaction
    FROM sales s
    WHERE s.tenant_id = p_tenant_id
        AND s.branch_id = p_branch_id
        AND DATE(s.created_at) >= p_start_date
        AND DATE(s.created_at) <= p_end_date
        AND s.status = 'completed'
    GROUP BY DATE(s.created_at)
    ORDER BY DATE(s.created_at);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

### 14. get_top_products

**Purpose**: Get best-selling products.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_top_products(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_start_date DATE,
    p_end_date DATE,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    product_id UUID,
    product_name VARCHAR,
    category VARCHAR,
    quantity_sold BIGINT,
    total_revenue DECIMAL,
    avg_price DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id as product_id,
        p.name as product_name,
        p.category,
        COALESCE(SUM(si.quantity), 0) as quantity_sold,
        COALESCE(SUM(si.subtotal), 0) as total_revenue,
        COALESCE(AVG(si.unit_price), 0) as avg_price
    FROM products p
    INNER JOIN sale_items si ON si.product_id = p.id
    INNER JOIN sales s ON s.id = si.sale_id
    WHERE s.tenant_id = p_tenant_id
        AND s.branch_id = p_branch_id
        AND DATE(s.created_at) >= p_start_date
        AND DATE(s.created_at) <= p_end_date
        AND s.status = 'completed'
    GROUP BY p.id, p.name, p.category
    ORDER BY quantity_sold DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

### 15. calculate_inventory_value

**Purpose**: Calculate total inventory value.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION calculate_inventory_value(
    p_tenant_id UUID,
    p_branch_id UUID
)
RETURNS TABLE (
    total_items BIGINT,
    total_stock_quantity BIGINT,
    total_cost_value DECIMAL,
    total_selling_value DECIMAL,
    potential_profit DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(DISTINCT bi.product_id) as total_items,
        COALESCE(SUM(bi.stock_quantity), 0) as total_stock_quantity,
        COALESCE(SUM(bi.stock_quantity * p.cost_price), 0) as total_cost_value,
        COALESCE(SUM(bi.stock_quantity * p.unit_price), 0) as total_selling_value,
        COALESCE(SUM(bi.stock_quantity * (p.unit_price - p.cost_price)), 0) as potential_profit
    FROM branch_inventory bi
    INNER JOIN products p ON p.id = bi.product_id
    WHERE bi.tenant_id = p_tenant_id
        AND bi.branch_id = p_branch_id
        AND bi.is_active = TRUE
        AND p.is_active = TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Staff & Branch Functions

### 16. get_staff_performance

**Purpose**: Get staff performance metrics.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION get_staff_performance(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    staff_id UUID,
    staff_name VARCHAR,
    role user_role,
    total_sales DECIMAL,
    transaction_count BIGINT,
    avg_transaction DECIMAL,
    items_sold BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id as staff_id,
        u.full_name as staff_name,
        u.role,
        COALESCE(SUM(s.total_amount), 0) as total_sales,
        COUNT(s.id) as transaction_count,
        COALESCE(AVG(s.total_amount), 0) as avg_transaction,
        COALESCE(SUM(si.quantity), 0)::BIGINT as items_sold
    FROM users u
    LEFT JOIN sales s ON s.cashier_id = u.id
        AND s.tenant_id = p_tenant_id
        AND s.branch_id = p_branch_id
        AND DATE(s.created_at) >= p_start_date
        AND DATE(s.created_at) <= p_end_date
        AND s.status = 'completed'
    LEFT JOIN sale_items si ON si.sale_id = s.id
    WHERE u.tenant_id = p_tenant_id
        AND u.branch_id = p_branch_id
        AND u.role IN ('cashier', 'branch_manager')
        AND u.deleted_at IS NULL
    GROUP BY u.id, u.full_name, u.role
    ORDER BY total_sales DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

### 17. create_inter_branch_transfer

**Purpose**: Create stock transfer between branches.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION create_inter_branch_transfer(
    p_tenant_id UUID,
    p_source_branch_id UUID,
    p_destination_branch_id UUID,
    p_transfer_items JSONB,
    p_notes TEXT,
    p_authorized_by_id UUID
)
RETURNS TABLE (
    transfer_id UUID,
    success BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    v_transfer_id UUID;
    v_item JSONB;
    v_product_id UUID;
    v_quantity INTEGER;
    v_available_stock INTEGER;
BEGIN
    -- Verify stock availability
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_transfer_items)
    LOOP
        v_product_id := (v_item->>'product_id')::UUID;
        v_quantity := (v_item->>'quantity')::INTEGER;

        SELECT (stock_quantity - reserved_quantity) INTO v_available_stock
        FROM branch_inventory
        WHERE tenant_id = p_tenant_id
            AND branch_id = p_source_branch_id
            AND product_id = v_product_id;

        IF v_available_stock IS NULL OR v_available_stock < v_quantity THEN
            RETURN QUERY SELECT
                NULL::UUID as transfer_id,
                FALSE as success,
                'Insufficient stock for product'::TEXT as error_message;
            RETURN;
        END IF;
    END LOOP;

    BEGIN
        -- Create transfer record
        INSERT INTO inter_branch_transfers (
            tenant_id,
            source_branch_id,
            destination_branch_id,
            status,
            notes,
            authorized_by_id
        ) VALUES (
            p_tenant_id,
            p_source_branch_id,
            p_destination_branch_id,
            'pending',
            p_notes,
            p_authorized_by_id
        )
        RETURNING id INTO v_transfer_id;

        -- Insert transfer items
        INSERT INTO transfer_items (
            transfer_id,
            product_id,
            quantity
        )
        SELECT
            v_transfer_id,
            (item->>'product_id')::UUID,
            (item->>'quantity')::INTEGER
        FROM jsonb_array_elements(p_transfer_items) AS item;

        -- Reserve stock at source
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_transfer_items)
        LOOP
            v_product_id := (v_item->>'product_id')::UUID;
            v_quantity := (v_item->>'quantity')::INTEGER;

            UPDATE branch_inventory
            SET reserved_quantity = reserved_quantity + v_quantity
            WHERE tenant_id = p_tenant_id
                AND branch_id = p_source_branch_id
                AND product_id = v_product_id;
        END LOOP;

        RETURN QUERY SELECT
            v_transfer_id as transfer_id,
            TRUE as success,
            NULL::TEXT as error_message;

    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT
            NULL::UUID as transfer_id,
            FALSE as success,
            SQLERRM as error_message;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Utility Functions

### 18. generate_slug

**Purpose**: Generate URL-friendly slug from text.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION generate_slug(p_text TEXT)
RETURNS TEXT AS $$
DECLARE
    v_slug TEXT;
    v_counter INTEGER := 0;
    v_final_slug TEXT;
BEGIN
    -- Convert to lowercase and replace spaces/special chars with hyphens
    v_slug := lower(trim(p_text));
    v_slug := regexp_replace(v_slug, '[^a-z0-9]+', '-', 'g');
    v_slug := regexp_replace(v_slug, '^-+|-+$', '', 'g');

    v_final_slug := v_slug;

    -- Check for uniqueness and append counter if needed
    WHILE EXISTS (SELECT 1 FROM tenants WHERE slug = v_final_slug) LOOP
        v_counter := v_counter + 1;
        v_final_slug := v_slug || '-' || v_counter;
    END LOOP;

    RETURN v_final_slug;
END;
$$ LANGUAGE plpgsql;
```

---

### 19. calculate_profit_margin

**Purpose**: Calculate profit margin percentage.

**SQL Definition**:
```sql
CREATE OR REPLACE FUNCTION calculate_profit_margin(
    p_selling_price DECIMAL,
    p_cost_price DECIMAL
)
RETURNS DECIMAL AS $$
BEGIN
    IF p_cost_price = 0 THEN
        RETURN 0;
    END IF;

    RETURN ROUND(((p_selling_price - p_cost_price) / p_cost_price) * 100, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

---

## FlutterFlow Integration Examples

### Example 1: Dashboard - Get Daily Summary

**Step 1: Create Backend Query in FlutterFlow**
1. Go to Backend Query → Supabase
2. Click "Add Query" → "RPC Call"
3. Name: `getDailySales`
4. Function Name: `get_daily_sales_summary`

**Step 2: Configure Parameters**
```dart
// In FlutterFlow Query Parameters
{
  "p_tenant_id": FFAppState().tenantId,
  "p_branch_id": FFAppState().branchId,
  "p_date": DateFormat('yyyy-MM-dd').format(DateTime.now())
}
```

**Step 3: Parse Response**
```dart
// In FlutterFlow, set response type to JSON
// Access fields in UI:
queryResult.jsonBody['total_amount']
queryResult.jsonBody['transaction_count']
queryResult.jsonBody['avg_transaction']
```

---

### Example 2: POS - Complete Sale

**Step 1: Prepare Cart Items JSON**
```dart
// Custom Action: prepareCartItemsJSON
List<dynamic> prepareCartItemsJSON(List<CartItem> cartItems) {
  return cartItems.map((item) => {
    'product_id': item.productId,
    'product_name': item.productName,
    'quantity': item.quantity,
    'unit_price': item.unitPrice,
    'discount_amount': item.discountAmount,
    'subtotal': item.subtotal,
  }).toList();
}
```

**Step 2: Create RPC Call**
```dart
// Backend Query: completeSale
{
  "p_tenant_id": FFAppState().tenantId,
  "p_branch_id": FFAppState().branchId,
  "p_cashier_id": FFAppState().userId,
  "p_customer_id": FFAppState().selectedCustomerId, // nullable
  "p_cart_items": jsonEncode(cartItemsJSON),
  "p_subtotal": cartSubtotal,
  "p_tax_amount": taxAmount,
  "p_discount_amount": discountAmount,
  "p_total_amount": totalAmount,
  "p_payment_method": selectedPaymentMethod,
  "p_payment_reference": paymentReference
}
```

**Step 3: Handle Response**
```dart
// In FlutterFlow Action Flow
if (queryResult.jsonBody['success'] == true) {
  // Show success message
  // Navigate to receipt
  context.pushNamed('SaleReceipt', extra: {
    'saleId': queryResult.jsonBody['sale_id'],
    'saleNumber': queryResult.jsonBody['sale_number'],
  });
} else {
  // Show error message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(queryResult.jsonBody['error_message'])),
  );
}
```

---

### Example 3: Products - Search for POS

**Step 1: Create Search Query**
```dart
// Backend Query: searchProducts
// Add debounce to search field (300ms)
{
  "p_tenant_id": FFAppState().tenantId,
  "p_branch_id": FFAppState().branchId,
  "p_search_term": searchTextController.text,
  "p_limit": 20
}
```

**Step 2: Display Results**
```dart
// In FlutterFlow ListView
// Data Source: searchProductsQuery
// Builder: Generate children from variable

// Each ListTile/Card shows:
productItem.productName
productItem.unitPrice
productItem.availableQuantity
```

---

### Example 4: Reports - Sales Trend Chart

**Step 1: Fetch Trend Data**
```dart
// Backend Query: getSalesTrend
{
  "p_tenant_id": FFAppState().tenantId,
  "p_branch_id": FFAppState().branchId,
  "p_start_date": DateFormat('yyyy-MM-dd').format(startDate),
  "p_end_date": DateFormat('yyyy-MM-dd').format(endDate)
}
```

**Step 2: Use Chart Widget**
```dart
// In FlutterFlow, add Custom Widget: LineChart
// Pass data: queryResult.jsonBody

// In Custom Widget:
List<FlSpot> spots = [];
for (int i = 0; i < data.length; i++) {
  spots.add(FlSpot(
    i.toDouble(),
    data[i]['total_sales'].toDouble(),
  ));
}
```

---

## Error Handling Pattern

All RPC functions return error information. Always check for errors:

```dart
// Check if query succeeded
if (queryResult.succeeded) {
  final data = queryResult.jsonBody;

  // Check function-specific success field
  if (data['success'] == true) {
    // Process successful result
  } else {
    // Show error from function
    showErrorSnackbar(data['error_message']);
  }
} else {
  // Show network/query error
  showErrorSnackbar(queryResult.error);
}
```

---

## Testing RPC Functions

Use Supabase SQL Editor to test functions:

```sql
-- Test get_daily_sales_summary
SELECT * FROM get_daily_sales_summary(
  'tenant-uuid'::UUID,
  'branch-uuid'::UUID,
  '2026-03-05'::DATE
);

-- Test complete_sale_transaction
SELECT * FROM complete_sale_transaction(
  'tenant-uuid'::UUID,
  'branch-uuid'::UUID,
  'cashier-uuid'::UUID,
  NULL, -- no customer
  '[{"product_id": "product-uuid", "product_name": "Test Product", "quantity": 2, "unit_price": 1500, "discount_amount": 0, "subtotal": 3000}]'::JSONB,
  3000.00,
  225.00,
  0.00,
  3225.00,
  'cash'::payment_method,
  NULL
);
```

---

## Performance Optimization

1. **Use Indexes**: All functions use indexed columns
2. **Limit Results**: Always use LIMIT for large datasets
3. **Pagination**: Use OFFSET for pagination
4. **Caching**: Cache frequently accessed data in FFAppState
5. **Lazy Loading**: Load data on demand, not upfront

---

## Security Notes

1. All functions use `SECURITY DEFINER` - they run with database owner privileges
2. RLS policies still apply through the functions
3. Always validate `tenant_id` and `branch_id` in functions
4. Never expose raw SQL queries to client
5. Use parameterized queries only

---

## Deployment Checklist

- [ ] Run all SQL function definitions in Supabase
- [ ] Test each function with sample data
- [ ] Configure all RPC calls in FlutterFlow
- [ ] Set up error handling for each query
- [ ] Test offline behavior for critical functions
- [ ] Monitor function performance in Supabase dashboard
- [ ] Set up alerts for failed queries

---

**End of RPC Functions Guide**

This guide provides complete SQL definitions and integration instructions for all 19 RPC functions needed across the 32 pages of the POS system.
