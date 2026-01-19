# Database Migration Guide

This guide will help you apply the database schema to your Supabase project.

## Prerequisites

- Supabase account and project created
- Access to Supabase SQL Editor

## Migration Order

The schema has been split into 10 smaller migrations for easier application:

1. **001_extensions_and_enums.sql** - PostgreSQL extensions and custom types
2. **002_core_tables.sql** - Subscriptions, tenants, branches, users
3. **003_product_inventory_tables.sql** - Products, inventory, transfers
4. **004_customer_sales_tables.sql** - Customers, sales, receipts
5. **005_order_delivery_tables.sql** - Orders, deliveries, riders, attendance
6. **006_additional_tables.sql** - E-commerce, chat, commissions, WhatsApp
7. **007_indexes.sql** - Performance indexes
8. **008_rls_policies.sql** - Row Level Security policies
9. **009_triggers.sql** - Database triggers
10. **010_seed_data.sql** - Default subscription plans

## Step-by-Step Instructions

### Option 1: Apply via Supabase Dashboard (Recommended)

1. **Navigate to Supabase SQL Editor**
   - Go to https://app.supabase.com
   - Select your project
   - Click "SQL Editor" in the left sidebar

2. **Apply Migrations in Order**
   - For each migration file (001 through 010):
     - Click "New query"
     - Copy the entire contents of the migration file
     - Paste into the SQL editor
     - Click "Run" (or press Cmd/Ctrl + Enter)
     - Wait for "Success" message
     - Verify no errors in the output

3. **Verify Installation**
   - After completing all migrations, run:
     ```sql
     -- Check tables created
     SELECT table_name FROM information_schema.tables
     WHERE table_schema = 'public'
     ORDER BY table_name;

     -- Should return 23 tables

     -- Check subscription plans
     SELECT plan_tier, monthly_fee FROM subscriptions ORDER BY monthly_fee;

     -- Should return 4 subscription plans
     ```

### Option 2: Apply via Supabase CLI

If you have Supabase CLI installed:

```bash
# Link to your project
supabase link --project-ref your-project-ref

# Apply migrations
supabase db push

# Generate TypeScript types
supabase gen types typescript --linked > types/database.types.ts
```

### Option 3: Apply All at Once (Advanced)

If you prefer to apply all migrations at once, you can combine them:

```bash
# On Windows (PowerShell)
Get-Content supabase/migrations/*.sql | Out-File -FilePath combined_migration.sql

# Then copy combined_migration.sql content to Supabase SQL Editor
```

## After Migration

### 1. Generate TypeScript Types

```bash
npx supabase gen types typescript --linked > types/database.types.ts
```

### 2. Verify Tables Created

Run this query in SQL Editor:

```sql
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

Expected tables (23 total):
- branches
- chat_conversations
- chat_messages
- commissions
- customer_addresses
- customers
- deliveries
- ecommerce_connections
- inter_branch_transfers
- inventory_transactions
- order_items
- orders
- products
- receipts
- riders
- sale_items
- sales
- staff_attendance
- subscriptions
- tenants
- transfer_items
- users
- whatsapp_messages

### 3. Verify RLS Enabled

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND rowsecurity = true;
```

Should return 17 tables with RLS enabled.

### 4. Verify Triggers

```sql
SELECT trigger_name, event_object_table, action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public';
```

Should show multiple triggers for:
- update_updated_at
- increment_sync_version
- generate_sale_number
- create_commission
- update_customer_loyalty

### 5. Verify Indexes

```sql
SELECT indexname, tablename
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

Should show 50+ indexes.

## Troubleshooting

### Error: "extension postgis does not exist"

Some Supabase projects don't have PostGIS enabled. To fix:

1. Go to Supabase Dashboard → Database → Extensions
2. Enable "postgis" extension
3. Re-run migration 001

### Error: "type already exists"

If you've partially applied migrations and encounter "type already exists" errors:

```sql
-- Drop existing types (only if needed)
DROP TYPE IF EXISTS business_type CASCADE;
-- ... repeat for other types

-- Then re-run migration 001
```

### Error: "relation already exists"

If tables were partially created:

```sql
-- Drop all tables (⚠️ DESTROYS DATA)
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- Then re-run all migrations
```

### Connection Timeout

If you encounter timeouts:
- Apply migrations one at a time
- Wait a few seconds between each migration
- Use Supabase CLI instead of web interface

## Next Steps

After successful migration:

1. ✅ Update `.env.local` with Supabase credentials
2. ✅ Generate TypeScript types
3. ✅ Test database connection: `npm run dev`
4. ✅ Set up PowerSync sync rules
5. ✅ Configure authentication
6. ✅ Begin implementing user stories

## Support

If you encounter issues:
- Check Supabase logs: Database → Logs
- Review migration file syntax
- Ensure migrations applied in order (001 → 010)
- Contact Supabase support if database-level issues persist
