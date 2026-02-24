# Owner Flow Testing Guide

This guide walks you through testing the complete owner registration and onboarding flow for Kemani POS.

## Overview

The owner flow consists of these steps:
1. **Login Page** - Enter email address
2. **OTP Verification** - Verify 6-digit code sent to email
3. **Registration/Onboarding** - Complete business setup (for new users)
4. **POS Dashboard** - Access the point of sale system

---

## Prerequisites

### 1. Database Setup
Ensure your Supabase database is running and migrated:
```bash
# Check Supabase status
supabase status

# If not started, start Supabase
supabase start

# Run migrations (including the new tenant-scoped products migration)
supabase db push
```

### 2. Environment Variables
Create `.env.local` file in the root directory:
```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 3. Start Development Server
```bash
npm run dev
```

The app should be running at `http://localhost:3000`

---

## Testing the Owner Flow

### Step 1: Login Page
**URL:** `http://localhost:3000/login`

**What to test:**
1. Open the login page
2. You should see:
   - Kemani POS logo
   - "Sign in with email" heading
   - Email input field
   - "Send Verification Code" button

**Actions:**
1. Enter a valid email address (e.g., `owner@example.com`)
2. Click "Send Verification Code"

**Expected Result:**
- Loading state shows "Sending..."
- Redirects to `/verify-otp?identifier=owner@example.com&channel=email`
- You should receive an OTP code via email

**What happens behind the scenes:**
- API: `POST /api/auth/send-otp`
- Supabase sends a magic link/OTP to the email
- The OTP is stored in Supabase Auth

---

### Step 2: OTP Verification
**URL:** `http://localhost:3000/verify-otp?identifier=owner@example.com&channel=email`

**What to test:**
1. You should see:
   - 6 input boxes for OTP digits
   - "Didn't receive code?" link
   - Email address displayed

**Actions:**
1. Check your email for the OTP code (6 digits)
2. Enter the OTP code in the 6 input boxes
3. The form auto-submits when all 6 digits are entered

**Expected Results:**

**For NEW users (first time):**
- API checks if user exists in `users` table
- Returns `needsRegistration: true`
- Redirects to `/register?identifier=owner@example.com`

**For EXISTING users:**
- Returns `needsRegistration: false`
- Redirects to `/pos/pos` (POS dashboard)

**What happens behind the scenes:**
- API: `POST /api/auth/verify-otp`
- Verifies OTP with Supabase Auth
- Creates Supabase session (user is now authenticated)
- Checks if user record exists in `users` table
- Returns appropriate response based on registration status

---

### Step 3: Registration (New Users Only)
**URL:** `http://localhost:3000/register?identifier=owner@example.com`

**Important:** This page requires an active Supabase session. If you're redirected back to login, it means the session expired. Start from Step 1 again.

**What to test:**
1. You should see:
   - Business Name field
   - Your Full Name field
   - Email Address field (pre-filled and read-only)
   - 6-digit Passcode field
   - Confirm Passcode field
   - Security notice explaining passcode usage

**Actions:**
1. Enter **Business Name**: e.g., "My Coffee Shop"
2. Enter **Your Full Name**: e.g., "John Doe"
3. Email is pre-filled with `owner@example.com`
4. Enter **6-Digit Passcode**: e.g., "123456"
5. Enter **Confirm Passcode**: "123456"
6. Click "Create Account"

**Expected Result:**
- Loading state shows "Creating Account..."
- Account is created successfully
- Redirects to `/pos/pos` (POS dashboard)

**What happens behind the scenes:**
- API: `POST /api/auth/register`
- Validates all inputs (passcode must be exactly 6 digits)
- Hashes the passcode using SHA-256
- Creates records in database:
  1. **Tenant** - Creates tenant with generated slug from business name
  2. **User** - Creates user with role `tenant_admin`
  3. **Branch** - Creates default branch named "{Business Name} - Main Branch"
- Stores passcode hash in user metadata
- Returns success response

**Database Records Created:**

**tenants table:**
```sql
{
  id: uuid,
  name: "My Coffee Shop",
  slug: "my-coffee-shop",
  email: "owner@example.com",
  created_at: timestamp
}
```

**users table:**
```sql
{
  id: uuid (from Supabase Auth),
  full_name: "John Doe",
  email: "owner@example.com",
  role: "tenant_admin",
  tenant_id: uuid (from tenants.id),
  created_at: timestamp
}
```

**branches table:**
```sql
{
  id: uuid,
  name: "My Coffee Shop - Main Branch",
  tenant_id: uuid,
  business_type: "retail",
  created_at: timestamp
}
```

**Supabase Auth User Metadata:**
```json
{
  "passcode_hash": "sha256_hash_of_123456"
}
```

---

### Step 4: POS Dashboard Access
**URL:** `http://localhost:3000/pos/pos`

**What to test:**
1. After successful registration, you should be redirected here
2. You should see the POS interface with:
   - Product selector (left side)
   - Cart and checkout (right side)
   - No product images (per recent changes)

**Expected Result:**
- POS page loads successfully
- User is authenticated and has access
- Products are loaded from the database (if any exist)

---

