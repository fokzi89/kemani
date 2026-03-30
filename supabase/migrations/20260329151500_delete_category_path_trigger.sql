-- Delete Category Path Trigger and Function
-- Transitioning to manual path generation in the application layer
-- Date: 2026-03-29

DROP TRIGGER IF EXISTS trg_update_category_path ON categories;
DROP FUNCTION IF EXISTS update_category_path();
