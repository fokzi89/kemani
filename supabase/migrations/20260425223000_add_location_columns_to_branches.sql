-- Add missing location columns to branches table
ALTER TABLE public.branches
ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,8) CHECK (latitude >= -90 AND latitude <= 90),
ADD COLUMN IF NOT EXISTS longitude DECIMAL(11,8) CHECK (longitude >= -180 AND longitude <= 180);

-- Also add state, city, country if they are somehow missing
ALTER TABLE public.branches
ADD COLUMN IF NOT EXISTS city VARCHAR(255),
ADD COLUMN IF NOT EXISTS state VARCHAR(255),
ADD COLUMN IF NOT EXISTS country VARCHAR(255);
