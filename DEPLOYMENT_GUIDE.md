# Database Migration & Security Fix Deployment Guide

**Date:** 2026-01-25
**Purpose:** Apply all database fixes and migrations to Supabase

---

## ⚠️ CRITICAL: Read This First

This deployment will:
1. ✅ Enable RLS on 10 unrestricted tables (SECURITY FIX)
2. ✅ Create 5 missing tables
3. ✅ Update TypeScript types to match database
4. ✅ Add comprehensive documentation

**Estimated Time:** 15-20 minutes
**Downtime:** None (migrations are additive)

---

## Pre-Deployment Checklist

- [ ] Backup database (Settings → Database → Backups)
- [ ] Review all migration files
- [ ] Notify team of deployment
- [ ] Test in development first (if you have a dev instance)
- [ ] Have rollback plan ready

---

## Step 1: Backup Your Database (5 minutes)

### Option A: Supabase Dashboard
1. Go to https://supabase.com/dashboard/project/ykbpznoqebhopyqpoqaf
2. Click **Database** → **Backups**
3. Click **Create Backup Now**
4. Wait for backup to complete
5. Note the backup ID

### Option B: Command Line (if Supabase CLI installed)
```bash
supabase db dump --project-id ykbpznoqebhopyqpoqaf > backup-$(date +%Y%m%d).sql
```

---

## Step 2: Apply RLS Security Migration (3 minutes)

This is **CRITICAL** - it fixes the multi-tenant security vulnerability.

### Apply Migration

1. Open Supabase SQL Editor:
   https://supabase.com/dashboard/project/ykbpznoqebhopyqpoqaf/sql

2. Copy contents of:
   `supabase/migrations/20260125_add_missing_rls_policies.sql`

3. Paste into SQL Editor

4. Click **Run**

5. Verify no errors

### Verify RLS Applied

Run this query:
```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'customer_addresses', 'subscriptions', 'commissions', 'receipts',
    'transfer_items', 'chat_messages', 'ecommerce_products',
    'dim_date', 'dim_time', 'spatial_ref_sys'
  );
```

**Expected:** All should show `rowsecurity = true`

---

## Step 3: Create Missing Tables (3 minutes)

Add the 5 missing tables to your database.

### Apply Migration

1. Open Supabase SQL Editor

2. Copy contents of:
   `supabase/migrations/20260125_create_missing_tables.sql`

3. Paste into SQL Editor

4. Click **Run**

5. Verify no errors

### Verify Tables Created

Run this query:
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'staff_invites', 'product_variants', 'invoices',
    'sync_logs', 'audit_logs'
  )
ORDER BY table_name;
```

**Expected:** All 5 tables should be listed

---

## Step 4: Verify RLS Policies (5 minutes)

Run comprehensive verification to ensure security is working.

### Run Verification Script

1. Open Supabase SQL Editor

2. Copy contents of:
   `scripts/verify-rls-policies.sql`

3. Run each section separately

4. Review results for any ❌ or ⚠️ warnings

### Critical Checks

**Check 1: All tables have RLS enabled**
```sql
SELECT tablename FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = false;
```
**Expected:** 0 rows (or only migration/system tables)

**Check 2: All tables have policies**
```sql
SELECT t.tablename
FROM pg_tables t
WHERE t.schemaname = 'public'
  AND t.rowsecurity = true
  AND NOT EXISTS (
    SELECT 1 FROM pg_policies p
    WHERE p.tablename = t.tablename
  );
```
**Expected:** 0 rows

**Check 3: Tenant isolation exists**
```sql
SELECT COUNT(DISTINCT tablename)
FROM pg_policies
WHERE qual::text LIKE '%tenant_id%';
```
**Expected:** 30+ tables (most tables should have tenant isolation)

---

## Step 5: Update TypeScript Types (2 minutes)

Update your codebase to include types for all 40 tables.

### Option A: Using Supabase CLI (Recommended)

```bash
supabase gen types typescript --project-id ykbpznoqebhopyqpoqaf > types/database.types.ts
```

### Option B: Using npx

```bash
npx supabase@latest gen types typescript --project-id ykbpznoqebhopyqpoqaf > types/database.types.ts
```

### Option C: Manual Download

1. Go to: https://supabase.com/dashboard/project/ykbpznoqebhopyqpoqaf/api
2. Scroll to "Type Definitions"
3. Click "TypeScript"
4. Copy generated types
5. Paste into `types/database.types.ts`

### Verify Types Updated

Check the file:
```bash
wc -l types/database.types.ts
```

**Expected:** 500+ lines (was ~200 before)

---

## Step 6: Restart Development Server (1 minute)

```bash
# Stop current server (Ctrl+C)

# Clear Next.js cache
rm -rf .next

