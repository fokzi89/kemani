-- Migration: Prescription Commissions
-- Tracks fees for freelance pharmacist consultations

ALTER TABLE public.prescriptions 
ADD COLUMN IF NOT EXISTS is_freelance BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS commission_rate DECIMAL(5,4) DEFAULT 0.0550, -- 5.5%
ADD COLUMN IF NOT EXISTS platform_fee_rate DECIMAL(5,4) DEFAULT 0.0100, -- 1.0%
ADD COLUMN IF NOT EXISTS medic_payout_rate DECIMAL(5,4) DEFAULT 0.0450; -- 4.5%

COMMENT ON COLUMN public.prescriptions.is_freelance IS 'True if issued by a freelance pharmacist, triggering the 5.5% fee.';
COMMENT ON COLUMN public.prescriptions.commission_rate IS 'Total prescription fee rate (e.g., 0.0550 for 5.5%).';
COMMENT ON COLUMN public.prescriptions.platform_fee_rate IS 'Platform share of the commission (e.g., 0.0100 for 1%).';
COMMENT ON COLUMN public.prescriptions.medic_payout_rate IS 'Medic share of the commission (e.g., 0.0450 for 4.5%).';
