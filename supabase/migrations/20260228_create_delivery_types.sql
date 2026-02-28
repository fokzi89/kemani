-- ============================================================
-- Migration: Delivery Types Table
-- ============================================================
-- Purpose: Tenant-defined delivery options and pricing
-- Context: Each tenant creates their own delivery types
--          (Van, Motorbike, Bicycle, Trek, etc.) with custom fees
-- Date: 2026-02-28

-- ============================================================
-- Step 1: Create delivery_types table
-- ============================================================

CREATE TABLE IF NOT EXISTS delivery_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Delivery type details
    name VARCHAR(50) NOT NULL,
    -- Examples: "Van", "Motorbike", "Bicycle", "Trek", "Express Delivery"

    description TEXT,
    -- Optional description for customers

    -- Pricing structure (flexible)
    base_fee DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (base_fee >= 0),
    -- Flat rate fee (e.g., NGN 500 base)

    per_km_fee DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (per_km_fee >= 0),
    -- Additional fee per kilometer (e.g., NGN 50/km)

    free_distance_km DECIMAL(8,2) NOT NULL DEFAULT 0 CHECK (free_distance_km >= 0),
    -- Distance within which delivery is free
    -- Example: 2km free, then charges apply

    min_order_value DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (min_order_value >= 0),
    -- Minimum order value required to use this delivery type
    -- Example: "Free Delivery (min NGN 5,000 order)"

    -- Service constraints
    max_distance_km DECIMAL(8,2) CHECK (max_distance_km IS NULL OR max_distance_km > 0),
    -- Maximum service distance (NULL = unlimited)
    -- Example: Bicycle limited to 5km radius

    estimated_minutes INTEGER CHECK (estimated_minutes IS NULL OR estimated_minutes > 0),
    -- Estimated delivery time in minutes

    -- Status
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    -- Can be toggled on/off without deletion

    display_order INTEGER NOT NULL DEFAULT 0,
    -- Order to display options to customers (lower = first)

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure unique names within tenant
    CONSTRAINT delivery_types_tenant_name_unique UNIQUE(tenant_id, name)
);

-- ============================================================
-- Step 2: Create indexes
-- ============================================================

CREATE INDEX idx_delivery_types_tenant_id ON delivery_types(tenant_id);
CREATE INDEX idx_delivery_types_active ON delivery_types(tenant_id, is_active);
CREATE INDEX idx_delivery_types_display_order ON delivery_types(tenant_id, display_order);

-- ============================================================
-- Step 3: Enable Row Level Security
-- ============================================================

ALTER TABLE delivery_types ENABLE ROW LEVEL SECURITY;

-- Tenant isolation policy
CREATE POLICY "Delivery types tenant isolation" ON delivery_types
    USING (tenant_id = current_tenant_id());

-- Allow tenants to view their delivery types
CREATE POLICY "Tenants can view delivery types" ON delivery_types
    FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Allow tenants to create delivery types
CREATE POLICY "Tenants can create delivery types" ON delivery_types
    FOR INSERT
    WITH CHECK (tenant_id = current_tenant_id());

-- Allow tenants to update delivery types
CREATE POLICY "Tenants can update delivery types" ON delivery_types
    FOR UPDATE
    USING (tenant_id = current_tenant_id())
    WITH CHECK (tenant_id = current_tenant_id());

-- Allow tenants to delete delivery types
CREATE POLICY "Tenants can delete delivery types" ON delivery_types
    FOR DELETE
    USING (tenant_id = current_tenant_id());

-- ============================================================
-- Step 4: Create trigger to update updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_delivery_types_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_delivery_types_updated_at
    BEFORE UPDATE ON delivery_types
    FOR EACH ROW
    EXECUTE FUNCTION update_delivery_types_updated_at();

-- ============================================================
-- Step 5: Create function to calculate delivery fee
-- ============================================================

CREATE OR REPLACE FUNCTION calculate_delivery_fee(
    p_delivery_type_id UUID,
    p_distance_km DECIMAL,
    p_order_value DECIMAL DEFAULT 0
)
RETURNS DECIMAL AS $$
DECLARE
    v_delivery_type RECORD;
    v_fee DECIMAL;
    v_chargeable_distance DECIMAL;
