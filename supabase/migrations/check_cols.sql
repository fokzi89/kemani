DO $$
DECLARE
    col_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'branch_inventory' AND column_name = 'image_url'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        RAISE NOTICE 'image_url does not exist in branch_inventory';
    ELSE
        RAISE NOTICE 'image_url exists in branch_inventory';
    END IF;
END $$;
