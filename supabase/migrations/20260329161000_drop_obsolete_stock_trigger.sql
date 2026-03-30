-- Drop the obsolete trigger that tries to sync stock to the 'products' table
DROP TRIGGER IF EXISTS auto_sync_product_stock ON branch_inventory;

-- Drop the underlying obsolete function since the 'products' table no longer tracks stock
DROP FUNCTION IF EXISTS trigger_sync_product_stock();
