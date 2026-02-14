-- ============================================================
-- Migration: Auth Trigger for User Registration
-- Feature: Flutter Migration - Auth
-- Date: 2026-02-13
-- ============================================================
-- Purpose: Automate Tenant, User, and Branch creation on sign-up
-- This replaces the Next.js API 'register' logic.
-- ============================================================

-- CLEANUP: Remove any old triggers/functions if they exist
-- This ensures a clean slate and avoids conflicts with previous Next.js associated logic
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_business_name TEXT;
    v_full_name TEXT;
    v_slug TEXT;
    v_tenant_id UUID;
    v_user_role TEXT;
BEGIN
    -- Extract metadata
    v_business_name := NEW.raw_user_meta_data->>'business_name';
    v_full_name := NEW.raw_user_meta_data->>'full_name';
    v_user_role := NEW.raw_user_meta_data->>'role';

    -- Only proceed if business_name is present (indicates a new tenant registration)
    -- If adding a staff member to existing tenant, logic might differ (handled by invite)
    IF v_business_name IS NOT NULL THEN
        
        -- 1. Generate Slug
        v_slug := lower(regexp_replace(v_business_name, '[^a-zA-Z0-9]', '-', 'g'));
        -- Append timestamp to ensure uniqueness roughly
        v_slug := v_slug || '-' || floor(extract(epoch from now()));

        -- 2. Create Tenant
        INSERT INTO public.tenants (name, slug, email)
        VALUES (v_business_name, v_slug, NEW.email)
        RETURNING id INTO v_tenant_id;

        -- 3. Create User Profile
        INSERT INTO public.users (id, tenant_id, full_name, role, email)
        VALUES (
            NEW.id, 
            v_tenant_id, 
            COALESCE(v_full_name, 'Admin'), 
            'tenant_admin', -- Default role for new business owner
            NEW.email
        );

        -- 4. Create Default Branch
        INSERT INTO public.branches (tenant_id, name, business_type)
        VALUES (v_tenant_id, v_business_name || ' - Main Branch', 'supermarket'); -- Default type

        -- 5. Create Subscription (Free Tier)
        -- Assuming a default subscription handling or trigger elsewhere, 
        -- but for now we ensure tenant is created. 
        -- (Optional: Insert into subscriptions if needed explicitly)

    ELSE
        -- Fallback: If no business name, check if it's an invited user (e.g., via metadata)
        -- Logic for invited users would typically be: 
        --   - Check for invite token or pre-assigned tenant_id in metadata?
        --   - Or the user is created via Supabase Auth Admin and public.users entry is made manually.
        -- For now, we strictly focus on Tenant Registration flow to replace the API route.
        NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
