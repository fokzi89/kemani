-- ============================================================================
-- FIX MISSING DELETE POLICY ON PRESCRIBED DRUGS
-- ============================================================================

-- Without a DELETE policy, the 'sync' logic (delete all then re-insert)
-- in the edit prescription page fails, resulting in duplicated entries.

ALTER TABLE prescribed_drugs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can delete prescribed drugs" ON prescribed_drugs;
CREATE POLICY "Authenticated users can delete prescribed drugs"
    ON prescribed_drugs FOR DELETE
    TO authenticated
    USING (true);
