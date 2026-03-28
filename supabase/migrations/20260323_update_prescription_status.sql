-- Drop the constraint that prevents 'draft'
ALTER TABLE prescriptions DROP CONSTRAINT IF EXISTS prescriptions_status_check;

-- Add it back with the 'draft' option
ALTER TABLE prescriptions 
ADD CONSTRAINT prescriptions_status_check 
CHECK (status IN ('draft', 'active', 'expired', 'fulfilled', 'cancelled'));
