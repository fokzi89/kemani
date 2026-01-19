-- ============================================================
-- Migration 009: Triggers
-- ============================================================
-- Purpose: Create triggers for automated updates and business logic

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at BEFORE UPDATE ON tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON branches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON sales
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Sync version increment on update (for CRDT)
CREATE OR REPLACE FUNCTION increment_sync_version()
RETURNS TRIGGER AS $$
BEGIN
    NEW._sync_version = OLD._sync_version + 1;
    NEW._sync_modified_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER increment_sync_version BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION increment_sync_version();
CREATE TRIGGER increment_sync_version BEFORE UPDATE ON sales
    FOR EACH ROW EXECUTE FUNCTION increment_sync_version();
CREATE TRIGGER increment_sync_version BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION increment_sync_version();

-- Auto-generate sale_number
CREATE OR REPLACE FUNCTION generate_sale_number()
RETURNS TRIGGER AS $$
DECLARE
    branch_code VARCHAR(10);
    sequence_num INTEGER;
BEGIN
    SELECT LEFT(name, 3) INTO branch_code FROM branches WHERE id = NEW.branch_id;
    SELECT COUNT(*) + 1 INTO sequence_num
        FROM sales
        WHERE branch_id = NEW.branch_id AND DATE(created_at) = CURRENT_DATE;

    NEW.sale_number = UPPER(branch_code) || '-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(sequence_num::TEXT, 4, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER generate_sale_number BEFORE INSERT ON sales
    FOR EACH ROW WHEN (NEW.sale_number IS NULL)
    EXECUTE FUNCTION generate_sale_number();

-- Auto-create commission on order completion
CREATE OR REPLACE FUNCTION create_commission_on_order_complete()
RETURNS TRIGGER AS $$
DECLARE
    tenant_commission_rate DECIMAL(5,2);
BEGIN
    IF NEW.order_status = 'completed' AND NEW.order_type = 'marketplace' THEN
        SELECT commission_rate INTO tenant_commission_rate
            FROM subscriptions WHERE tenant_id = NEW.tenant_id;

        INSERT INTO commissions (tenant_id, order_id, sale_amount, commission_rate, commission_amount)
        VALUES (
            NEW.tenant_id,
            NEW.id,
            NEW.total_amount,
            tenant_commission_rate,
            NEW.total_amount * (tenant_commission_rate / 100)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_commission AFTER UPDATE ON orders
    FOR EACH ROW WHEN (OLD.order_status != 'completed' AND NEW.order_status = 'completed')
    EXECUTE FUNCTION create_commission_on_order_complete();

-- Update customer loyalty points on sale
CREATE OR REPLACE FUNCTION update_customer_loyalty()
RETURNS TRIGGER AS $$
DECLARE
    points_earned INTEGER;
BEGIN
    IF NEW.customer_id IS NOT NULL AND NEW.status = 'completed' THEN
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

CREATE TRIGGER update_customer_loyalty AFTER INSERT ON sales
    FOR EACH ROW EXECUTE FUNCTION update_customer_loyalty();
