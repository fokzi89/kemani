# Supabase Setup Guide

Complete guide to setting up Supabase for the Kemani multi-platform monorepo.

## Table of Contents

1. [Create Supabase Project](#1-create-supabase-project)
2. [Run Database Migrations](#2-run-database-migrations)
3. [Configure Environment Variables](#3-configure-environment-variables)
4. [Verify Setup](#4-verify-setup)
5. [Create Test Users](#5-create-test-users)
6. [Database Schema Overview](#database-schema-overview)
7. [Troubleshooting](#troubleshooting)

---

## 1. Create Supabase Project

### Step 1.1: Sign Up / Log In

1. Go to https://supabase.com
2. Click **"Start your project"** or **"Sign In"**
3. Sign up with GitHub, GitLab, or email

### Step 1.2: Create New Project

1. Click **"New Project"**
2. Select your organization (or create one)
3. Fill in project details:
   - **Name:** `kemani` (or your preferred name)
   - **Database Password:** Generate a strong password (save it!)
   - **Region:** Choose closest to your users
   - **Pricing Plan:** Start with Free tier

4. Click **"Create new project"**
5. Wait 2-3 minutes for provisioning

### Step 1.3: Get API Credentials

Once your project is ready:

1. Go to **Project Settings** (gear icon) → **API**
2. Copy these values:
   - **Project URL** → This is your `SUPABASE_URL`
   - **anon public** key → This is your `SUPABASE_ANON_KEY`
   - **service_role** key → This is your `SUPABASE_SERVICE_ROLE_KEY` (keep secret!)

**⚠️ SECURITY WARNING:**
- ✅ **anon key** - Safe to use in client apps (SvelteKit, Flutter)
- ❌ **service_role key** - NEVER expose in client code, only use in backend/scripts

---

## 2. Run Database Migrations

You have **3 options** to apply migrations. Choose the one that works best for you.

### Option A: Supabase CLI (Recommended)

**Prerequisites:** Install Supabase CLI

```bash
# Install via npm
npm install -g supabase

# Or via Scoop (Windows)
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

**Steps:**

```bash
# 1. Navigate to project root
cd C:\Users\AFOKE\kemani

# 2. Link to your Supabase project
supabase link --project-ref YOUR_PROJECT_REF

# To find PROJECT_REF: https://supabase.com/dashboard/project/YOUR_PROJECT/settings/general
# It's in the "Reference ID" field

# 3. Push migrations
supabase db push

# 4. Verify
supabase db diff --use-migra
```

### Option B: PowerShell Script (Combined SQL)

**Steps:**

```powershell
# 1. Navigate to project root
cd C:\Users\AFOKE\kemani

# 2. Run the PowerShell script
.\supabase\apply_migrations.ps1

# This will:
# - Combine all 30 migration files into one
# - Create: supabase/combined_migration.sql
# - Open the file automatically

# 3. Copy the entire contents of combined_migration.sql

# 4. Go to Supabase Dashboard:
#    https://supabase.com/dashboard/project/YOUR_PROJECT/sql

# 5. Click "New query" → Paste → Click "Run"

# 6. Wait for completion (may take 1-2 minutes)
```

### Option C: Manual Application (Individual Files)

**Steps:**

1. Open Supabase Dashboard → **SQL Editor**
2. Click **"New query"**
3. Apply migrations in this **exact order:**

```
migrations/
├── 001_extensions_and_enums.sql          # PostgreSQL extensions & enums
├── 002_core_tables.sql                   # Core tables (tenants, users)
├── 003_product_inventory_tables.sql      # Products & inventory
├── 004_customer_sales_tables.sql         # Customers & sales
├── 005_order_delivery_tables.sql         # Orders & deliveries
├── 006_additional_tables.sql             # Additional features
├── 007_indexes.sql                       # Performance indexes
├── 008_rls_policies.sql                  # Row-Level Security
├── 009_triggers.sql                      # Database triggers
├── 010_analytics_schema.sql              # Analytics tables
├── 011_analytics_indexes_partitions.sql  # Analytics optimization
├── 012_analytics_etl_functions.sql       # ETL functions
├── 013_analytics_seed_dimensions.sql     # Seed data
├── 014_enhance_sales_table.sql           # Sales enhancements
├── 015_enhance_sale_items_table.sql      # Sale items enhancements
├── 016_create_brands_categories.sql      # Brands & categories
├── 017_analytics_dimensions.sql          # Analytics dimensions
├── 018_analytics_fact_tables.sql         # Fact tables
├── 019_rls_helper_functions.sql          # RLS helper functions
├── 020_enable_rls_policies.sql           # Enable RLS
├── 021_add_tenant_id_to_sale_items.sql   # Tenant scoping
├── 022_seed_data.sql                     # Sample data (optional)
├── 023_chat_enhancements.sql             # Chat features (optional)
├── 024_ecommerce_enhancements.sql        # E-commerce features (optional)
├── 20260125_add_missing_rls_policies.sql # Additional RLS
├── 20260125001_create_missing_tables.sql # Missing tables
├── 20260222194504_healthcare_consultation.sql  # Healthcare system ✅
└── 20260223_tenant_scoped_products.sql   # Tenant products ✅
```

**For each file:**
1. Copy the contents
2. Paste into SQL Editor
3. Click **"Run"**
4. Wait for success message
5. Move to next file

---

## 3. Configure Environment Variables

### 3.1 Root Environment (Optional)

Update `.env` in project root (if needed for scripts):

```bash
cd C:\Users\AFOKE\kemani
cp .env.example .env
```

Edit `.env`:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJxxx...
SUPABASE_SERVICE_ROLE_KEY=eyJxxx...
```

### 3.2 Healthcare Customer App (SvelteKit)

```bash
cd apps/healthcare_customer
cp .env.example .env
```

Edit `.env`:
```env
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=eyJxxx...
```

**Note:** SvelteKit requires `PUBLIC_` prefix for client-side variables.

### 3.3 POS Admin App (Flutter)

**Option 1: Command-line (Recommended)**

No .env file needed. Pass credentials when running:

```bash
cd apps/pos_admin
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJxxx...
```

**Option 2: Edit main.dart**

Edit `apps/pos_admin/lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'https://your-project.supabase.co',
  anonKey: 'eyJxxx...',
);
```

### 3.4 Healthcare Medic App (Flutter)

Same as POS Admin. Choose Option 1 or 2 above.

---

## 4. Verify Setup

### 4.1 Check Database Tables

1. Go to Supabase Dashboard → **Table Editor**
2. Verify these tables exist:

**Multi-Tenant POS:**
- ✅ `tenants`
- ✅ `users`
- ✅ `products`
- ✅ `inventory`
- ✅ `sales`
- ✅ `sale_items`
- ✅ `receipts`
- ✅ `staff`
- ✅ `brands`
- ✅ `categories`

**Healthcare System:**
- ✅ `healthcare_providers`
- ✅ `patients`
- ✅ `consultations`
- ✅ `consultation_notes`
- ✅ `appointments`
- ✅ `provider_availability_templates`
- ✅ `provider_time_slots`
- ✅ `patient_health_records`

### 4.2 Check Row-Level Security (RLS)

1. Go to **Authentication** → **Policies**
2. Verify RLS is enabled on all tables
3. Check that policies exist for:
   - `SELECT` (read)
   - `INSERT` (create)
   - `UPDATE` (modify)
   - `DELETE` (remove)

### 4.3 Test Connection from Apps

**Test Healthcare Customer App:**

```bash
cd apps/healthcare_customer
npm install
npm run dev
# Open http://localhost:5173
# You should see the dashboard (no errors in console)
```

**Test POS Admin App:**

```bash
cd apps/pos_admin
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-key
# You should see the login screen
```

---

## 5. Create Test Users

### 5.1 Create Users via Dashboard

1. Go to **Authentication** → **Users**
2. Click **"Add user"** → **"Create new user"**

Create at least 3 test users:

**Test User 1: Tenant Owner (POS)**
- Email: `owner@example.com`
- Password: `TestPassword123!`
- Auto Confirm User: ✅ Yes
- Metadata (optional):
  ```json
  {
    "role": "owner",
    "full_name": "John Owner"
  }
  ```

**Test User 2: Healthcare Provider (Medic)**
- Email: `doctor@example.com`
- Password: `TestPassword123!`
- Auto Confirm User: ✅ Yes
- Metadata:
  ```json
  {
    "role": "provider",
    "full_name": "Dr. Jane Smith"
  }
  ```

**Test User 3: Patient (Customer)**
- Email: `patient@example.com`
- Password: `TestPassword123!`
- Auto Confirm User: ✅ Yes
- Metadata:
  ```json
  {
    "role": "patient",
    "full_name": "Alice Patient"
  }
  ```

### 5.2 Create Associated Records

After creating users, you need to create associated records in the database.

**For Tenant Owner (POS):**

Go to **SQL Editor** and run:

```sql
-- 1. Create tenant
INSERT INTO tenants (id, business_name, email, country, plan_tier)
VALUES (
  'c7b3d8f0-5c5f-4c1d-8c3f-8f3f5f3f5f3f',
  'Test Business',
  'owner@example.com',
  'Nigeria',
  'pro'
);

-- 2. Link user to tenant (update with actual user UUID from Auth > Users)
UPDATE auth.users
SET raw_user_meta_data = raw_user_meta_data || jsonb_build_object('tenant_id', 'c7b3d8f0-5c5f-4c1d-8c3f-8f3f5f3f5f3f')
WHERE email = 'owner@example.com';
```

**For Healthcare Provider:**

```sql
-- Create healthcare provider profile (update user_id with actual UUID)
INSERT INTO healthcare_providers (
  user_id,
  full_name,
  slug,
  email,
  type,
  specialization,
  country,
  fees,
  is_verified,
  is_active
)
VALUES (
  'PASTE_DOCTOR_USER_UUID_HERE',
  'Dr. Jane Smith',
  'dr-jane-smith',
  'doctor@example.com',
  'doctor',
  'General Medicine',
  'Nigeria',
  '{"chat": 5000, "video": 10000}'::jsonb,
  TRUE,
  TRUE
);
```

**For Patient:**

```sql
-- Create patient record (update user_id with actual UUID)
INSERT INTO patients (
  user_id,
  full_name,
  email,
  phone,
  date_of_birth,
  country
)
VALUES (
  'PASTE_PATIENT_USER_UUID_HERE',
  'Alice Patient',
  'patient@example.com',
  '+2348012345678',
  '1990-01-15',
  'Nigeria'
);
```

---

## Database Schema Overview

### Multi-Tenant POS System

**Core Tables:**
- `tenants` - Businesses using the POS system
- `users` - User accounts (linked to auth.users)
- `staff` - Staff members per tenant

**Product Management:**
- `products` - Product catalog
- `brands` - Product brands
- `categories` - Product categories
- `inventory` - Stock levels and tracking

**Sales:**
- `sales` - Transaction headers
- `sale_items` - Transaction line items
- `receipts` - Printable receipts

**Analytics:**
- Multiple dimension and fact tables for reporting

**Key Features:**
- Row-Level Security (RLS) enforces tenant isolation
- All tables have `tenant_id` for multi-tenancy
- Automated triggers for stock updates
- Denormalized fields for performance

### Healthcare Consultation System

**Core Tables:**
- `healthcare_providers` - Doctors, pharmacists, specialists
- `patients` - Patient records
- `consultations` - Consultation sessions
- `consultation_notes` - Session notes and diagnoses
- `appointments` - Scheduled appointments

**Scheduling:**
- `provider_availability_templates` - Recurring schedules
- `provider_time_slots` - Bookable time slots

**Medical Records:**
- `patient_health_records` - Health history and vitals

**Key Features:**
- Multi-domain branding support (custom clinics)
- Referral tracking for commission attribution
- Optimistic locking for slot booking
- Auto-expiration for prescriptions
- 35+ performance indexes

---

## Troubleshooting

### Issue: "relation does not exist" error

**Cause:** Migrations not applied or applied out of order

**Solution:**
1. Check SQL Editor history for errors
2. Re-apply failed migration
3. Ensure migrations applied in order (001 → 030)

### Issue: "permission denied for table" error

**Cause:** RLS policies not configured correctly

**Solution:**
1. Check **Authentication** → **Policies**
2. Ensure RLS is enabled on the table
3. Verify policies allow your operation
4. Check if user has required claims/metadata

### Issue: Cannot connect from app

**Cause:** Wrong credentials or CORS issue

**Solution:**
1. Verify `SUPABASE_URL` is correct (no trailing slash)
2. Verify `SUPABASE_ANON_KEY` is the anon public key (not service_role)
3. Check browser console for detailed error
4. Verify Supabase project is active (not paused)

### Issue: "JWT expired" or "Invalid token"

**Cause:** Expired session or wrong JWT secret

**Solution:**
1. Clear browser cookies/localStorage
2. Sign out and sign in again
3. Verify anon key is correct
4. Check if user exists in Authentication > Users

### Issue: Flutter app won't build

**Cause:** Missing dependencies or Flutter SDK issue

**Solution:**
```bash
flutter clean
flutter pub get
flutter doctor
```

### Issue: SvelteKit "Cannot find module"

**Cause:** Missing dependencies or wrong import

**Solution:**
```bash
rm -rf node_modules package-lock.json
npm install
```

### Issue: User can see data from other tenants

**Cause:** RLS policies not enforcing tenant isolation

**Solution:**
1. Check user metadata has `tenant_id`
2. Verify RLS policies filter by `tenant_id`
3. Run this to check user metadata:
   ```sql
   SELECT id, email, raw_user_meta_data
   FROM auth.users
   WHERE email = 'your-email@example.com';
   ```
4. Update if missing:
   ```sql
   UPDATE auth.users
   SET raw_user_meta_data = raw_user_meta_data || '{"tenant_id": "YOUR_TENANT_ID"}'::jsonb
   WHERE email = 'your-email@example.com';
   ```

---

## Next Steps

1. ✅ **Supabase project created**
2. ✅ **Migrations applied**
3. ✅ **Environment configured**
4. ✅ **Test users created**

**Now you can:**
- Start developing features in your apps
- Test authentication flows
- Build out UI screens
- Add business logic

**Recommended Next Steps:**
1. Follow [QUICK_START.md](./QUICK_START.md) to run apps locally
2. Review [ARCHITECTURE.md](./ARCHITECTURE.md) for architecture details
3. Read app-specific READMEs in `apps/*/README.md`

---

## Useful Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [Row-Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)
- [SvelteKit + Supabase](https://supabase.com/docs/guides/getting-started/tutorials/with-sveltekit)
- [Flutter + Supabase](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)

## Support

For issues:
1. Check [Troubleshooting](#troubleshooting) section above
2. Review Supabase Dashboard logs
3. Check browser console errors
4. Review individual app READMEs
