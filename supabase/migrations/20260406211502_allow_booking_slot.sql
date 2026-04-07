-- Allow authenticated users (patients) to insert provider time slots for booking
-- Also ensure they can reserve a slot
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'provider_time_slots' 
        AND policyname = 'Authenticated users can create slots'
    ) THEN
        CREATE POLICY "Authenticated users can create slots"
            ON provider_time_slots FOR INSERT
            WITH CHECK (auth.uid() IS NOT NULL);
    END IF;
END $$;
