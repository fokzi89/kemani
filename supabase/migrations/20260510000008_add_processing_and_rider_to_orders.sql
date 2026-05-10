-- ============================================================
-- Migration: Add processing and rider tracking to orders
-- ============================================================

-- 1. Add columns to orders table
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS processed_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS rider_id UUID REFERENCES riders(id),
ADD COLUMN IF NOT EXISTS processed_at TIMESTAMPTZ;

-- 2. Add comments for clarity
COMMENT ON COLUMN orders.processed_by IS 'The staff member who claimed/processed the order.';
COMMENT ON COLUMN orders.rider_id IS 'The rider assigned to this order (redundant with deliveries but added for performance/direct access).';
COMMENT ON COLUMN orders.processed_at IS 'When the staff member started processing the order.';

-- 3. Update RLS (if needed, but standard policies should cover new columns)
-- Ensure indexes for performance
CREATE INDEX IF NOT EXISTS idx_orders_processed_by ON orders(processed_by) WHERE processed_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_rider_id ON orders(rider_id) WHERE rider_id IS NOT NULL;
