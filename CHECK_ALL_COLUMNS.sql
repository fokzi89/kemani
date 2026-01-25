-- Check ALL columns in the 10 tables to see their structure
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN (
    'customer_addresses', 'subscriptions', 'commissions', 'receipts',
    'transfer_items', 'chat_messages', 'ecommerce_products',
    'dim_date', 'dim_time', 'spatial_ref_sys'
  )
ORDER BY table_name, ordinal_position;
