# User Story 2: Schema Fixes & RLS Verification Report

**Date**: 2026-02-27
**User Story**: US2 - Multi-Tenant Isolation and Email/Google Authentication
**Status**: ✅ Critical Fixes Completed, RLS Verified

---

## Executive Summary

Successfully fixed critical schema mismatch where country settings were incorrectly being saved to a non-existent `profiles` table instead of the `tenants` table. Also eliminated the confusion around `profiles` vs `users` table by consolidating user profile data into the `users` table.

**Key Changes:**
1. ✅ Added `country_code`, `dial_code`, `currency_code` to `tenants` table
2. ✅ Added `gender` field to `users` table
3. ✅ Updated all SupabaseService methods to use correct tables
4. ✅ Updated UI screens to pass country data correctly
5. ✅ Verified comprehensive RLS policies are in place

---

## 1. Schema Fixes Implemented

### Migration Created: `20260227_add_country_settings_to_tenants.sql`

**Location**: `C:\Users\AFOKE\kemani\supabase\migrations\20260227_add_country_settings_to_tenants.sql`

**Changes:**

#### Tenants Table (Country Settings)
```sql
ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS country_code VARCHAR(2),
ADD COLUMN IF NOT EXISTS dial_code VARCHAR(10),
ADD COLUMN IF NOT EXISTS currency_code VARCHAR(3);
```

**Constraints Added:**
- ✅ `country_code` must be ISO 3166-1 alpha-2 (e.g., "NG", "US")
- ✅ `dial_code` must be +[1-4 digits] (e.g., "+234", "+1")
- ✅ `currency_code` must be ISO 4217 (e.g., "NGN", "USD")
- ✅ Index on `country_code` for analytics queries

#### Users Table (Profile Settings)
```sql
ALTER TABLE users
ADD COLUMN IF NOT EXISTS gender VARCHAR(10);
```

**Constraints Added:**
- ✅ `gender` must be IN ('male', 'female', 'other') or NULL

---

## 2. SupabaseService Updates

### File: `apps/pos_admin/lib/services/supabase_service.dart`

#### Changed Methods:

**1. `updateCountrySettings()` - NOW SAVES TO TENANTS TABLE**

**Before (INCORRECT):**
```dart
Future<void> updateCountrySettings({
  required String userId,  // ❌ Used user ID
  ...
}) async {
  await _client.from('profiles').update({  // ❌ Non-existent table
    ...
  }).eq('user_id', userId);  // ❌ Wrong filter
}
```

**After (CORRECT):**
```dart
Future<void> updateCountrySettings({
  required String tenantId,  // ✅ Uses tenant ID
  ...
}) async {
  await _client.from('tenants').update({  // ✅ Correct table
    'country_code': countryCode,
    'currency_code': currencyCode,
    'dial_code': dialCode,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', tenantId);  // ✅ Correct filter
}
```

**2. `createBusiness()` - NOW ACCEPTS COUNTRY PARAMETERS**

```dart
Future<String> createBusiness({
  ...
  String? countryCode,    // ✅ New parameter
  String? dialCode,       // ✅ New parameter
  String? currencyCode,   // ✅ New parameter
}) async {
  final insertData = {...};

  // Add country settings if provided
  if (countryCode != null) insertData['country_code'] = countryCode;
  if (dialCode != null) insertData['dial_code'] = dialCode;
  if (currencyCode != null) insertData['currency_code'] = currencyCode;

  final response = await _client.from('tenants').insert(insertData).select().single();
  return response['id'] as String;
}
```

**3. `updateUserProfile()` - NOW USES USERS TABLE**

**Before (INCORRECT):**
```dart
await _client.from('profiles').upsert({  // ❌ Non-existent table
  'user_id': userId,
  'gender': gender,
  'phone_number': phoneNumber,      // ❌ Wrong field name
  'profile_image_url': profileImageUrl,  // ❌ Wrong field name
});
```

**After (CORRECT):**
```dart
await _client.from('users').update({  // ✅ Correct table
  'gender': gender.toLowerCase(),
  'phone': phoneNumber,               // ✅ Correct field name
  'avatar_url': profileImageUrl,      // ✅ Correct field name
  'updated_at': DateTime.now().toIso8601String(),
}).eq('id', userId);
```

**4. `getUserProfile()` - NOW USES USERS TABLE**

**Before:**
```dart
final response = await _client
    .from('profiles')  // ❌ Non-existent table
    .select()
    .eq('user_id', userId)  // ❌ Wrong filter
    .maybeSingle();
```

