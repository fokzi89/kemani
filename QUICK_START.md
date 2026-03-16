# 🚀 Healthcare Customer App - Quick Start Guide

Get the healthcare app running with video consultations in **5 minutes**!

## ✅ What's Been Created

### 1. Healthcare Customer Portal (SvelteKit)
**Location:** `apps/healthcare_customer/`

A patient-facing web application for booking and managing healthcare consultations.

**Features:**
- Dashboard with consultation overview
- Book new consultations
- View appointment history
- User profile management
- Real-time notifications

**To run:**
```bash
cd apps/healthcare_customer
npm install
cp .env.example .env
# Edit .env with your Supabase credentials
npm run dev
```
Open http://localhost:5173

### 2. POS Admin Dashboard (Flutter)
**Location:** `apps/pos_admin/`

Cross-platform admin interface for managing POS operations.

**Features:**
- Dashboard with sales overview
- Product management
- Inventory tracking
- Sales processing
- Analytics
- Multi-tenant support

**To run:**
```bash
cd apps/pos_admin
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-key
```

### 3. Healthcare Medic Interface (Flutter)
**Location:** `apps/healthcare_medic/`

Medical professional interface for managing consultations and patients.

**Features:**
- Consultation management
- Patient records
- Appointment scheduling
- Session notes
- Provider profile

**To run:**
```bash
cd apps/healthcare_medic
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-key
```

## 🚀 Setup Instructions

### Prerequisites

1. **Node.js** 18+ (for SvelteKit apps)
2. **Flutter** 3.0+ (for Flutter apps)
3. **Supabase** account with project created

### Step 1: Set Up Supabase

1. Create a Supabase project at https://supabase.com
2. Run your database migrations:
   ```bash
   # Navigate to project root
   cd C:\Users\AFOKE\kemani

   # Run migrations via Supabase CLI (if installed)
   supabase db push

   # Or manually copy migrations from supabase/migrations/ to Supabase Dashboard > SQL Editor
   ```

3. Get your Supabase credentials from Project Settings > API:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

### Step 2: Configure Healthcare Customer App (SvelteKit)

```bash
cd apps/healthcare_customer

# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Edit .env and add:
# PUBLIC_SUPABASE_URL=https://your-project.supabase.co
# PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# Start development server
npm run dev
```

Visit http://localhost:5173

### Step 3: Configure POS Admin App (Flutter)

```bash
cd apps/pos_admin

# Install dependencies
flutter pub get

# Option 1: Run with command-line arguments (recommended)
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key

# Option 2: Edit lib/main.dart and replace the default values
```

### Step 4: Configure Healthcare Medic App (Flutter)