## Common Issues & Troubleshooting

### Issue 1: Email Not Received
**Problem:** OTP email doesn't arrive

**Solutions:**
1. Check spam/junk folder
2. Verify email configuration in Supabase dashboard
3. Check Supabase logs for email sending errors
4. For development, check Supabase Studio > Authentication > Logs for the OTP code

### Issue 2: Session Expired on Registration Page
**Problem:** Redirected to login from `/register`

**Solutions:**
1. The OTP session expires after a certain time
2. Complete the flow faster
3. Start from Step 1 (login) again

### Issue 3: Slug Already Taken
**Problem:** Business name generates duplicate slug

**Solutions:**
- The system automatically appends timestamp to make it unique
- E.g., "my-coffee-shop" becomes "my-coffee-shop-1708789200000"

### Issue 4: Branch Creation Failed
**Problem:** Default branch not created

**Solutions:**
- This is a non-critical error (logged but doesn't fail registration)
- Branch can be created manually later
- Check database RLS policies for `branches` table

### Issue 5: Products Don't Load
**Problem:** No products show in POS

**Solutions:**
1. This is expected for new tenants (no products yet)
2. Products must be added via admin interface or API
3. After adding products, they need branch inventory records
4. Verify the migration `20260223_tenant_scoped_products.sql` ran successfully

---

## Testing Checklist

Use this checklist to verify the complete flow:

- [ ] **Login Page**
  - [ ] Email input accepts valid email
  - [ ] "Send Verification Code" button works
  - [ ] Loading state displays correctly
  - [ ] Redirects to OTP verification

- [ ] **OTP Verification**
  - [ ] OTP email received
  - [ ] 6 input boxes work correctly
  - [ ] Auto-focus moves to next input
  - [ ] Auto-submit on completion
  - [ ] Backspace navigation works
  - [ ] "Resend OTP" button works

- [ ] **Registration (New User)**
  - [ ] All form fields render correctly
  - [ ] Email pre-filled and read-only
  - [ ] Passcode validation (must be 6 digits)
  - [ ] Passcode confirmation validation
  - [ ] Error messages display for invalid input
  - [ ] Success creates tenant, user, and branch
  - [ ] Redirects to POS dashboard

- [ ] **POS Access**
  - [ ] POS page loads successfully
  - [ ] No product images displayed (performance optimization)
  - [ ] User is authenticated

- [ ] **Database Verification**
  - [ ] Tenant record created in `tenants` table
  - [ ] User record created in `users` table with role `tenant_admin`
  - [ ] Branch record created in `branches` table
  - [ ] Passcode hash stored in Supabase Auth metadata

---

## API Endpoints Reference

### POST /api/auth/send-otp
**Purpose:** Send OTP code to email

**Request:**
```json
{
  "identifier": "owner@example.com",
  "channel": "email"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP sent successfully"
}
```

### POST /api/auth/verify-otp
**Purpose:** Verify OTP and create session

**Request:**
```json
{
  "identifier": "owner@example.com",
  "otp": "123456",
  "channel": "email"
}
```

**Response (New User):**
```json
{
  "success": true,
  "needsRegistration": true
}
```

**Response (Existing User):**
```json
{
  "success": true,
  "needsRegistration": false
}
```

### POST /api/auth/register
**Purpose:** Complete registration for new users

**Request:**
```json
{
  "businessName": "My Coffee Shop",
  "fullName": "John Doe",
  "email": "owner@example.com",
  "passcode": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "tenant": {
    "id": "uuid",
    "name": "My Coffee Shop",
    "slug": "my-coffee-shop",
    "email": "owner@example.com"
  },
  "message": "Registration completed successfully"
}
```

---

## Next Steps After Registration

After successfully registering as an owner, you can:

1. **Add Products** - Create tenant products via admin interface
2. **Configure Branch Inventory** - Set stock levels for each branch
3. **Invite Staff** - Add cashiers and branch managers
4. **Configure Settings** - Set up payment methods, taxes, etc.
5. **Test POS** - Process sample sales to verify everything works

---

## Development Tips

### Quick Reset for Testing
If you need to test the registration flow multiple times:

```sql
-- Delete test user from Supabase Auth (via Supabase Studio)
-- Then delete from database:
DELETE FROM users WHERE email = 'owner@example.com';
DELETE FROM branches WHERE tenant_id = (SELECT id FROM tenants WHERE email = 'owner@example.com');
DELETE FROM tenants WHERE email = 'owner@example.com';
```

### Checking Logs
Monitor logs in terminal while testing:
```bash
# Terminal running npm run dev will show:
# - API requests
# - Database queries
# - Errors and warnings
```

### Browser DevTools
- **Network Tab:** Monitor API calls and responses
- **Console Tab:** Check for JavaScript errors
- **Application Tab:** View Supabase session/cookies

---

## Success Criteria

The owner flow is working correctly if:

1. ✅ User can enter email and receive OTP
2. ✅ User can verify OTP successfully
3. ✅ New users are redirected to registration
4. ✅ Registration creates all required database records
5. ✅ User is redirected to POS dashboard after registration
6. ✅ User can access POS without errors

Happy testing! 🎉