**After:**
```dart
final response = await _client
    .from('users')  // ✅ Correct table
    .select()
    .eq('id', userId)  // ✅ Correct filter
    .maybeSingle();
```

---

## 3. UI Screen Updates

### CountrySelectionScreen (`country_selection_screen.dart`)

**Changed Behavior:**
- **Before**: Tried to save country settings immediately to non-existent `profiles` table
- **After**: Passes country data to next screen (BusinessSetupScreen) via route arguments
- **Reason**: Country settings are tenant-level, so they should be saved when the tenant is created

**Code Change:**
```dart
// Now passes country data to BusinessSetupScreen
Navigator.of(context).pushReplacementNamed(
  '/business-setup',
  arguments: {
    'selectedCountry': {
      'code': _selectedCountry!.code,
      'name': _selectedCountry!.name,
      'dialCode': _selectedCountry!.dialCode,
      'currencyCode': _selectedCountry!.currencyCode,
      'flag': _selectedCountry!.flag,
    },
  },
);
```

### BusinessSetupScreen (`business_setup_screen.dart`)

**Changes:**
1. Added state variable to hold country data:
```dart
Map<String, dynamic>? _selectedCountry;
```

2. Added `initState()` to retrieve country data from route arguments:
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('selectedCountry')) {
      setState(() {
        _selectedCountry = args['selectedCountry'] as Map<String, dynamic>;
      });
    }
  });
}
```

3. Updated `_submit()` to pass country data to `createBusiness()`:
```dart
final tenantId = await supabaseService.createBusiness(
  ownerId: userId,
  businessName: _businessNameController.text.trim(),
  ...
  countryCode: _selectedCountry?['code'] as String?,
  dialCode: _selectedCountry?['dialCode'] as String?,
  currencyCode: _selectedCountry?['currencyCode'] as String?,
);
```

---

## 4. RLS Policies Verification

### ✅ RLS ENABLED on All Tenant-Scoped Tables

**Migration**: `008_rls_policies.sql` and `020_enable_rls_policies.sql`

**Tables with RLS:**
- ✅ tenants
- ✅ branches
- ✅ users
- ✅ products
- ✅ inventory_transactions
- ✅ inter_branch_transfers
- ✅ customers
- ✅ sales
- ✅ sale_items
- ✅ orders
- ✅ order_items
- ✅ deliveries
- ✅ riders
- ✅ staff_attendance
- ✅ ecommerce_connections
- ✅ chat_conversations
- ✅ whatsapp_messages

### ✅ Helper Functions Implemented

**Migration**: `019_rls_helper_functions.sql`

**Functions Available:**
1. ✅ `current_tenant_id()` - Returns authenticated user's tenant_id
2. ✅ `current_user_role()` - Returns user's role
3. ✅ `current_user_branch_id()` - Returns user's branch_id
4. ✅ `has_permission(role)` - Checks role hierarchy
5. ✅ `is_in_tenant(tenant_id)` - Validates tenant access
6. ✅ `can_access_branch(branch_id)` - Branch-level access control
7. ✅ `can_manage_users()` - User management permission
8. ✅ `can_manage_products()` - Product management permission
9. ✅ `can_view_reports()` - Analytics access permission
10. ✅ `can_void_sales()` - Sales void permission
11. ✅ `get_accessible_branches()` - Returns accessible branch UUIDs
12. ✅ `log_audit_event()` - Audit logging function

**All functions granted EXECUTE permission to authenticated users.**

### ✅ Tenant Isolation Policies

**Tenants Table:**
```sql
-- Users can only see their own tenant
CREATE POLICY "Users can view their own tenant"
    ON tenants FOR SELECT
    USING (id = current_tenant_id());

-- Only tenant admins can update tenant settings
CREATE POLICY "Owners can update tenant"
    ON tenants FOR UPDATE
    USING (id = current_tenant_id() AND current_user_role() = 'tenant_admin');
```

**Users Table:**
```sql
-- Users can view other users in their tenant
CREATE POLICY "Users can view users in their tenant"
    ON users FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (id = auth.uid());

-- Managers can create users in their tenant
CREATE POLICY "Managers can create users"
    ON users FOR INSERT
    WITH CHECK (
        tenant_id = current_tenant_id() AND
        can_manage_users()
    );
```

**Products Table:**
```sql
-- Users can view products in their tenant
CREATE POLICY "Users can view products in their tenant"
    ON products FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Managers can manage products
CREATE POLICY "Managers can insert products"
    ON products FOR INSERT
    WITH CHECK (
        tenant_id = current_tenant_id() AND
        can_manage_products()
    );
