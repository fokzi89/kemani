-- ============================================================
-- Migration: Reintroduce Pre-order Schema (Clean Architecture)
-- ============================================================
-- Pre-orders are now:
--   - Tenant-gated  : tenants.preorders_enabled
--   - Per-product   : branch_inventory.allow_preorder
--   - Limit-capped  : branch_inventory.preorder_limit (NULL = unlimited)
--   - Demand-tracked: branch_inventory.preorder_quantity
--   - Order-tagged  : orders.is_preorder_order, sale_items.is_preorder
--   - Staff-notified: staff_notifications table
-- ============================================================

-- ── 1. branch_inventory columns ──────────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'branch_inventory' AND column_name = 'allow_preorder') THEN
        ALTER TABLE branch_inventory ADD COLUMN allow_preorder BOOLEAN NOT NULL DEFAULT false;
        COMMENT ON COLUMN branch_inventory.allow_preorder
            IS 'When true, out-of-stock units can be pre-ordered by customers.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'branch_inventory' AND column_name = 'preorder_quantity') THEN
        ALTER TABLE branch_inventory ADD COLUMN preorder_quantity INTEGER NOT NULL DEFAULT 0;
        COMMENT ON COLUMN branch_inventory.preorder_quantity
            IS 'Live demand counter — units currently committed to pre-orders.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'branch_inventory' AND column_name = 'preorder_limit') THEN
        ALTER TABLE branch_inventory ADD COLUMN preorder_limit INTEGER DEFAULT NULL;
        COMMENT ON COLUMN branch_inventory.preorder_limit
            IS 'Max units that can be pre-ordered. NULL = unlimited.';
    END IF;
END $$;

-- ── 2. tenants column ─────────────────────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'tenants' AND column_name = 'preorders_enabled') THEN
        ALTER TABLE tenants ADD COLUMN preorders_enabled BOOLEAN NOT NULL DEFAULT false;
        COMMENT ON COLUMN tenants.preorders_enabled
            IS 'Global on/off switch for the pre-order feature.';
    END IF;
END $$;

-- ── 3. orders column ──────────────────────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'orders' AND column_name = 'is_preorder_order') THEN
        ALTER TABLE orders ADD COLUMN is_preorder_order BOOLEAN NOT NULL DEFAULT false;
        COMMENT ON COLUMN orders.is_preorder_order
            IS 'True when this order contains only pre-order items (split from a mixed cart).';
    END IF;
END $$;

-- ── 4. sale_items column ──────────────────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'is_preorder') THEN
        ALTER TABLE sale_items ADD COLUMN is_preorder BOOLEAN NOT NULL DEFAULT false;
        COMMENT ON COLUMN sale_items.is_preorder
            IS 'True when this line item was placed as a pre-order (no physical stock deducted at order time).';
    END IF;
END $$;

-- ── 5. staff_notifications table ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.staff_notifications (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID        NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    branch_id   UUID        REFERENCES public.branches(id) ON DELETE SET NULL,
    type        TEXT        NOT NULL,          -- e.g. 'preorder_fulfilled', 'low_stock'
    title       TEXT        NOT NULL,
    body        TEXT        NOT NULL,
    metadata    JSONB       NOT NULL DEFAULT '{}',
    is_read     BOOLEAN     NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_staff_notifications_tenant_unread
    ON public.staff_notifications (tenant_id, is_read, created_at DESC);

ALTER TABLE public.staff_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Staff can view own tenant notifications" ON public.staff_notifications;
CREATE POLICY "Staff can view own tenant notifications"
    ON public.staff_notifications FOR SELECT
    USING (
        tenant_id IN (
            SELECT tenant_id FROM public.users WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Staff can update own tenant notifications" ON public.staff_notifications;
CREATE POLICY "Staff can update own tenant notifications"
    ON public.staff_notifications FOR UPDATE
    USING (
        tenant_id IN (
            SELECT tenant_id FROM public.users WHERE id = auth.uid()
        )
    );

-- ── 6. marketplace_products_with_stock view ───────────────────────────────────
DROP VIEW IF EXISTS public.marketplace_products_with_stock;
CREATE VIEW public.marketplace_products_with_stock AS
SELECT
    p.id                                                AS product_id,
    p.name                                              AS product_name,
    p.description,
    p.category,
    p.image_url,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer,
    p.product_type,
    p.is_active,
    bi.tenant_id,
    bi.branch_id,
    bi.id                                               AS inventory_id,
    bi.stock_quantity,
    bi.selling_price,
    bi.low_stock_threshold,
    bi.expiry_date,
    bi.unit_of_measure,
    bi.allow_preorder,
    bi.preorder_quantity,
    bi.preorder_limit,
    (bi.stock_quantity > 0 OR bi.allow_preorder = true) AS is_available,
    CASE
        WHEN bi.stock_quantity <= bi.low_stock_threshold THEN true
        ELSE false
    END AS is_low_stock
FROM public.products p
JOIN public.branch_inventory bi ON bi.product_id = p.id
WHERE p._sync_is_deleted = false
  AND p.is_active = true
  AND bi._sync_is_deleted = false
  AND bi.is_active = true;
