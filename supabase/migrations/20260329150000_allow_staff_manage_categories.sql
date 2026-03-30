-- Update Categories RLS to allow staff with POS management privileges to create categories
-- Date: 2026-03-29

DROP POLICY IF EXISTS "Managers can insert categories" ON categories;
CREATE POLICY "Managers and Staff can insert categories"
    ON categories FOR INSERT
    WITH CHECK (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND (role IN ('tenant_admin', 'branch_manager') OR canManagePOS = true)
        )
    );

DROP POLICY IF EXISTS "Managers can update categories" ON categories;
CREATE POLICY "Managers and Staff can update categories"
    ON categories FOR UPDATE
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND (role IN ('tenant_admin', 'branch_manager') OR canManagePOS = true)
        )
    );
