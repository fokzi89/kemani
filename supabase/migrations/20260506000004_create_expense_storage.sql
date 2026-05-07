-- ============================================================================
-- CREATE STORAGE BUCKET FOR EXPENSES
-- ============================================================================

-- Expense Documents Bucket (Private)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'expense-documents',
    'expense-documents',
    false, -- Private access
    5242880, -- 5MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- STORAGE RLS POLICIES
-- ============================================================================

-- POLICY: Staff can upload documents to their tenant's folder
-- Folder structure: /tenant_id/staff_id/filename.ext
DROP POLICY IF EXISTS "Staff can upload expense documents" ON storage.objects;
CREATE POLICY "Staff can upload expense documents"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'expense-documents' AND
        (storage.foldername(name))[1] IN (SELECT tenant_id::text FROM users WHERE id = auth.uid())
    );

-- POLICY: Users can view documents in their tenant
DROP POLICY IF EXISTS "Users can view tenant expense documents" ON storage.objects;
CREATE POLICY "Users can view tenant expense documents"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'expense-documents' AND
        (storage.foldername(name))[1] IN (SELECT tenant_id::text FROM users WHERE id = auth.uid())
    );

-- POLICY: Admins/Delegated Staff can delete documents in their tenant
DROP POLICY IF EXISTS "Admins can delete tenant expense documents" ON storage.objects;
CREATE POLICY "Admins can delete tenant expense documents"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'expense-documents' AND
        (storage.foldername(name))[1] IN (
            SELECT tenant_id::text FROM users 
            WHERE id = auth.uid() 
            AND (role = 'tenant_admin' OR can_manage_expenses = TRUE)
        )
    );
