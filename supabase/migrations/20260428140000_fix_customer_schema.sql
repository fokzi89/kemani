-- Migration: Fix Customer Schema
-- Description: Adds missing columns to the customers table to match the POS frontend requirements.

ALTER TABLE public.customers
ADD COLUMN IF NOT EXISTS first_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS last_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS date_of_birth DATE,
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS loyalty_points INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_spent DECIMAL(12,2) DEFAULT 0;

-- Simple index for address search
CREATE INDEX IF NOT EXISTS idx_customers_address_search ON public.customers(address) WHERE address IS NOT NULL;

-- Trigger to automatically update full_name from first_name and last_name
CREATE OR REPLACE FUNCTION update_customer_full_name()
RETURNS TRIGGER AS $$
BEGIN
    NEW.full_name := TRIM(CONCAT(NEW.first_name, ' ', NEW.last_name));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_customer_full_name ON public.customers;
CREATE TRIGGER trigger_update_customer_full_name
    BEFORE INSERT OR UPDATE OF first_name, last_name ON public.customers
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_full_name();
