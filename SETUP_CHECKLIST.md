# Setup Checklist

Complete checklist for getting your Kemani multi-platform monorepo up and running.

## Prerequisites ✅

- [ ] **Node.js 18+** installed
  ```bash
  node --version  # Should be 18.0.0 or higher
  ```

- [ ] **Flutter 3.0+** installed (for Flutter apps)
  ```bash
  flutter --version  # Should be 3.0.0 or higher
  flutter doctor     # Check for issues
  ```

- [ ] **Supabase account** created at https://supabase.com

---

## Step 1: Supabase Setup 🗄️

Follow [SUPABASE_SETUP.md](./SUPABASE_SETUP.md) for detailed instructions.

### 1.1 Create Supabase Project

- [ ] Go to https://supabase.com
- [ ] Create new project named `kemani`
- [ ] Choose region closest to your users
- [ ] Save database password securely
- [ ] Wait for project provisioning (2-3 minutes)

### 1.2 Get API Credentials

- [ ] Go to Project Settings → API
- [ ] Copy **Project URL** (`SUPABASE_URL`)
- [ ] Copy **anon public** key (`SUPABASE_ANON_KEY`)
- [ ] Copy **service_role** key (`SUPABASE_SERVICE_ROLE_KEY`)
- [ ] Save these securely (you'll need them for each app)

### 1.3 Run Database Migrations

Choose one method:

**Option A: Supabase CLI (Recommended)**
- [ ] Install Supabase CLI: `npm install -g supabase`
- [ ] Link project: `supabase link --project-ref YOUR_PROJECT_REF`
- [ ] Push migrations: `supabase db push`

**Option B: PowerShell Script**
- [ ] Run: `.\supabase\apply_migrations.ps1`
- [ ] Copy output: `supabase\combined_migration.sql`
- [ ] Paste in Supabase Dashboard → SQL Editor
- [ ] Click "Run"

**Option C: Manual**
- [ ] Apply each migration file in order (001 → 030)
- [ ] Use Supabase Dashboard → SQL Editor

### 1.4 Verify Database Setup

- [ ] Go to Table Editor
- [ ] Confirm `tenants` table exists
- [ ] Confirm `products` table exists
- [ ] Confirm `healthcare_providers` table exists
- [ ] Confirm `patients` table exists
- [ ] Go to Authentication → Policies
- [ ] Verify RLS is enabled on tables

---

## Step 2: Environment Configuration 🔧

### 2.1 Root Environment (Optional)

- [ ] Copy: `cp .env.example .env`
- [ ] Edit `.env` and add your Supabase credentials

### 2.2 Healthcare Customer App (SvelteKit)

- [ ] Navigate: `cd apps/healthcare_customer`
- [ ] Copy: `cp .env.example .env`
- [ ] Edit `.env`:
  ```env
  PUBLIC_SUPABASE_URL=https://your-project.supabase.co
  PUBLIC_SUPABASE_ANON_KEY=your-anon-key
  ```

### 2.3 POS Admin App (Flutter)

No .env file needed. You'll pass credentials when running:
- [ ] Prepare your run command:
  ```bash
  flutter run -d chrome \
    --dart-define=SUPABASE_URL=https://your-project.supabase.co \
    --dart-define=SUPABASE_ANON_KEY=your-anon-key
  ```

**Alternative:** Edit `lib/main.dart` directly (not recommended for production)

### 2.4 Healthcare Medic App (Flutter)

Same as POS Admin:
- [ ] Prepare your run command with Supabase credentials

---

## Step 3: Create Test Users 👥

### 3.1 Create Users in Supabase Dashboard

Go to Authentication → Users → Add user

**Test User 1: POS Owner**
- [ ] Email: `owner@example.com`
- [ ] Password: `TestPassword123!`
- [ ] Auto Confirm: ✅ Yes
- [ ] Note the user UUID

**Test User 2: Healthcare Provider**
- [ ] Email: `doctor@example.com`
- [ ] Password: `TestPassword123!`
- [ ] Auto Confirm: ✅ Yes
- [ ] Note the user UUID

**Test User 3: Patient**
- [ ] Email: `patient@example.com`
- [ ] Password: `TestPassword123!`
- [ ] Auto Confirm: ✅ Yes
- [ ] Note the user UUID

### 3.2 Create Associated Database Records

Go to SQL Editor and run:

**For POS Owner:**
- [ ] Create tenant record (see SUPABASE_SETUP.md for SQL)
- [ ] Link user to tenant via metadata update

**For Healthcare Provider:**
- [ ] Create `healthcare_providers` record (see SUPABASE_SETUP.md for SQL)

**For Patient:**
- [ ] Create `patients` record (see SUPABASE_SETUP.md for SQL)

---

## Step 4: Test Apps Locally 🚀

### 4.1 Healthcare Customer App (SvelteKit)

- [ ] Navigate: `cd apps/healthcare_customer`
- [ ] Install dependencies: `npm install`
- [ ] Start dev server: `npm run dev`
- [ ] Open: http://localhost:5173
- [ ] Verify dashboard loads without errors
- [ ] Check browser console for any errors
- [ ] Try clicking navigation cards

**Expected Result:**
- ✅ Dashboard with 4 cards visible
- ✅ No console errors
- ✅ Tailwind CSS styling applied

### 4.2 POS Admin App (Flutter)

- [ ] Navigate: `cd apps/pos_admin`
- [ ] Install dependencies: `flutter pub get`
- [ ] Run app:
  ```bash
  flutter run -d chrome \
    --dart-define=SUPABASE_URL=your-url \
    --dart-define=SUPABASE_ANON_KEY=your-key
  ```
- [ ] Verify login screen appears
- [ ] Try logging in with `owner@example.com`
- [ ] Verify dashboard loads with 4 stat cards
- [ ] Try bottom navigation (Dashboard, Products, Inventory, Sales, Analytics)

**Expected Result:**
- ✅ Login screen loads
- ✅ Authentication works
- ✅ Dashboard shows 4 stat cards
- ✅ Bottom navigation works

### 4.3 Healthcare Medic App (Flutter)

- [ ] Navigate: `cd apps/healthcare_medic`
- [ ] Install dependencies: `flutter pub get`
- [ ] Run app with Supabase credentials
- [ ] Login with `doctor@example.com`
- [ ] Verify consultations screen appears
- [ ] Check bottom navigation (Consultations, Patients, Schedule, Profile)
- [ ] Verify "New Consultation" floating button appears

**Expected Result:**
- ✅ Login successful
- ✅ Consultations screen shows "No consultations" message
- ✅ Navigation works
- ✅ Floating action button visible

---

## Step 5: Verify Integration 🔍

### 5.1 Test Authentication

- [ ] Sign out from one app
- [ ] Sign in with test credentials
- [ ] Verify successful login
- [ ] Check that user data loads correctly

### 5.2 Test Database Connection

**Healthcare Customer:**
- [ ] Try loading consultations (should be empty initially)
- [ ] Check browser Network tab for Supabase API calls
- [ ] Verify no 401/403 errors

**POS Admin:**
- [ ] Navigate to Products screen
- [ ] Check for database connection
- [ ] Verify RLS policies allow access

**Healthcare Medic:**
- [ ] Navigate to Patients screen
- [ ] Check for database connection
- [ ] Verify provider permissions work

### 5.3 Test RLS Policies

- [ ] Log in as `owner@example.com` in POS Admin
- [ ] Verify you can only see your tenant's data
- [ ] Log in as different user (if available)
- [ ] Verify data isolation works

---

## Step 6: Optional Enhancements 🎨

### 6.1 Sample Data

- [ ] Add sample products to POS system
- [ ] Create sample consultations
- [ ] Add sample patients
- [ ] Test with realistic data

### 6.2 Customize Branding

**Healthcare Customer:**
- [ ] Update `apps/healthcare_customer/src/app.html` title
- [ ] Add favicon
- [ ] Customize colors in Tailwind config

**POS Admin:**
- [ ] Update app name in `pubspec.yaml`
- [ ] Add app icon
- [ ] Customize theme colors in `lib/main.dart`

**Healthcare Medic:**
- [ ] Update app name
- [ ] Add branding
- [ ] Customize colors

### 6.3 Set Up Development Workflow

- [ ] Create feature branch: `git checkout -b feature/your-feature`
- [ ] Make changes
- [ ] Test locally
- [ ] Commit and push
- [ ] Create pull request

---

## Troubleshooting 🔧

If you encounter issues, check:

- [ ] [SUPABASE_SETUP.md](./SUPABASE_SETUP.md) → Troubleshooting section
- [ ] [QUICK_START.md](./QUICK_START.md) → Troubleshooting section
- [ ] Individual app READMEs in `apps/*/README.md`
- [ ] Browser console for errors
- [ ] Supabase Dashboard → Logs
- [ ] Supabase Dashboard → API → Check credentials

**Common Issues:**

1. **"Cannot connect to Supabase"**
   - Verify URL and anon key are correct
   - Check if project is active (not paused)
   - Verify network connection

2. **"Permission denied"**
   - Check RLS policies are configured
   - Verify user has required metadata (tenant_id)
   - Check if user exists in database table

3. **"Module not found" (SvelteKit)**
   - Run `npm install` in app directory
   - Delete `node_modules` and reinstall
   - Check Node.js version

4. **Flutter build errors**
   - Run `flutter clean && flutter pub get`
   - Run `flutter doctor` to check setup
   - Verify Flutter version is 3.0+

---

## Next Steps 🎯

After completing this checklist:

1. **Start Developing:**
   - Follow [QUICK_START.md](./QUICK_START.md) for development workflow
   - Review [ARCHITECTURE.md](./ARCHITECTURE.md) for architecture decisions
   - Check [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) for database reference

2. **Implement Features:**
   - Complete placeholder screens
   - Add CRUD operations
   - Implement business logic
   - Add real-time updates

3. **Testing:**
   - Write unit tests
   - Add integration tests
   - Test on different platforms (web, mobile, desktop)

4. **Deployment:**
   - Set up production Supabase project
   - Configure production environment variables
   - Deploy to hosting platforms
   - Set up CI/CD pipelines

---

## Success Criteria ✅

You've successfully set up the project when:

- ✅ All 3 apps run locally without errors
- ✅ Authentication works in all apps
- ✅ Database connection is successful
- ✅ RLS policies enforce proper access control
- ✅ Test users can log in and see appropriate data
- ✅ No console errors in browser or terminal

---

## Resources 📚

**Documentation:**
- [SUPABASE_SETUP.md](./SUPABASE_SETUP.md) - Detailed Supabase setup
- [QUICK_START.md](./QUICK_START.md) - Quick start guide
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Architecture overview
- [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) - Database reference
- [MIGRATION_FROM_NEXTJS.md](./MIGRATION_FROM_NEXTJS.md) - Migration guide

**External:**
- [Supabase Docs](https://supabase.com/docs)
- [SvelteKit Docs](https://kit.svelte.dev/)
- [Flutter Docs](https://flutter.dev/)

---

**Need Help?**

1. Check documentation files listed above
2. Review app-specific READMEs
3. Check Supabase Dashboard logs
4. Review browser console errors
5. Run `flutter doctor` or `npm doctor`

**Ready to start coding?** 🚀

Proceed to [QUICK_START.md](./QUICK_START.md) for development workflow!