BEGIN
    -- Get delivery type details
    SELECT
        base_fee,
        per_km_fee,
        free_distance_km,
        min_order_value,
        max_distance_km
    INTO v_delivery_type
    FROM delivery_types
    WHERE id = p_delivery_type_id
    AND is_active = TRUE;

    -- If delivery type not found or inactive, return NULL
    IF v_delivery_type IS NULL THEN
        RETURN NULL;
    END IF;

    -- Check if order meets minimum value
    IF p_order_value < v_delivery_type.min_order_value THEN
        -- Order doesn't meet minimum, return NULL (not eligible)
        RETURN NULL;
    END IF;

    -- Check if distance exceeds maximum
    IF v_delivery_type.max_distance_km IS NOT NULL AND p_distance_km > v_delivery_type.max_distance_km THEN
        -- Distance too far, return NULL (not eligible)
        RETURN NULL;
    END IF;

    -- Calculate chargeable distance (distance beyond free zone)
    v_chargeable_distance := GREATEST(p_distance_km - v_delivery_type.free_distance_km, 0);

    -- Calculate total fee: base + (chargeable_distance * per_km_fee)
    v_fee := v_delivery_type.base_fee + (v_chargeable_distance * v_delivery_type.per_km_fee);

    RETURN v_fee;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 6: Insert default delivery types for existing tenants
-- ============================================================

-- Create standard delivery types for existing tenants
DO $$
DECLARE
    tenant_record RECORD;
BEGIN
    FOR tenant_record IN SELECT id, currency_code FROM tenants LOOP
        -- Add "Standard Delivery" option
        INSERT INTO delivery_types (
            tenant_id,
            name,
            description,
            base_fee,
            per_km_fee,
            free_distance_km,
            min_order_value,
            max_distance_km,
            estimated_minutes,
            is_active,
            display_order
        ) VALUES (
            tenant_record.id,
            'Standard Delivery',
            'Regular delivery within city limits',
            500.00,  -- NGN 500 base fee
            50.00,   -- NGN 50 per km
            0,       -- No free distance
            0,       -- No minimum order
            20,      -- Max 20km
            60,      -- 60 minutes estimated
            TRUE,
            1
        ) ON CONFLICT (tenant_id, name) DO NOTHING;

        -- Add "Pickup" option (free, no delivery)
        INSERT INTO delivery_types (
            tenant_id,
            name,
            description,
            base_fee,
            per_km_fee,
            free_distance_km,
            min_order_value,
            max_distance_km,
            estimated_minutes,
            is_active,
            display_order
        ) VALUES (
            tenant_record.id,
            'Pickup',
            'Pick up your order at our location',
            0,       -- Free
            0,
            0,
            0,
            NULL,    -- No distance limit
            15,      -- 15 minutes to prepare
            TRUE,
            0        -- Show first (preferred option)
        ) ON CONFLICT (tenant_id, name) DO NOTHING;
    END LOOP;
END;
$$;

-- ============================================================
-- Comments for documentation
-- ============================================================

COMMENT ON TABLE delivery_types IS 'Tenant-defined delivery options with flexible pricing rules';
COMMENT ON COLUMN delivery_types.name IS 'Delivery type name (Van, Motorbike, Bicycle, Trek, etc.)';
COMMENT ON COLUMN delivery_types.base_fee IS 'Flat rate fee charged regardless of distance';
COMMENT ON COLUMN delivery_types.per_km_fee IS 'Additional fee charged per kilometer';
COMMENT ON COLUMN delivery_types.free_distance_km IS 'Distance within which no per_km_fee is charged';
COMMENT ON COLUMN delivery_types.min_order_value IS 'Minimum order value required to use this delivery type';
COMMENT ON COLUMN delivery_types.max_distance_km IS 'Maximum service distance in kilometers (NULL = unlimited)';
COMMENT ON COLUMN delivery_types.estimated_minutes IS 'Estimated delivery time in minutes';
COMMENT ON COLUMN delivery_types.display_order IS 'Order to display options (lower = shown first)';

COMMENT ON FUNCTION calculate_delivery_fee(UUID, DECIMAL, DECIMAL) IS 'Calculates delivery fee based on delivery type, distance, and order value';
