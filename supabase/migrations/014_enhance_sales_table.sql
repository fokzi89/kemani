-- ============================================
-- Migration: Enhance Sales Table for Analytics
-- Description: Add missing columns to existing sales table
-- Created: 2026-01-23
-- ============================================

-- Add customer_type column if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'customer_type'
    ) THEN
        ALTER TABLE sales ADD COLUMN customer_type VARCHAR(20) DEFAULT 'walk-in';
        COMMENT ON COLUMN sales.customer_type IS 'Customer type: walk-in, registered, marketplace, new';
    END IF;
END $$;

-- Add sales_attendant_id column if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'sales_attendant_id'
    ) THEN
        ALTER TABLE sales ADD COLUMN sales_attendant_id UUID REFERENCES users(id) ON DELETE SET NULL;
        COMMENT ON COLUMN sales.sales_attendant_id IS 'Staff member who assisted with the sale (for commission tracking)';

        -- Create index for sales attendant queries
        CREATE INDEX idx_sales_attendant ON sales(sales_attendant_id, created_at DESC) WHERE sales_attendant_id IS NOT NULL;
    END IF;
END $$;

-- Add sale_type column if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'sale_type'
    ) THEN
        ALTER TABLE sales ADD COLUMN sale_type VARCHAR(20) DEFAULT 'pos';
        COMMENT ON COLUMN sales.sale_type IS 'Sale type: pos, online, marketplace, delivery';
    END IF;
END $$;

-- Add channel column if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'channel'
    ) THEN
        ALTER TABLE sales ADD COLUMN channel VARCHAR(20) DEFAULT 'in-store';
        COMMENT ON COLUMN sales.channel IS 'Sales channel: in-store, online, mobile-app, whatsapp';

        -- Create index for channel analysis
        CREATE INDEX idx_sales_channel ON sales(channel, tenant_id) WHERE channel IS NOT NULL;
    END IF;
END $$;

-- Rename 'status' to 'sale_status' if needed (handle both cases)
DO $$
BEGIN
    -- If 'status' exists but 'sale_status' doesn't, rename it
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'status'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'sale_status'
    ) THEN
        ALTER TABLE sales RENAME COLUMN status TO sale_status;
    END IF;

    -- If neither exists, create sale_status
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'sale_status'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'status'
    ) THEN
        ALTER TABLE sales ADD COLUMN sale_status VARCHAR(20) DEFAULT 'completed';
        COMMENT ON COLUMN sales.sale_status IS 'Sale status: pending, completed, void, refunded, partial_refund';
    END IF;
END $$;

-- Add void tracking columns if not exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'void_reason'
    ) THEN
        ALTER TABLE sales ADD COLUMN void_reason TEXT;
        COMMENT ON COLUMN sales.void_reason IS 'Reason for voiding the sale';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'voided_by'
    ) THEN
        ALTER TABLE sales ADD COLUMN voided_by UUID REFERENCES users(id) ON DELETE SET NULL;
        COMMENT ON COLUMN sales.voided_by IS 'User who voided the sale';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'voided_at'
    ) THEN
        ALTER TABLE sales ADD COLUMN voided_at TIMESTAMPTZ;
        COMMENT ON COLUMN sales.voided_at IS 'Timestamp when sale was voided';
    END IF;
END $$;

-- Add sale_date column (for easy date-based queries)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'sale_date'
    ) THEN
        ALTER TABLE sales ADD COLUMN sale_date DATE;

        -- Populate existing records from created_at
        UPDATE sales SET sale_date = DATE(created_at) WHERE sale_date IS NULL;

        -- Make it NOT NULL after populating
        ALTER TABLE sales ALTER COLUMN sale_date SET NOT NULL;

        COMMENT ON COLUMN sales.sale_date IS 'Date portion of sale (denormalized for analytics)';

        -- Create index for date-based queries
        CREATE INDEX idx_sales_date ON sales(tenant_id, sale_date DESC);
    END IF;
END $$;

-- Add sale_time column (for hourly analysis)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'sale_time'
    ) THEN
        ALTER TABLE sales ADD COLUMN sale_time TIME;

        -- Populate existing records from created_at
        UPDATE sales SET sale_time = created_at::TIME WHERE sale_time IS NULL;

        -- Make it NOT NULL after populating
        ALTER TABLE sales ALTER COLUMN sale_time SET NOT NULL;

        COMMENT ON COLUMN sales.sale_time IS 'Time portion of sale (for hourly pattern analysis)';
    END IF;
END $$;

-- Add completed_at column (if different from created_at)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'completed_at'
    ) THEN
        ALTER TABLE sales ADD COLUMN completed_at TIMESTAMPTZ DEFAULT NOW();

        -- Populate existing records from created_at
        UPDATE sales SET completed_at = created_at WHERE completed_at IS NULL;

        -- Make it NOT NULL after populating
        ALTER TABLE sales ALTER COLUMN completed_at SET NOT NULL;

        COMMENT ON COLUMN sales.completed_at IS 'Timestamp when sale was completed';
    END IF;
END $$;

-- Create/update trigger to auto-populate sale_date and sale_time
CREATE OR REPLACE FUNCTION populate_sale_datetime()
RETURNS TRIGGER AS $$
BEGIN
    -- Set sale_date and sale_time from completed_at if not provided
    IF NEW.sale_date IS NULL THEN
        NEW.sale_date := DATE(NEW.completed_at);
    END IF;

    IF NEW.sale_time IS NULL THEN
        NEW.sale_time := NEW.completed_at::TIME;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS trg_populate_sale_datetime ON sales;
CREATE TRIGGER trg_populate_sale_datetime
    BEFORE INSERT OR UPDATE ON sales
    FOR EACH ROW
    EXECUTE FUNCTION populate_sale_datetime();

COMMENT ON TRIGGER trg_populate_sale_datetime ON sales IS 'Auto-populates sale_date and sale_time from completed_at';
