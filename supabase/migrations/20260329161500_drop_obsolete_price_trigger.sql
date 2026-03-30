-- Since pricing has migrated off the global 'products' table and into 'branch_inventory',
-- the legacy trigger tracking price changes directly on the 'products' table crashes
-- whenever any product is updated because the 'selling_price'/'unit_price' fields are gone.

-- Drop the obsolete trigger from the 'products' table
DROP TRIGGER IF EXISTS trg_track_product_price_change ON products;

-- Optionally, drop the obsolete function that caused the crash
DROP FUNCTION IF EXISTS track_product_price_change();
