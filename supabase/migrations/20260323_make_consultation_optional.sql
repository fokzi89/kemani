-- Make consultation_id optional in prescriptions so providers can create 
-- direct prescriptions without an active consultation session.
ALTER TABLE prescriptions ALTER COLUMN consultation_id DROP NOT NULL;