# Restart
npm run dev
```

---

## Step 7: Test Database Access (5 minutes)

### Test 1: Basic Queries

Create a test API route:
```typescript
// app/api/test-db/route.ts
import { createClient } from '@/lib/supabase/server';

export async function GET() {
  const supabase = createClient();

  // Test new tables
  const { data: invites, error: invitesError } = await supabase
    .from('staff_invites')
    .select('*')
    .limit(1);

  const { data: variants, error: variantsError } = await supabase
    .from('product_variants')
    .select('*')
    .limit(1);

  return Response.json({
    staff_invites: { data: invites, error: invitesError },
    product_variants: { data: variants, error: variantsError },
  });
}
```

Visit: http://localhost:3000/api/test-db

**Expected:** No TypeScript errors, queries execute (even if no data)

### Test 2: RLS Isolation

Test that tenant isolation works:

```typescript
// This should ONLY return data for the current user's tenant
const { data } = await supabase.from('products').select('*');
```

**Expected:** Only your tenant's products, not all tenants

---

## Post-Deployment Verification

### Checklist

- [ ] All migrations applied successfully
- [ ] No SQL errors in Supabase logs
- [ ] RLS enabled on all tables
- [ ] All tables have policies
- [ ] TypeScript types updated
- [ ] No TypeScript errors in codebase
- [ ] Development server starts successfully
- [ ] Database queries work
- [ ] Tenant isolation verified

---

## Rollback Plan (Emergency Only)

If something goes wrong:

### Option 1: Restore from Backup

1. Go to Supabase Dashboard → Backups
2. Find today's backup
3. Click **Restore**
4. Wait for restoration

### Option 2: Disable RLS (Temporary)

```sql
-- ONLY IF EMERGENCY - This removes security!
ALTER TABLE customer_addresses DISABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions DISABLE ROW LEVEL SECURITY;
-- ... etc for other tables
```

### Option 3: Drop New Tables

```sql
-- Remove newly created tables
DROP TABLE IF EXISTS staff_invites CASCADE;
DROP TABLE IF EXISTS product_variants CASCADE;
DROP TABLE IF EXISTS invoices CASCADE;
DROP TABLE IF EXISTS sync_logs CASCADE;
DROP TABLE IF EXISTS audit_logs CASCADE;
```

---

## Troubleshooting

### Issue: RLS blocks all access

**Symptom:** Queries return empty even though data exists

**Cause:** RLS policies too restrictive or JWT missing tenant_id

**Fix:**
1. Check JWT contains tenant_id claim:
   ```sql
   SELECT auth.jwt() ->> 'tenant_id';
   ```

2. If null, update auth hook to set tenant_id

3. Temporarily check as superuser:
   ```sql
   SELECT * FROM products; -- As superuser in SQL Editor
   ```

### Issue: TypeScript errors after type update

**Symptom:** "Property does not exist on type Database"

**Cause:** Cached TypeScript server

**Fix:**
1. Restart VS Code TypeScript server: Cmd/Ctrl+Shift+P → "Restart TS Server"
2. Clear node_modules and reinstall:
   ```bash
   rm -rf node_modules .next
   npm install
   ```

### Issue: Migration fails partway through

**Symptom:** Some tables created, others failed

**Cause:** SQL error in migration

**Fix:**
1. Check Supabase logs for exact error
2. Fix the failing SQL statement
3. Remove successfully created tables
4. Re-run migration

---

## Success Criteria

✅ **Security:**
- All 40 tables have RLS enabled
- All tenant-scoped tables have tenant_id policies
- No cross-tenant data leaks

✅ **Functionality:**
- All 40 tables accessible from code
- TypeScript types match database
- No TypeScript errors

✅ **Performance:**
- No significant query slowdowns
- Indexes on tenant_id exist
- Dimension tables readable by all

---

## Next Steps After Deployment

1. **Monitor Logs:**
   - Watch for RLS-related errors
   - Check query performance

2. **Update Documentation:**
   - Mark this deployment as complete
   - Update data model docs

3. **Team Communication:**
   - Notify team of new tables
   - Share updated TypeScript types
   - Document new RLS policies

4. **Future Work:**
   - Set up automated RLS testing
   - Add more comprehensive audit logging
   - Optimize analytics queries

---

## Support

**Issues?** Check:
- Supabase Logs: https://supabase.com/dashboard/project/ykbpznoqebhopyqpoqaf/logs
- Database Health: https://supabase.com/dashboard/project/ykbpznoqebhopyqpoqaf/reports

**Questions?** Review:
- `reports/actual-table-comparison.md` - Full table analysis
- `specs/001-multi-tenant-pos/data-model-addendum.md` - Extra tables documentation
- `scripts/verify-rls-policies.sql` - Verification queries

---

**Deployment Prepared:** 2026-01-25
**Ready to Deploy:** Yes ✅