```

**Sales Table:**
```sql
-- Users can view sales in their tenant
CREATE POLICY "Users can view sales in their tenant"
    ON sales FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Cashiers can create sales
CREATE POLICY "Cashiers can create sales"
    ON sales FOR INSERT
    WITH CHECK (
        tenant_id = current_tenant_id() AND
        (cashier_id = auth.uid() OR sales_attendant_id = auth.uid())
    );
```

### ✅ Role Hierarchy Implemented

**Permission Levels (Higher = More Permissions):**
- `super_admin`: 100
- `tenant_admin`: 80 (Owner)
- `branch_manager`: 60
- `staff`: 40 (Cashier/Staff)
- `rider`: 20 (Delivery Rider)

**Access Control:**
- ✅ Super admins and tenant admins can access all branches in their tenant
- ✅ Branch managers can access their assigned branch
- ✅ Staff can access their assigned branch
- ✅ Riders can access deliveries assigned to them
- ✅ All roles can only access data within their tenant (tenant_id isolation)

---

## 5. Data Architecture Clarification

### BEFORE (Incorrect - 3 Tables)

```
auth.users (Supabase Auth)
  └─> public.users (App users)
  └─> public.profiles ❌ (NON-EXISTENT)
       └─> country_code, dial_code, currency_code ❌ (Wrong location)
       └─> gender, phone, profile_image_url
```

### AFTER (Correct - 2 Tables)

```
auth.users (Supabase Auth)
  └─> public.users (User profiles + auth)
       ├─> tenant_id → tenants
       ├─> role, branch_id
       ├─> email, phone, full_name
       ├─> avatar_url (profile picture)
       ├─> gender ✅ (NEW)
       └─> last_login_at

tenants (Business/Company)
  ├─> owner_id → users
  ├─> name, slug, logo_url, brand_color
  ├─> country_code, dial_code, currency_code ✅ (NEW)
  ├─> state, city, address, business_type
  └─> subscription_id → subscriptions
```

**Key Principle:**
- **User-level settings** (gender, phone, avatar) → `users` table
- **Tenant-level settings** (country, currency, branding) → `tenants` table

---

## 6. Testing Checklist

### ⚠️ Still Required (Manual Testing)

- [ ] **T089**: Test cross-tenant data isolation
  - Create Tenant A and Tenant B
  - Add products to Tenant A
  - Login as Tenant B user
  - Verify Tenant B CANNOT see Tenant A's products

- [ ] **T090**: Test role-based permissions
  - Create user with role='staff'
  - Attempt to delete a product (should FAIL)
  - Create user with role='tenant_admin'
  - Attempt to delete a product (should SUCCEED)

- [ ] **T090a**: Test Google Sign-In integration
  - Sign up using Google OAuth
  - Verify user created in `users` table
  - Verify tenant_id is NULL until business setup complete

- [ ] **T090b**: Test country selection persistence
  - Select country during onboarding (e.g., Nigeria)
  - Complete business setup
  - Query `tenants` table for created tenant
  - Verify `country_code='NG'`, `dial_code='+234'`, `currency_code='NGN'`

### ✅ Database Verification (Can Run Now)

```sql
-- Verify tenants table has new columns
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'tenants'
  AND column_name IN ('country_code', 'dial_code', 'currency_code');

-- Verify users table has gender column
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users'
  AND column_name = 'gender';

-- Verify RLS is enabled
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE tablename IN ('tenants', 'users', 'products', 'sales')
  AND schemaname = 'public';

-- List all RLS policies
SELECT schemaname, tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public';
```

---

## 7. Migration Deployment Instructions

### Step 1: Review Migration File

```bash
# Review the migration SQL
cat supabase/migrations/20260227_add_country_settings_to_tenants.sql
```

### Step 2: Apply Migration to Supabase

**Option A: Using Supabase CLI**
```bash
cd C:\Users\AFOKE\kemani
supabase db push
```

**Option B: Using Supabase Dashboard**
1. Go to https://supabase.com/dashboard
2. Select project: `ykbpznoqebhopyqpoqaf`
3. Navigate to SQL Editor
4. Copy contents of `20260227_add_country_settings_to_tenants.sql`
5. Execute SQL
6. Verify no errors

### Step 3: Verify Migration Applied

```sql
-- Check tenants table structure
\d tenants;

-- Check users table structure
\d users;

-- Verify constraints
SELECT conname, contype, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'tenants'::regclass
  AND conname LIKE 'chk_%';
