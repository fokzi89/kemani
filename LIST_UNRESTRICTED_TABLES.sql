-- Step 1: Find which tables have RLS disabled
SELECT
  tablename as "Table Name",
  CASE WHEN rowsecurity THEN '✅ ENABLED' ELSE '❌ DISABLED' END as "RLS Status"
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = false
  AND tablename NOT LIKE '%migration%'
ORDER BY tablename;
