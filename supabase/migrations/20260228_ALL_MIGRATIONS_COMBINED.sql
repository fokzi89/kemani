-- ============================================================
-- COMBINED MIGRATION FILE - User Story 3
-- ============================================================
-- Date: 2026-02-28
-- Contains: All 5 migrations for Customer Management & Marketplace
-- Safe to run: Idempotent - skips already-applied changes
--
-- Migrations included:
-- 1. Customer-Tenants Junction (FIXED)
-- 2. Loyalty Configuration
-- 3. Delivery Types
-- 4. Storefront Configuration
-- 5. Reserved Quantity for Branch Inventory
-- ============================================================

-- ============================================================
-- MIGRATION 1: Customer-Tenants Junction (FIXED)
-- ============================================================
-- Purpose: Support customers ordering from multiple tenants

-- Step 0: Drop existing RLS policies on customers table
DROP POLICY IF EXISTS "Customer tenant isolation" ON customers;
DROP POLICY IF EXISTS "Users can view customers in their tenant" ON customers;
DROP POLICY IF EXISTS "Staff can create customers" ON customers;
DROP POLICY IF EXISTS "Staff can update customers" ON customers;
DROP POLICY IF EXISTS "Managers can delete customers" ON customers;
DROP POLICY IF EXISTS "Tenants can view their customers" ON customers;
DROP POLICY IF EXISTS "Tenants can create customers" ON customers;
DROP POLICY IF EXISTS "Tenants can update customers" ON customers;
DROP POLICY IF EXISTS "Tenants can delete customers" ON customers;

-- Drop policies on customer_addresses that depend on customers.tenant_id
DROP POLICY IF EXISTS "customer_addresses_tenant_isolation" ON customer_addresses;
DROP POLICY IF EXISTS "Users can view customer addresses" ON customer_addresses;
DROP POLICY IF EXISTS "Users can manage customer addresses" ON customer_addresses;

-- Step 1: Create customer_tenants junction table
CREATE TABLE IF NOT EXISTS customer_tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Tenant-specific customer analytics
    loyalty_points INTEGER NOT NULL DEFAULT 0 CHECK (loyalty_points >= 0),
    total_purchases DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (total_purchases >= 0),
    purchase_count INTEGER NOT NULL DEFAULT 0 CHECK (purchase_count >= 0),
    last_purchase_at TIMESTAMPTZ,

    -- Customer preferences per tenant
    preferred_branch_id UUID REFERENCES branches(id),
    notes TEXT,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure one record per customer-tenant pair
    CONSTRAINT customer_tenants_unique UNIQUE(customer_id, tenant_id)
);

-- Step 2: Migrate existing customer data to junction table (if tenant_id exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT FROM information_schema.columns
        WHERE table_name = 'customers' AND column_name = 'tenant_id'
    ) THEN
        INSERT INTO customer_tenants (
            customer_id,
            tenant_id,
            loyalty_points,
            total_purchases,
            purchase_count,
            last_purchase_at,
            created_at,
            updated_at
        )
        SELECT
            id,
            tenant_id,
            COALESCE(loyalty_points, 0),
            COALESCE(total_purchases, 0),
            COALESCE(purchase_count, 0),
            last_purchase_at,
            created_at,
            updated_at
        FROM customers
        WHERE tenant_id IS NOT NULL
        ON CONFLICT (customer_id, tenant_id) DO NOTHING;
    END IF;
END $$;

-- Step 3: Drop tenant-specific columns from customers
ALTER TABLE customers DROP COLUMN IF EXISTS tenant_id CASCADE;
ALTER TABLE customers DROP COLUMN IF EXISTS loyalty_points;
ALTER TABLE customers DROP COLUMN IF EXISTS total_purchases;
ALTER TABLE customers DROP COLUMN IF EXISTS purchase_count;
ALTER TABLE customers DROP COLUMN IF EXISTS last_purchase_at;

-- Step 4: Add unique constraint on email
ALTER TABLE customers DROP CONSTRAINT IF EXISTS customers_email_unique;
ALTER TABLE customers ADD CONSTRAINT customers_email_unique UNIQUE (email);

