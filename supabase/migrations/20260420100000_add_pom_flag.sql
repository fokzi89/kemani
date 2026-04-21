-- Migration: Add isPOM flag to products and branch_inventory
-- Description: Standardizes the Prescription Only Medicine flag for visibility control.

-- 1. Update products table
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS "isPOM" boolean NOT NULL DEFAULT false;

-- 2. Update branch_inventory table
ALTER TABLE public.branch_inventory 
ADD COLUMN IF NOT EXISTS "isPOM" boolean NOT NULL DEFAULT false;

-- 3. Update indices for optimized storefront queries
CREATE INDEX IF NOT EXISTS idx_branch_inventory_not_pom ON public.branch_inventory (tenant_id, branch_id) 
WHERE ("isPOM" = false AND is_active = true AND _sync_is_deleted = false);

CREATE INDEX IF NOT EXISTS idx_products_not_pom ON public.products (is_active) 
WHERE ("isPOM" = false AND deleted_at IS NULL);
