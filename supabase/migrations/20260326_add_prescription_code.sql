-- Add prescription_code to prescriptions table
ALTER TABLE prescriptions ADD COLUMN IF NOT EXISTS prescription_code TEXT;

-- Update the check constraint if we want it to be unique or have a specific format in the future, 
-- but for now just adding the column.
