-- ============================================================
-- Migration: Process Sale Returns
-- Description: Adds RPC to safely process a sale return, updating sales table, sale_items table, and restoring inventory
-- ============================================================

CREATE OR REPLACE FUNCTION process_sale_return(
    p_sale_id UUID,
    p_items JSONB,
    p_staff_id UUID
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_sale RECORD;
    v_item RECORD;
    v_batch_id UUID;
    v_return_value DECIMAL := 0;
    v_new_subtotal DECIMAL;
    v_new_total DECIMAL;
BEGIN
    -- 1. Fetch sale
    SELECT * INTO v_sale FROM sales WHERE id = p_sale_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sale not found';
    END IF;

    -- 2. Process items
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(sale_item_id UUID, product_id UUID, return_qty INTEGER)
    LOOP
        -- Process only if return_qty > 0
        IF v_item.return_qty <= 0 THEN
            CONTINUE;
        END IF;

        DECLARE
            v_sale_item RECORD;
            v_previous_stock INTEGER;
            v_new_stock INTEGER;
            v_new_item_qty INTEGER;
            v_new_item_discount DECIMAL;
            v_new_item_subtotal DECIMAL;
        BEGIN
            -- Fetch sale_item
            SELECT * INTO v_sale_item FROM sale_items 
            WHERE id = v_item.sale_item_id AND sale_id = p_sale_id FOR UPDATE;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Sale item not found %', v_item.sale_item_id;
            END IF;

            IF v_item.return_qty > v_sale_item.quantity THEN
                RAISE EXCEPTION 'Return quantity exceeds purchased quantity';
            END IF;

            -- Calculate proportional refund value (before item update)
            v_return_value := v_return_value + (v_sale_item.unit_price * v_item.return_qty);

            -- Recalculate item fields to satisfy CHECK constraints
            v_new_item_qty := v_sale_item.quantity - v_item.return_qty;
            
            -- Proportional discount reduction
            IF v_sale_item.quantity > 0 THEN
                v_new_item_discount := (v_sale_item.discount_amount * v_new_item_qty) / v_sale_item.quantity;
            ELSE
                v_new_item_discount := 0;
            END IF;
            
            v_new_item_subtotal := (v_sale_item.unit_price * v_new_item_qty) - v_new_item_discount;

            -- Update sale_item with consistent values
            UPDATE public.sale_items 
            SET quantity = v_new_item_qty,
                discount_amount = v_new_item_discount,
                subtotal = v_new_item_subtotal
            WHERE id = v_item.sale_item_id;

            -- Find latest active batch assigned to this branch to restore inventory
            SELECT id INTO v_batch_id
            FROM branch_inventory
            WHERE branch_id = v_sale.branch_id AND product_id = v_item.product_id
            ORDER BY created_at DESC LIMIT 1 FOR UPDATE;

            -- Increment inventory and Log
            IF v_batch_id IS NOT NULL THEN
                -- Capture stock before incrementing
                SELECT stock_quantity INTO v_previous_stock FROM branch_inventory WHERE id = v_batch_id;
                v_new_stock := COALESCE(v_previous_stock, 0) + v_item.return_qty;

                UPDATE branch_inventory
                SET stock_quantity = v_new_stock,
                    updated_at = NOW()
                WHERE id = v_batch_id;

                -- Log transaction securely
                INSERT INTO inventory_transactions (
                    tenant_id, branch_id, product_id, transaction_type, 
                    quantity_delta, previous_quantity, new_quantity, reference_id, reference_type, staff_id, notes
                ) VALUES (
                    v_sale.tenant_id, v_sale.branch_id, v_item.product_id, 'adjustment',
                    v_item.return_qty, v_previous_stock, v_new_stock, p_sale_id, 'sale_return', 
                    p_staff_id, 'Item returned by customer and restored to inventory'
                );
            END IF;
        END;
    END LOOP;

    -- 3. Adjust Sale master totals
    v_new_subtotal := GREATEST(0, v_sale.subtotal - v_return_value);
    
    -- Adjust total_amount identically
    v_new_total := GREATEST(0, v_sale.total_amount - v_return_value);

    IF v_new_subtotal <= 0 THEN
        UPDATE sales 
        SET subtotal = 0, 
            total_amount = GREATEST(0, v_sale.total_amount - v_sale.subtotal), -- Keep tax if any? Or just 0
            sale_status = 'refunded',
            updated_at = NOW()
        WHERE id = p_sale_id;
    ELSE
        UPDATE sales 
        SET subtotal = v_new_subtotal, 
            total_amount = v_new_total,
            updated_at = NOW()
        WHERE id = p_sale_id;
    END IF;

END;
$$;
