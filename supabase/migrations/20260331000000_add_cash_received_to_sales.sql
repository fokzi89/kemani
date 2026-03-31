-- Migration: Add missing columns to sales table for POS checkout
-- Created: 2026-03-31

ALTER TABLE public.sales 
ADD COLUMN IF NOT EXISTS cash_received DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS change_given DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS customer_name VARCHAR(255);

-- Also ensure sale_items has consistent columns if any were missed
-- total_price was used in code but subtotal is in schema.
-- We fixed the code to use subtotal, so no change needed here 
-- unless we want to rename it. Keeping subtotal as per schema.
