-- Check if parent tables have tenant_id column
SELECT
  table_name,
  column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('customers', 'sales', 'inter_branch_transfers', 'chat_conversations')
  AND column_name = 'tenant_id'
ORDER BY table_name;

-- Also check all columns in these parent tables
SELECT
  table_name,
  string_agg(column_name, ', ' ORDER BY ordinal_position) as columns
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('customers', 'sales', 'inter_branch_transfers', 'chat_conversations')
GROUP BY table_name
ORDER BY table_name;
