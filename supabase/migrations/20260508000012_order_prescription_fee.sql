-- Migration: Add Prescription Fee to Orders
-- Tracks the 5.5% commission for freelance pharmacist consultations

ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS prescription_fee DECIMAL(10,2) DEFAULT 0.00;

COMMENT ON COLUMN public.orders.prescription_fee IS 'Total fee for freelance pharmacist prescriptions (5.5%).';
