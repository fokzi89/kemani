-- Check which tables have tenant_id column
SELECT
  table_name,
  column_name,
  data_type,
  '✅ HAS tenant_id' as status
FROM information_schema.columns
WHERE table_schema = 'public'
  AND column_name = 'tenant_id'
  AND table_name IN (
    'customer_addresses', 'subscriptions', 'commissions', 'receipts',
    'transfer_items', 'chat_messages', 'ecommerce_products',
    'dim_date', 'dim_time', 'spatial_ref_sys'
  )
ORDER BY table_name;