-- Step 5: Create indexes
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customer_tenants_customer_id ON customer_tenants(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_tenants_tenant_id ON customer_tenants(tenant_id);
CREATE INDEX IF NOT EXISTS idx_customer_tenants_loyalty_points ON customer_tenants(tenant_id, loyalty_points DESC);
CREATE INDEX IF NOT EXISTS idx_customer_tenants_total_purchases ON customer_tenants(tenant_id, total_purchases DESC);

-- Step 6: Enable RLS on customer_tenants
ALTER TABLE customer_tenants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Customer-tenant tenant isolation" ON customer_tenants;
CREATE POLICY "Customer-tenant tenant isolation" ON customer_tenants
    USING (tenant_id = current_tenant_id());

DROP POLICY IF EXISTS "Tenants can view their customers" ON customer_tenants;
CREATE POLICY "Tenants can view their customers" ON customer_tenants
    FOR SELECT USING (tenant_id = current_tenant_id());

DROP POLICY IF EXISTS "Tenants can create customer relationships" ON customer_tenants;
CREATE POLICY "Tenants can create customer relationships" ON customer_tenants
    FOR INSERT WITH CHECK (tenant_id = current_tenant_id());

DROP POLICY IF EXISTS "Tenants can update customer data" ON customer_tenants;
CREATE POLICY "Tenants can update customer data" ON customer_tenants
    FOR UPDATE
    USING (tenant_id = current_tenant_id())
    WITH CHECK (tenant_id = current_tenant_id());

-- Step 7: Create trigger
CREATE OR REPLACE FUNCTION update_customer_tenants_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_customer_tenants_updated_at ON customer_tenants;
CREATE TRIGGER trigger_customer_tenants_updated_at
    BEFORE UPDATE ON customer_tenants
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_tenants_updated_at();

-- Step 8: Update customers RLS policies (global access)
DROP POLICY IF EXISTS "Anyone authenticated can view customers" ON customers;
CREATE POLICY "Anyone authenticated can view customers" ON customers
    FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Anyone authenticated can create customers" ON customers;
CREATE POLICY "Anyone authenticated can create customers" ON customers
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Anyone authenticated can update customers" ON customers;
CREATE POLICY "Anyone authenticated can update customers" ON customers
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Step 9: Recreate customer_addresses policies
DROP POLICY IF EXISTS "Users can view customer addresses" ON customer_addresses;
CREATE POLICY "Users can view customer addresses" ON customer_addresses
    FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can create customer addresses" ON customer_addresses;
CREATE POLICY "Users can create customer addresses" ON customer_addresses
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update customer addresses" ON customer_addresses;
CREATE POLICY "Users can update customer addresses" ON customer_addresses
    FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can delete customer addresses" ON customer_addresses;
CREATE POLICY "Users can delete customer addresses" ON customer_addresses
    FOR DELETE USING (auth.role() = 'authenticated');

-- Comments
COMMENT ON TABLE customer_tenants IS 'Junction table linking customers to tenants with tenant-specific analytics and loyalty data';
COMMENT ON TABLE customers IS 'Global customer table - customers can order from multiple tenants';

-- ============================================================
-- MIGRATION 2: Loyalty Configuration
-- ============================================================
-- Purpose: Tenant-configurable loyalty points system

CREATE TABLE IF NOT EXISTS loyalty_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE UNIQUE,

    -- Enable/Disable
    is_enabled BOOLEAN NOT NULL DEFAULT FALSE,

    -- Earning rules
    points_per_currency_unit INTEGER NOT NULL DEFAULT 1 CHECK (points_per_currency_unit > 0),
    currency_unit DECIMAL(10,2) NOT NULL DEFAULT 100.00 CHECK (currency_unit > 0),

    -- Redemption rules
    min_redemption_points INTEGER NOT NULL DEFAULT 100 CHECK (min_redemption_points >= 0),
    redemption_value_per_point DECIMAL(10,2) NOT NULL DEFAULT 1.00 CHECK (redemption_value_per_point > 0),
    allow_partial_payment BOOLEAN NOT NULL DEFAULT TRUE,
    allow_full_payment BOOLEAN NOT NULL DEFAULT TRUE,

    -- Constraints
    max_points_per_order INTEGER CHECK (max_points_per_order IS NULL OR max_points_per_order > 0),
    points_expiry_days INTEGER CHECK (points_expiry_days IS NULL OR points_expiry_days > 0),

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_loyalty_config_tenant_id ON loyalty_config(tenant_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_config_enabled ON loyalty_config(tenant_id, is_enabled);

-- RLS
ALTER TABLE loyalty_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Loyalty config tenant isolation" ON loyalty_config;
CREATE POLICY "Loyalty config tenant isolation" ON loyalty_config
    USING (tenant_id = current_tenant_id());

DROP POLICY IF EXISTS "Tenants can manage loyalty config" ON loyalty_config;
CREATE POLICY "Tenants can manage loyalty config" ON loyalty_config
    FOR ALL USING (tenant_id = current_tenant_id());

-- Trigger
CREATE OR REPLACE FUNCTION update_loyalty_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_loyalty_config_updated_at ON loyalty_config;
CREATE TRIGGER trigger_loyalty_config_updated_at
    BEFORE UPDATE ON loyalty_config
    FOR EACH ROW
    EXECUTE FUNCTION update_loyalty_config_updated_at();

-- Helper functions
CREATE OR REPLACE FUNCTION calculate_loyalty_points(
    p_tenant_id UUID,
    p_purchase_amount DECIMAL
) RETURNS INTEGER AS $$
DECLARE
    v_config RECORD;
    v_points INTEGER;
BEGIN
    SELECT is_enabled, points_per_currency_unit, currency_unit
    INTO v_config FROM loyalty_config WHERE tenant_id = p_tenant_id;

    IF v_config IS NULL OR v_config.is_enabled = FALSE THEN
        RETURN 0;
    END IF;

    v_points := FLOOR((p_purchase_amount / v_config.currency_unit) * v_config.points_per_currency_unit);
    RETURN GREATEST(v_points, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculate_redemption_value(
    p_tenant_id UUID,
    p_points INTEGER
) RETURNS DECIMAL AS $$
DECLARE
    v_config RECORD;
BEGIN
    SELECT redemption_value_per_point INTO v_config
    FROM loyalty_config WHERE tenant_id = p_tenant_id;

    IF v_config IS NULL THEN
        RETURN 0;
    END IF;

    RETURN p_points * v_config.redemption_value_per_point;
END;
$$ LANGUAGE plpgsql;

-- Seed default configs for existing tenants
INSERT INTO loyalty_config (tenant_id, is_enabled)
SELECT id, FALSE FROM tenants
ON CONFLICT (tenant_id) DO NOTHING;

COMMENT ON TABLE loyalty_config IS 'Tenant-specific loyalty points configuration';

-- ============================================================
-- MIGRATION 3: Delivery Types
-- ============================================================
-- Purpose: Tenant-defined delivery options

CREATE TABLE IF NOT EXISTS delivery_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Basic info
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon_url TEXT,

    -- Pricing
    base_fee DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (base_fee >= 0),
    per_km_fee DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (per_km_fee >= 0),
    free_distance_km DECIMAL(10,2) DEFAULT 0 CHECK (free_distance_km >= 0),

    -- Constraints
    min_order_value DECIMAL(10,2) CHECK (min_order_value IS NULL OR min_order_value >= 0),
    max_distance_km DECIMAL(10,2) CHECK (max_distance_km IS NULL OR max_distance_km > 0),
    estimated_minutes INTEGER,

    -- Settings
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INTEGER NOT NULL DEFAULT 0,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT delivery_types_tenant_name_unique UNIQUE(tenant_id, name)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_delivery_types_tenant_id ON delivery_types(tenant_id);
CREATE INDEX IF NOT EXISTS idx_delivery_types_active ON delivery_types(tenant_id, is_active, display_order);

-- RLS
ALTER TABLE delivery_types ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Delivery types tenant isolation" ON delivery_types;
CREATE POLICY "Delivery types tenant isolation" ON delivery_types
    USING (tenant_id = current_tenant_id());

DROP POLICY IF EXISTS "Tenants can manage delivery types" ON delivery_types;
CREATE POLICY "Tenants can manage delivery types" ON delivery_types
    FOR ALL USING (tenant_id = current_tenant_id());

-- Trigger
CREATE OR REPLACE FUNCTION update_delivery_types_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_delivery_types_updated_at ON delivery_types;
CREATE TRIGGER trigger_delivery_types_updated_at
    BEFORE UPDATE ON delivery_types
    FOR EACH ROW
    EXECUTE FUNCTION update_delivery_types_updated_at();

-- Helper function
CREATE OR REPLACE FUNCTION calculate_delivery_fee(
    p_delivery_type_id UUID,
    p_distance_km DECIMAL,
    p_order_value DECIMAL DEFAULT 0
) RETURNS DECIMAL AS $$
DECLARE
    v_type RECORD;
    v_fee DECIMAL;
    v_billable_distance DECIMAL;
BEGIN
    SELECT * INTO v_type FROM delivery_types WHERE id = p_delivery_type_id;

    IF v_type IS NULL OR v_type.is_active = FALSE THEN
        RETURN NULL;
    END IF;

    IF v_type.min_order_value IS NOT NULL AND p_order_value < v_type.min_order_value THEN
        RETURN NULL;
    END IF;

    IF v_type.max_distance_km IS NOT NULL AND p_distance_km > v_type.max_distance_km THEN
        RETURN NULL;
    END IF;

    v_billable_distance := GREATEST(p_distance_km - COALESCE(v_type.free_distance_km, 0), 0);
    v_fee := v_type.base_fee + (v_billable_distance * v_type.per_km_fee);

    RETURN ROUND(v_fee, 2);
END;
$$ LANGUAGE plpgsql;

-- Seed default delivery types
INSERT INTO delivery_types (tenant_id, name, description, base_fee, per_km_fee, free_distance_km, display_order)
SELECT
    id,
    'Standard Delivery',
    'Regular delivery service',
    500.00,
    50.00,
    2.00,
    1
FROM tenants
ON CONFLICT (tenant_id, name) DO NOTHING;

INSERT INTO delivery_types (tenant_id, name, description, base_fee, per_km_fee, display_order)
SELECT
    id,
    'Pickup',
    'Customer picks up from store',
    0.00,
    0.00,
    2
FROM tenants
ON CONFLICT (tenant_id, name) DO NOTHING;

COMMENT ON TABLE delivery_types IS 'Tenant-defined delivery options with flexible pricing';

-- ============================================================
-- MIGRATION 4: Storefront Configuration
-- ============================================================
-- Purpose: Marketplace storefront customization

CREATE TABLE IF NOT EXISTS storefront_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE UNIQUE,

    -- Appearance
    banner_url TEXT,
    about_text TEXT,
    welcome_message TEXT,

    -- Operating hours (JSONB format)
    operating_hours JSONB DEFAULT '{
        "monday": {"open": "08:00", "close": "18:00", "closed": false},
        "tuesday": {"open": "08:00", "close": "18:00", "closed": false},
        "wednesday": {"open": "08:00", "close": "18:00", "closed": false},
        "thursday": {"open": "08:00", "close": "18:00", "closed": false},
        "friday": {"open": "08:00", "close": "18:00", "closed": false},
        "saturday": {"open": "09:00", "close": "17:00", "closed": false},
        "sunday": {"open": "00:00", "close": "00:00", "closed": true}
    }'::jsonb,

    -- Contact
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    contact_whatsapp VARCHAR(20),

    -- Order settings
    minimum_order_value DECIMAL(10,2) DEFAULT 0 CHECK (minimum_order_value >= 0),
    accept_online_orders BOOLEAN NOT NULL DEFAULT TRUE,
    allow_guest_checkout BOOLEAN NOT NULL DEFAULT TRUE,
    show_stock_quantity BOOLEAN NOT NULL DEFAULT FALSE,

    -- Settings
    is_active BOOLEAN NOT NULL DEFAULT FALSE,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_storefront_config_tenant_id ON storefront_config(tenant_id);
CREATE INDEX IF NOT EXISTS idx_storefront_config_active ON storefront_config(tenant_id, is_active);

-- RLS
ALTER TABLE storefront_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Storefront config tenant isolation" ON storefront_config;
CREATE POLICY "Storefront config tenant isolation" ON storefront_config
    USING (tenant_id = current_tenant_id());

DROP POLICY IF EXISTS "Tenants can manage storefront config" ON storefront_config;
CREATE POLICY "Tenants can manage storefront config" ON storefront_config
    FOR ALL USING (tenant_id = current_tenant_id());

-- Trigger
CREATE OR REPLACE FUNCTION update_storefront_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_storefront_config_updated_at ON storefront_config;
CREATE TRIGGER trigger_storefront_config_updated_at
    BEFORE UPDATE ON storefront_config
    FOR EACH ROW
    EXECUTE FUNCTION update_storefront_config_updated_at();

-- Helper function
CREATE OR REPLACE FUNCTION is_storefront_open(
    p_tenant_id UUID,
    p_check_time TIMESTAMPTZ DEFAULT NOW()
) RETURNS BOOLEAN AS $$
DECLARE
    v_config RECORD;
    v_day_name TEXT;
    v_hours JSONB;
    v_open_time TIME;
    v_close_time TIME;
    v_check_time TIME;
BEGIN
    SELECT * INTO v_config FROM storefront_config WHERE tenant_id = p_tenant_id;

    IF v_config IS NULL OR v_config.is_active = FALSE OR v_config.accept_online_orders = FALSE THEN
        RETURN FALSE;
    END IF;

    v_day_name := LOWER(TO_CHAR(p_check_time, 'Day'));
    v_day_name := TRIM(v_day_name);

    v_hours := v_config.operating_hours -> v_day_name;

    IF v_hours IS NULL OR (v_hours->>'closed')::boolean = TRUE THEN
        RETURN FALSE;
    END IF;

    v_open_time := (v_hours->>'open')::TIME;
    v_close_time := (v_hours->>'close')::TIME;
    v_check_time := p_check_time::TIME;

    RETURN v_check_time >= v_open_time AND v_check_time <= v_close_time;
END;
$$ LANGUAGE plpgsql;

-- Seed default configs
INSERT INTO storefront_config (tenant_id, is_active, allow_guest_checkout)
SELECT id, FALSE, TRUE FROM tenants
ON CONFLICT (tenant_id) DO NOTHING;

COMMENT ON TABLE storefront_config IS 'Marketplace storefront customization per tenant';

-- ============================================================
-- MIGRATION 5: Reserved Quantity for Branch Inventory
-- ============================================================
-- Purpose: Inventory reservation for pending orders

-- Add reserved_quantity column
ALTER TABLE branch_inventory
ADD COLUMN IF NOT EXISTS reserved_quantity INTEGER NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0);

-- Add constraint
ALTER TABLE branch_inventory DROP CONSTRAINT IF EXISTS check_stock_available;
ALTER TABLE branch_inventory ADD CONSTRAINT check_stock_available
CHECK (stock_quantity >= reserved_quantity);

-- Create index
CREATE INDEX IF NOT EXISTS idx_branch_inventory_available_stock
ON branch_inventory(tenant_id, branch_id, (stock_quantity - reserved_quantity));

-- Helper functions
CREATE OR REPLACE FUNCTION get_available_stock(
    p_branch_id UUID,
    p_product_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_available INTEGER;
BEGIN
    SELECT stock_quantity - reserved_quantity
    INTO v_available
    FROM branch_inventory
    WHERE branch_id = p_branch_id AND product_id = p_product_id;
    RETURN COALESCE(v_available, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reserve_inventory(
    p_branch_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_available INTEGER;
    v_rows_updated INTEGER;
BEGIN
    v_available := get_available_stock(p_branch_id, p_product_id);
    IF v_available < p_quantity THEN
        RETURN FALSE;
    END IF;

    UPDATE branch_inventory
    SET reserved_quantity = reserved_quantity + p_quantity, updated_at = NOW()
    WHERE branch_id = p_branch_id AND product_id = p_product_id
    AND (stock_quantity - reserved_quantity) >= p_quantity;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    RETURN v_rows_updated > 0;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION release_reserved_inventory(
    p_branch_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_rows_updated INTEGER;
BEGIN
    UPDATE branch_inventory
    SET reserved_quantity = GREATEST(reserved_quantity - p_quantity, 0), updated_at = NOW()
    WHERE branch_id = p_branch_id AND product_id = p_product_id
    AND reserved_quantity >= p_quantity;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    RETURN v_rows_updated > 0;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION confirm_reservation(
    p_branch_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_rows_updated INTEGER;
BEGIN
    UPDATE branch_inventory
    SET
        stock_quantity = stock_quantity - p_quantity,
        reserved_quantity = GREATEST(reserved_quantity - p_quantity, 0),
        updated_at = NOW()
    WHERE branch_id = p_branch_id AND product_id = p_product_id
    AND reserved_quantity >= p_quantity AND stock_quantity >= p_quantity;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    RETURN v_rows_updated > 0;
END;
$$ LANGUAGE plpgsql;

-- Trigger for low stock alerts
CREATE OR REPLACE FUNCTION check_reorder_alert()
RETURNS TRIGGER AS $$
DECLARE
    v_available INTEGER;
    v_product_name TEXT;
BEGIN
    v_available := NEW.stock_quantity - NEW.reserved_quantity;
    SELECT name INTO v_product_name FROM products WHERE id = NEW.product_id;

    IF NEW.low_stock_threshold IS NOT NULL THEN
        IF v_available <= NEW.low_stock_threshold THEN
            RAISE NOTICE 'Low stock alert: Product % (%) at branch % has % available (threshold: %)',
                v_product_name, NEW.product_id, NEW.branch_id, v_available, NEW.low_stock_threshold;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_check_reorder_alert ON branch_inventory;
CREATE TRIGGER trigger_check_reorder_alert
    AFTER UPDATE OF stock_quantity, reserved_quantity ON branch_inventory
    FOR EACH ROW
    WHEN (OLD.stock_quantity IS DISTINCT FROM NEW.stock_quantity
          OR OLD.reserved_quantity IS DISTINCT FROM NEW.reserved_quantity)
    EXECUTE FUNCTION check_reorder_alert();

-- Create view
CREATE OR REPLACE VIEW product_stock_status AS
SELECT
    p.id AS product_id,
    p.tenant_id,
    bi.branch_id,
    p.name AS product_name,
    p.sku,
    p.barcode,
    bi.stock_quantity,
    bi.reserved_quantity,
    (bi.stock_quantity - bi.reserved_quantity) AS available_quantity,
    bi.low_stock_threshold,
    CASE
        WHEN (bi.stock_quantity - bi.reserved_quantity) <= 0 THEN 'out_of_stock'
        WHEN bi.low_stock_threshold IS NOT NULL
             AND (bi.stock_quantity - bi.reserved_quantity) <= bi.low_stock_threshold THEN 'low_stock'
        ELSE 'in_stock'
    END AS stock_status,
    p.unit_price AS selling_price,
    p.cost_price,
    (p.cost_price * bi.stock_quantity) AS total_stock_value,
    bi.expiry_date,
    CASE
        WHEN bi.expiry_date IS NULL THEN NULL
        WHEN bi.expiry_date < CURRENT_DATE THEN 'expired'
        WHEN bi.expiry_date < (CURRENT_DATE + bi.expiry_alert_days) THEN 'expiring_soon'
        ELSE 'valid'
    END AS expiry_status,
    bi.expiry_alert_days,
    p.is_active,
    bi.created_at,
    bi.updated_at
FROM products p
INNER JOIN branch_inventory bi ON p.id = bi.product_id
WHERE p.is_active = TRUE;

-- Comments
COMMENT ON COLUMN branch_inventory.reserved_quantity IS 'Quantity reserved for pending orders at this branch';
COMMENT ON VIEW product_stock_status IS 'Real-time view of product stock status per branch including reserved quantities';

-- ============================================================
-- MIGRATION COMPLETE
-- ============================================================
-- All 5 migrations applied successfully!
