-- Fix Category Path Trigger Function
-- Removed references to non-existent parent_category_id and level columns
-- Date: 2026-03-29

CREATE OR REPLACE FUNCTION update_category_path()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate a clean slug-based path from the name
    NEW.path := '/' || LOWER(REGEXP_REPLACE(NEW.name, '[^a-zA-Z0-9]+', '-', 'g')) || '/';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Re-apply trigger to ensure it uses the latest function logic
DROP TRIGGER IF EXISTS trg_update_category_path ON categories;
CREATE TRIGGER trg_update_category_path
    BEFORE INSERT OR UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_category_path();
