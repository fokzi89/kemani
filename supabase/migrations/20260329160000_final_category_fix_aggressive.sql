-- Aggressive cleanup and restoration of Category Path Trigger
-- This script ensures no old versions of the trigger or function remain.
-- Date: 2026-03-29

-- 1. Correct the table schema aggressively (ensure no old columns remain)
DO $$ 
BEGIN 
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'categories' AND column_name = 'code') THEN
        ALTER TABLE public.categories DROP COLUMN code;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'categories' AND column_name = 'description') THEN
        ALTER TABLE public.categories DROP COLUMN description;
    END IF;
END $$;

-- 2. Drop the trigger from the table aggressively
DROP TRIGGER IF EXISTS trg_update_category_path ON public.categories CASCADE;

-- 2. Drop the function with a cascade to remove any dependent objects
DROP FUNCTION IF EXISTS public.update_category_path() CASCADE;

-- 3. Redefine the function cleanly with the NEW flat schema logic
-- Note: NEW.name and NEW.path must exist for this to work.
CREATE OR REPLACE FUNCTION public.update_category_path()
RETURNS TRIGGER AS $$
BEGIN
    -- Log for debugging (found in Supabase logs)
    -- RAISE NOTICE 'Generating path for category: %', NEW.name;
    
    NEW.path := '/' || LOWER(REGEXP_REPLACE(NEW.name, '[^a-zA-Z0-9]+', '-', 'g')) || '/';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Re-create the trigger on the table
CREATE TRIGGER trg_update_category_path
    BEFORE INSERT OR UPDATE ON public.categories
    FOR EACH ROW
    EXECUTE FUNCTION public.update_category_path();

-- 5. Ensure RLS is still open as requested
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view categories" ON public.categories;
CREATE POLICY "Public can view categories" ON public.categories FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can create categories" ON public.categories;
CREATE POLICY "Authenticated users can create categories" ON public.categories FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can update categories" ON public.categories;
CREATE POLICY "Authenticated users can update categories" ON public.categories FOR UPDATE USING (auth.uid() IS NOT NULL);