```

---

## 8. Breaking Changes

### ⚠️ IMPORTANT: These changes may break existing functionality

**1. CountrySelectionScreen Navigation**

**Before:** Used `Navigator.pushReplacementNamed('/business-setup')`
**After:** Uses `Navigator.pushReplacementNamed('/business-setup', arguments: {...})`

**Impact:** If `/business-setup` route is not configured to accept arguments, this will fail.

**Fix:** Ensure route configuration supports arguments in `main.dart` or routing setup.

**2. SupabaseService Method Signatures Changed**

**Before:**
```dart
updateCountrySettings(userId: ...)
createBusiness(ownerId: ..., businessName: ...)
updateUserProfile(required String userId, required String gender, ...)
```

**After:**
```dart
updateCountrySettings(tenantId: ...)  // ❌ PARAMETER NAME CHANGED
createBusiness(ownerId: ..., businessName: ..., countryCode: ..., dialCode: ..., currencyCode: ...)  // ✅ NEW OPTIONAL PARAMS
updateUserProfile(required String userId, String? gender, ...)  // ❌ NOW OPTIONAL
```

**Impact:** Any existing code calling these methods will need to be updated.

**Fix:** Search codebase for calls to these methods and update accordingly.

---

## 9. Recommendations for Next Steps

### Immediate (Before Testing)

1. **Apply Migration**
   - Deploy `20260227_add_country_settings_to_tenants.sql` to Supabase

2. **Add Email Confirmation Screen**
   - Create `apps/pos_admin/lib/screens/email_confirmation_pending_screen.dart`
   - Show "Check your email" message after signup

3. **Add Brand Color Configuration**
   - Add color picker to `business_setup_screen.dart` or settings screen
   - Save to `tenants.brand_color` field

### Short-term (This Week)

4. **Manual Testing**
   - Execute T089-T090b test cases
   - Document results

5. **Create Test Tenants**
   - Create 2-3 test tenants with different countries
   - Verify country settings persist correctly

6. **Verify Google OAuth Config**
   - Check Supabase dashboard → Authentication → Providers → Google
   - Ensure client ID and secret are configured
   - Test Google Sign-In flow end-to-end

### Long-term (Next Sprint)

7. **Automated Integration Tests**
   - Write Playwright/Flutter integration tests for multi-tenant isolation
   - Test RLS policies automatically
   - Test country selection flow

8. **Staff Management UI**
   - Locate or build staff management screens
   - Test staff invite flow
   - Verify role-based permissions in UI

---

## 10. Files Changed

### Created:
- ✅ `supabase/migrations/20260227_add_country_settings_to_tenants.sql`
- ✅ `specs/001-multi-tenant-pos/us2-fixes-verification.md` (this file)

### Modified:
- ✅ `apps/pos_admin/lib/services/supabase_service.dart`
- ✅ `apps/pos_admin/lib/screens/country_selection_screen.dart`
- ✅ `apps/pos_admin/lib/screens/business_setup_screen.dart`

### Verified (No Changes Needed):
- ✅ `supabase/migrations/002_core_tables.sql` (tenants table)
- ✅ `supabase/migrations/008_rls_policies.sql` (RLS enabled)
- ✅ `supabase/migrations/019_rls_helper_functions.sql` (Helper functions)
- ✅ `supabase/migrations/020_enable_rls_policies.sql` (Policies)

---

## 11. Summary

### ✅ Completed

1. **Schema Fixes**
   - Added `country_code`, `dial_code`, `currency_code` to `tenants` table
   - Added `gender` to `users` table
   - Added validation constraints and indexes

2. **Service Layer Fixes**
   - `updateCountrySettings()` now saves to `tenants` table
   - `createBusiness()` accepts country parameters
   - `updateUserProfile()` and `getUserProfile()` now use `users` table
   - Eliminated references to non-existent `profiles` table

3. **UI Fixes**
   - CountrySelectionScreen passes country data to BusinessSetupScreen
   - BusinessSetupScreen receives and saves country data during tenant creation

4. **RLS Verification**
   - Confirmed RLS enabled on all tenant-scoped tables
   - Verified comprehensive RLS policies exist
   - Confirmed helper functions implement proper tenant isolation

### ⚠️ Pending

1. **Migration Deployment** - Need to apply SQL migration to Supabase
2. **Manual Testing** - Need to execute T089-T090b test cases
3. **Email Confirmation Screen** - Missing UI component
4. **Brand Color Configuration** - Partial implementation

### 🎯 Next Action

**Deploy the migration and run manual tests to verify multi-tenant isolation works correctly.**

---

**Generated**: 2026-02-27
**Author**: Claude (Code Review & Schema Fix)
**Status**: ✅ Ready for Migration Deployment
