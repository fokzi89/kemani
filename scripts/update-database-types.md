# Update Database Types from Supabase

## Option 1: Using Supabase CLI (Recommended)

If you have Supabase CLI installed:

```bash
supabase gen types typescript --project-id ykbpznoqebhopyqpoqaf > types/database.types.ts
```

## Option 2: Using npx (One-time)

```bash
npx supabase@latest gen types typescript --project-id ykbpznoqebhopyqpoqaf > types/database.types.ts
```

## Option 3: Using Supabase Dashboard

1. Go to: https://supabase.com/dashboard/project/ykbpznoqebhopyqpoqaf/api
2. Scroll to "Generate Types" section
3. Select "TypeScript"
4. Click "Generate and Download"
5. Replace `types/database.types.ts` with downloaded file

## Option 4: Using API Directly

```bash
curl "https://api.supabase.com/v1/projects/ykbpznoqebhopyqpoqaf/types/typescript" \
  -H "Authorization: Bearer YOUR_SUPABASE_ACCESS_TOKEN" \
  > types/database.types.ts
```

## What This Does

This command will:
- Connect to your Supabase project
- Read the entire database schema (all 40 tables)
- Generate TypeScript interfaces for:
  - All table row types
  - Insert types (with defaults optional)
  - Update types (all fields optional)
  - Enums
  - Functions
  - Views

## After Running

Your `types/database.types.ts` will include types for all 40 tables:

- Core: tenants, users, branches, brands, categories, products
- Sales: sales, sale_items, inventory_transactions
- Customers: customers, customer_addresses
- Orders: orders, order_items
- Delivery: deliveries, riders
- Staff: staff_attendance
- Chat: chat_conversations, chat_messages
- E-commerce: ecommerce_connections, ecommerce_products
- Messaging: whatsapp_messages
- Transfers: inter_branch_transfers, transfer_items
- Monetization: subscriptions, commissions, receipts
- **Analytics: fact_brand_sales, fact_daily_sales, fact_hourly_sales, fact_product_sales, fact_staff_sales**
- **Dimensions: dim_date, dim_time**
- PostGIS: geography_columns, geometry_columns, spatial_ref_sys
- Price tracking: product_price_history

## Current Status

Your current `types/database.types.ts` only has 7 tables.
After updating, it will have all 40 tables!

## Next Steps

After generating new types:

1. Restart your TypeScript server
2. Fix any type errors in your code
3. Update Supabase client calls to use new table names
4. Test all database operations

## Verification

To verify the update worked:

```typescript
import { Database } from '@/types/database.types';

// Should have all these tables:
type Tables = Database['public']['Tables'];
type AllTables = keyof Tables;

// This should now include 40+ table names
const tableCount = Object.keys({} as Tables).length;
console.log(`Total tables: ${tableCount}`); // Should be ~40
```
