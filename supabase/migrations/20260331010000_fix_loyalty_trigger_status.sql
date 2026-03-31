-- Migration: Fix customer loyalty trigger
-- Description: Updates the 'update_customer_loyalty' trigger function to reference 'sale_status' instead of 'status'

CREATE OR REPLACE FUNCTION update_customer_loyalty()
RETURNS TRIGGER AS $$
DECLARE
    points_earned INTEGER;
BEGIN
    -- Fixed: Using 'sale_status' instead of 'status' according to the sales schema definition
    IF NEW.customer_id IS NOT NULL AND NEW.sale_status = 'completed' THEN
        -- 1 point per ₦100 spent
        points_earned = FLOOR(NEW.total_amount / 100);

        UPDATE customers
        SET
            loyalty_points = loyalty_points + points_earned,
            total_purchases = total_purchases + NEW.total_amount,
            purchase_count = purchase_count + 1,
            last_purchase_at = NEW.created_at
        WHERE id = NEW.customer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