```bash
cd apps/healthcare_medic

# Install dependencies
flutter pub get

# Run with command-line arguments
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## 📱 Platform Support

### SvelteKit Apps (healthcare_customer)
- ✅ Web (all browsers)
- ✅ Server-Side Rendering (SSR)
- ✅ Static Site Generation (SSG)

**Deploy to:** Vercel, Netlify, Cloudflare Pages

### Flutter Apps (pos_admin, healthcare_medic)
- ✅ Web (Chrome, Edge, Safari, Firefox)
- ✅ Windows Desktop
- ✅ Android (mobile & tablet)
- ✅ iOS (mobile & tablet)
- ✅ macOS Desktop
- ✅ Linux Desktop

**Deploy to:**
- Web: Firebase Hosting, Vercel, Netlify
- Mobile: Google Play Store, Apple App Store
- Desktop: Direct distribution or Windows Store

## 🗄️ Database Tables Required

Ensure these tables exist in your Supabase database:

### Multi-Tenant POS System
- `tenants` - Business/tenant information
- `users` - User accounts
- `products` - Products catalog
- `inventory` - Stock levels
- `sales` - Transaction records
- `receipts` - Sale receipts
- `staff` - Staff members

### Healthcare System
- `healthcare_providers` - Medical professionals
- `patients` - Patient records
- `consultations` - Consultation sessions
- `consultation_notes` - Session notes
- `appointments` - Scheduled appointments

## 🔐 Authentication Setup

All apps use **Supabase Auth**. You'll need to:

1. **Enable Email/Password authentication** in Supabase Dashboard:
   - Go to Authentication > Providers
   - Enable Email provider

2. **Create test users** in Supabase Dashboard:
   - Go to Authentication > Users
   - Click "Add user"
   - Add email and password

3. **Set up Row-Level Security (RLS):**
   - Ensure RLS is enabled on all tables
   - Migrations in `supabase/migrations/` already include RLS policies

## 🧪 Testing the Apps

### Healthcare Customer App
1. Start the app: `npm run dev`
2. Open http://localhost:5173
3. You should see the dashboard with cards for:
   - Consultations
   - Book Consultation
   - Profile
   - Notifications

### POS Admin App
1. Run: `flutter run -d chrome`
2. You should see a login screen
3. Sign in with a test user
4. Dashboard shows:
   - Total Sales
   - Products
   - Low Stock
   - Transactions
5. Bottom navigation: Dashboard, Products, Inventory, Sales, Analytics

### Healthcare Medic App
1. Run: `flutter run -d chrome`
2. Sign in with a healthcare provider account
3. Dashboard shows:
   - Today's Consultations
   - Patients
   - Schedule
   - Profile
4. Floating action button to create new consultation

## 📝 Next Steps

### For Development

1. **Implement business logic:**
   - Add database queries to fetch real data
   - Implement create/update/delete operations
   - Add form validation

2. **Build out screens:**
   - Complete placeholder screens (Products, Inventory, etc.)
   - Add detail views
   - Implement navigation

3. **Add features:**
   - Real-time updates via Supabase Realtime
   - Offline support for Flutter apps
   - Search and filtering
   - Export functionality

4. **Testing:**
   - Write unit tests
   - Add integration tests
   - E2E testing with Playwright (SvelteKit) or integration_test (Flutter)

### For Production

1. **Security:**
   - Review RLS policies
   - Implement rate limiting
   - Add audit logging
   - Security headers

2. **Performance:**
   - Optimize database queries
   - Add caching
   - Implement pagination
   - Image optimization

3. **Monitoring:**
   - Set up error tracking (Sentry)
   - Add analytics
   - Performance monitoring
   - Uptime monitoring

4. **Deployment:**
   - Set up CI/CD pipelines
   - Configure production environment variables
   - Deploy to hosting platforms
   - Set up custom domains

## 🔄 Migration from Old Code

The old Next.js code has been removed. To migrate business logic:

1. **API Routes → Direct Supabase Calls**
   - Old: `app/api/products/route.ts`
   - New: Direct calls in SvelteKit load functions or Flutter services

2. **React Components → Svelte/Flutter**
   - Old: React components in `components/`
   - New: Svelte components (`.svelte`) or Flutter widgets (`.dart`)

3. **Hooks → Svelte Stores/Flutter State**
   - Old: React hooks like `useAuth`, `useProducts`
   - New: Svelte stores or Flutter Provider/Riverpod

See [MIGRATION_FROM_NEXTJS.md](./MIGRATION_FROM_NEXTJS.md) for detailed code examples.

## 📚 Documentation

- **[README.md](./README.md)** - Project overview
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Architecture decisions
- **[CLAUDE.md](./CLAUDE.md)** - Development workflow
- **[MIGRATION_FROM_NEXTJS.md](./MIGRATION_FROM_NEXTJS.md)** - Migration guide
- Individual app READMEs in each `apps/*/README.md`

## 🆘 Troubleshooting

### SvelteKit App Won't Start
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Check Node.js version
node --version  # Should be 18+
```

### Flutter App Won't Build
```bash
# Clean build
flutter clean
flutter pub get

# Check Flutter version
flutter --version  # Should be 3.0+

# Run Flutter doctor
flutter doctor
```

### Supabase Connection Error
- Verify your Supabase URL and anon key are correct
- Check if Supabase project is active
- Ensure RLS policies allow your operations
- Check browser console for detailed errors

### Authentication Issues
- Verify user exists in Supabase Auth
- Check RLS policies on tables
- Ensure anon key has correct permissions
- Check Supabase Auth logs in dashboard

## 🎯 Current Status

| App | Status | Tech | Platform |
|-----|--------|------|----------|
| Marketing Site | ✅ Existing | SvelteKit | Web |
| Storefront | 🚧 In Progress | SvelteKit | Web |
| Healthcare Customer | ✅ Created | SvelteKit | Web |
| POS Admin | ✅ Created | Flutter | Multi-platform |
| Healthcare Medic | ✅ Created | Flutter | Multi-platform |
| Web Client (Legacy) | 📦 Archived | Flutter | Web |

✅ = Ready to develop | 🚧 = Needs completion | 📦 = Legacy

---

**You're all set!** Start developing by choosing an app and running it locally. Refer to individual app READMEs for more details.
