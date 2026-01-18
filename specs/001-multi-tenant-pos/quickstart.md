# Kemani POS Platform - Developer Quickstart Guide

**Version**: 1.0.0
**Last Updated**: 2026-01-17
**Target Audience**: Developers setting up local development environment

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Environment Setup](#local-environment-setup)
3. [Supabase Configuration](#supabase-configuration)
4. [Database Setup](#database-setup)
5. [Next.js Application Setup](#nextjs-application-setup)
6. [PWA Configuration](#pwa-configuration)
7. [Offline Sync Setup (PowerSync)](#offline-sync-setup-powersync)
8. [Payment Gateway Integration](#payment-gateway-integration)
9. [Testing](#testing)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| **Node.js** | 20.x LTS | Runtime environment | [nodejs.org](https://nodejs.org/) |
| **npm** | 10.x | Package manager | Included with Node.js |
| **Git** | Latest | Version control | [git-scm.com](https://git-scm.com/) |
| **VS Code** | Latest | Code editor (recommended) | [code.visualstudio.com](https://code.visualstudio.com/) |
| **Supabase CLI** | Latest | Database management | `npm install -g supabase` |

### Accounts & Services

- **Supabase Account**: [supabase.com](https://supabase.com) (free tier sufficient for development)
- **Paystack Test Account**: [paystack.com](https://paystack.com) (for payment testing)
- **Termii Account**: [termii.com](https://termii.com) (for SMS OTP - optional for local dev)

### System Requirements

- **OS**: Windows 10+, macOS 12+, or Linux (Ubuntu 20.04+)
- **RAM**: 8GB minimum (16GB recommended)
- **Disk Space**: 5GB free space
- **Internet**: Required for initial setup and package downloads

---

## Local Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/kemani-pos.git
cd kemani-pos
```

### 2. Install Dependencies

```bash
npm install
```

This installs:
- Next.js 16 (App Router)
- React 19
- TypeScript 5.x
- Tailwind CSS 4
- Supabase Client
- PowerSync SDK
- wa-sqlite
- next-pwa
- And all other dependencies

### 3. Environment Variables

Create `.env.local` file in project root:

```bash
cp .env.example .env.local
```

Update `.env.local` with your credentials:

```env
# ============================================================
# Supabase Configuration
# ============================================================
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# ============================================================
# PowerSync Configuration
# ============================================================
NEXT_PUBLIC_POWERSYNC_URL=https://your-powersync-instance.powersync.com
NEXT_PUBLIC_POWERSYNC_TOKEN=your-powersync-token

# ============================================================
# Payment Gateways (Test Mode)
# ============================================================
NEXT_PUBLIC_PAYSTACK_PUBLIC_KEY=pk_test_xxxxxxxxxxxxx
PAYSTACK_SECRET_KEY=sk_test_xxxxxxxxxxxxx

FLUTTERWAVE_PUBLIC_KEY=FLWPUBK_TEST-xxxxxxxxxxxxx
FLUTTERWAVE_SECRET_KEY=FLWSECK_TEST-xxxxxxxxxxxxx

# ============================================================
# SMS/OTP Provider (Optional for local dev)
# ============================================================
TERMII_API_KEY=your-termii-api-key
TERMII_SENDER_ID=Kemani

# ============================================================
# Application Settings
# ============================================================
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development
```

---

## Supabase Configuration

### 1. Create Supabase Project

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Click "New Project"
3. Fill in:
   - **Project Name**: `kemani-pos-dev`
   - **Database Password**: (generate strong password, save it!)
   - **Region**: Choose nearest region
4. Click "Create new project" (takes ~2 minutes)

### 2. Get API Credentials

Once project is ready:

1. Go to **Settings** → **API**
2. Copy:
   - **Project URL** → `NEXT_PUBLIC_SUPABASE_URL`
   - **anon/public key** → `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - **service_role key** → `SUPABASE_SERVICE_ROLE_KEY` (⚠️ Keep secret!)

### 3. Enable Required Extensions

Go to **Database** → **Extensions** and enable:

```sql
-- In SQL Editor
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "postgis";
```

### 4. Configure Authentication

1. Go to **Authentication** → **Providers**
2. Enable **Phone** provider:
   - Enable "Phone"
   - Choose SMS provider: Twilio or custom (we'll use Supabase's default for testing)
3. Enable **Email** provider (default, should be enabled)

### 5. Configure Storage

1. Go to **Storage** → **Buckets**
2. Create buckets:
   - **Name**: `product-images`, **Public**: true, **File size limit**: 5MB
   - **Name**: `receipts`, **Public**: false, **File size limit**: 10MB
   - **Name**: `delivery-proofs`, **Public**: false, **File size limit**: 5MB

3. Set bucket policies (SQL Editor):

```sql
-- Product images: Public read, authenticated write
CREATE POLICY "Public read product images" ON storage.objects
    FOR SELECT USING (bucket_id = 'product-images');

CREATE POLICY "Authenticated users can upload product images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'product-images' AND auth.role() = 'authenticated');

-- Receipts: Owner-only access
CREATE POLICY "Users can view own tenant receipts" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'receipts' AND
        (storage.foldername(name))[1] = (SELECT tenant_id::TEXT FROM users WHERE id = auth.uid())
    );
```

---

## Database Setup

### 1. Run Database Migrations

Execute the Supabase schema:

1. Open Supabase SQL Editor: [supabase.com/dashboard/project/_/sql](https://supabase.com/dashboard/project/_/sql)
2. Copy contents of `specs/001-multi-tenant-pos/contracts/supabase-schema.sql`
3. Paste into SQL Editor
4. Click **Run**

This creates:
- All 19 tables (tenants, branches, products, sales, orders, etc.)
- RLS policies for multi-tenant isolation
- Indexes for performance
- Triggers for auto-generated values
- Seed data (subscription plans)

### 2. Verify Database Setup

Run verification query:

```sql
-- Check tables created
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Should return: branches, chat_conversations, chat_messages, commissions,
-- customer_addresses, customers, deliveries, ecommerce_connections,
-- inter_branch_transfers, inventory_transactions, order_items, orders,
-- products, receipts, riders, sale_items, sales, staff_attendance,
-- subscriptions, tenants, transfer_items, users, whatsapp_messages
```

### 3. Create Test Data (Optional)

```sql
-- Create test tenant with admin user
INSERT INTO tenants (name, slug, email, phone, subscription_id)
VALUES (
    'Test Pharmacy',
    'test-pharmacy',
    'admin@testpharmacy.com',
    '+2348012345678',
    (SELECT id FROM subscriptions WHERE plan_tier = 'basic' LIMIT 1)
);

-- Create test branch
INSERT INTO branches (tenant_id, name, business_type, address, tax_rate)
VALUES (
    (SELECT id FROM tenants WHERE slug = 'test-pharmacy'),
    'Main Branch',
    'pharmacy',
    '123 Lagos Street, Ikeja, Lagos',
    7.5
);
```

---

## Next.js Application Setup

### 1. Project Structure

Verify your project structure matches:

```
kemani/
├── app/
│   ├── (auth)/              # Authentication routes
│   ├── (dashboard)/         # Protected dashboard routes
│   │   ├── pos/            # POS interface
│   │   ├── products/       # Product management
│   │   ├── orders/         # Order management
│   │   ├── customers/      # Customer management
│   │   ├── analytics/      # Analytics dashboard
│   │   └── settings/       # Tenant settings
│   ├── api/                # API routes
│   │   ├── auth/           # Auth endpoints
│   │   ├── sync/           # PowerSync webhooks
│   │   └── webhooks/       # Payment webhooks
│   ├── globals.css
│   ├── layout.tsx
│   └── page.tsx
├── components/
│   ├── ui/                 # Shadcn UI components
│   ├── pos/                # POS-specific components
│   └── shared/             # Shared components
├── lib/
│   ├── supabase/           # Supabase client & helpers
│   ├── powersync/          # PowerSync configuration
│   ├── db/                 # SQLite schema for offline
│   ├── payments/           # Payment gateway integrations
│   └── utils/              # Utility functions
├── hooks/
│   ├── use-offline.ts      # Offline detection
│   ├── use-sync.ts         # Sync status
│   └── use-auth.ts         # Authentication
├── types/
│   └── database.types.ts   # TypeScript types from Supabase
├── public/
│   ├── manifest.json       # PWA manifest
│   └── sw.js               # Service worker
├── .env.local
├── .env.example
├── next.config.ts
├── package.json
├── tsconfig.json
└── tailwind.config.ts
```

### 2. Generate TypeScript Types from Database

```bash
# Install Supabase CLI if not already installed
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Generate types
supabase gen types typescript --linked > types/database.types.ts
```

### 3. Configure Supabase Client

Create `lib/supabase/client.ts`:

```typescript
import { createBrowserClient } from '@supabase/ssr'
import type { Database } from '@/types/database.types'

export const createClient = () =>
  createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
```

Create `lib/supabase/server.ts`:

```typescript
import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { cookies } from 'next/headers'
import type { Database } from '@/types/database.types'

export const createClient = () => {
  const cookieStore = cookies()

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value
        },
        set(name: string, value: string, options: CookieOptions) {
          cookieStore.set({ name, value, ...options })
        },
        remove(name: string, options: CookieOptions) {
          cookieStore.set({ name, value: '', ...options })
        },
      },
    }
  )
}
```

### 4. Install shadcn/ui

Initialize shadcn/ui in your project:

```bash
npx shadcn@latest init
```

When prompted, select:
- **TypeScript**: Yes
- **Style**: New York (or Default - your preference)
- **Base color**: Slate (or your preference)
- **CSS variables**: Yes (recommended for theming)
- **Tailwind config**: Yes
- **Import alias**: `@/` (matches existing Next.js config)

This will:
- Configure `components.json`
- Set up Tailwind CSS configuration
- Add CSS variables to `app/globals.css`
- Create `lib/utils.ts` with `cn()` helper

### 5. Install Essential shadcn/ui Components

Install commonly needed components for POS interface:

```bash
# Core UI components
npx shadcn@latest add button
npx shadcn@latest add input
npx shadcn@latest add label
npx shadcn@latest add card
npx shadcn@latest add table
npx shadcn@latest add dialog
npx shadcn@latest add select
npx shadcn@latest add form

# Data display
npx shadcn@latest add badge
npx shadcn@latest add separator
npx shadcn@latest add tabs
npx shadcn@latest add toast

# Navigation
npx shadcn@latest add dropdown-menu
npx shadcn@latest add navigation-menu

# Feedback
npx shadcn@latest add alert
npx shadcn@latest add skeleton
npx shadcn@latest add progress
```

These components will be added to `components/ui/` directory.

### 6. Start Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in browser.

You should see the default Next.js homepage. All shadcn/ui components are now available for use.

---

## PWA Configuration

### 1. Install next-pwa

```bash
npm install next-pwa
```

### 2. Configure next.config.ts

```typescript
import withPWA from 'next-pwa'

const config = {
  // Your existing Next.js config
}

export default withPWA({
  dest: 'public',
  register: true,
  skipWaiting: true,
  disable: process.env.NODE_ENV === 'development',
})(config)
```

### 3. Create PWA Manifest

Create `public/manifest.json`:

```json
{
  "name": "Kemani POS",
  "short_name": "Kemani",
  "description": "Offline-first point of sale for Nigerian retailers",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#4F46E5",
  "orientation": "portrait",
  "icons": [
    {
      "src": "/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
```

### 4. Add Icons

Generate PWA icons using [realfavicongenerator.net](https://realfavicongenerator.net/) and place in `public/` directory.

---

## Offline Sync Setup (PowerSync)

### 1. Sign Up for PowerSync

1. Go to [powersync.com](https://powersync.com)
2. Create account (free tier available)
3. Create new PowerSync instance
4. Connect to your Supabase database:
   - Database Host: From Supabase Settings → Database → Connection String
   - Port: 5432
   - Database Name: `postgres`
   - Username: `postgres`
   - Password: Your Supabase database password

### 2. Configure Sync Rules

In PowerSync dashboard, create sync rules (`sync-rules.yaml`):

```yaml
bucket_definitions:
  # Branch-specific data
  branch_data:
    parameters:
      - SELECT branch_id FROM users WHERE id = auth.uid()
    data:
      - SELECT * FROM products WHERE branch_id = BUCKET_PARAM(branch_id)
      - SELECT * FROM sales WHERE branch_id = BUCKET_PARAM(branch_id)
      - SELECT * FROM orders WHERE branch_id = BUCKET_PARAM(branch_id)
      - SELECT * FROM deliveries WHERE branch_id = BUCKET_PARAM(branch_id)

  # Tenant-wide data (customers shared across branches)
  tenant_data:
    parameters:
      - SELECT tenant_id FROM users WHERE id = auth.uid()
    data:
      - SELECT * FROM customers WHERE tenant_id = BUCKET_PARAM(tenant_id)
```

### 3. Install PowerSync SDK

```bash
npm install @powersync/web @powersync/react
```

### 4. Configure PowerSync Client

Create `lib/powersync/client.ts`:

```typescript
import { WASQLitePowerSyncDatabaseOpenFactory } from '@powersync/web'
import { PowerSyncDatabase } from '@powersync/web'
import { schema } from './schema'

export const createPowerSyncClient = async () => {
  const factory = new WASQLitePowerSyncDatabaseOpenFactory({
    dbFilename: 'kemani.db',
    schema,
  })

  const db = new PowerSyncDatabase({
    database: factory,
    options: {
      baseUrl: process.env.NEXT_PUBLIC_POWERSYNC_URL!,
      token: process.env.NEXT_PUBLIC_POWERSYNC_TOKEN!,
    },
  })

  await db.init()
  await db.connect()

  return db
}
```

### 5. Define SQLite Schema

Create `lib/powersync/schema.ts`:

```typescript
import { column, Schema, Table } from '@powersync/web'

const products = new Table({
  id: column.text,
  name: column.text,
  unit_price: column.real,
  stock_quantity: column.integer,
  // ... other columns
})

const sales = new Table({
  id: column.text,
  total_amount: column.real,
  created_at: column.text,
  // ... other columns
})

export const schema = new Schema([products, sales])
```

---

## Payment Gateway Integration

### 1. Paystack Setup

Get test API keys:

1. Login to [paystack.com/dashboard](https://paystack.com/dashboard)
2. Go to **Settings** → **API Keys & Webhooks**
3. Copy **Test Public Key** and **Test Secret Key**

Create `lib/payments/paystack.ts`:

```typescript
import axios from 'axios'

const PAYSTACK_BASE_URL = 'https://api.paystack.co'

export class PaystackClient {
  private secretKey: string

  constructor(secretKey: string) {
    this.secretKey = secretKey
  }

  async initializeTransaction(params: {
    email: string
    amount: number // in kobo (₦100 = 10000 kobo)
    reference: string
  }) {
    const response = await axios.post(
      `${PAYSTACK_BASE_URL}/transaction/initialize`,
      params,
      {
        headers: {
          Authorization: `Bearer ${this.secretKey}`,
        },
      }
    )
    return response.data
  }

  async verifyTransaction(reference: string) {
    const response = await axios.get(
      `${PAYSTACK_BASE_URL}/transaction/verify/${reference}`,
      {
        headers: {
          Authorization: `Bearer ${this.secretKey}`,
        },
      }
    )
    return response.data
  }
}

export const paystack = new PaystackClient(
  process.env.PAYSTACK_SECRET_KEY!
)
```

### 2. Test Payment Flow

```bash
# Create test sale
curl -X POST http://localhost:3000/api/sales \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "branch_id": "...",
    "items": [...],
    "payment_method": "card",
    "total_amount": 5000
  }'

# Use Paystack test cards:
# Success: 4084084084084081
# Decline: 4084084084084081 (with CVV 999)
```

---

## Testing

### 1. Run Type Checking

```bash
npx tsc --noEmit
```

Should return no errors.

### 2. Run Linter

```bash
npm run lint
```

Fix any errors:

```bash
npm run lint -- --fix
```

### 3. Run Build

```bash
npm run build
```

Should complete successfully.

### 4. Test Offline Functionality

1. Open app in Chrome DevTools
2. Go to **Application** → **Service Workers**
3. Check "Offline" mode
4. Navigate to POS screen
5. Create sale (should work offline)
6. Check **Application** → **IndexedDB** → `kemani.db` (should see local data)
7. Uncheck "Offline"
8. Data should sync to Supabase

### 5. Test PWA Installation

1. Open app in Chrome (desktop or Android)
2. Click browser menu → **Install Kemani POS**
3. App should install and open in standalone window
4. Verify offline functionality works in installed app

---

## Troubleshooting

### Issue: "Supabase connection failed"

**Solution**:
1. Verify `.env.local` has correct `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`
2. Check Supabase project is not paused (free tier pauses after 7 days inactivity)
3. Test connection: `curl https://your-project.supabase.co/rest/v1/` (should return 401)

### Issue: "PowerSync not syncing"

**Solution**:
1. Check PowerSync instance is running: [powersync.com/dashboard](https://powersync.com/dashboard)
2. Verify sync rules are deployed
3. Check browser console for sync errors
4. Test PowerSync connection: `await db.connect()` should not throw

### Issue: "TypeScript errors in database types"

**Solution**:
```bash
# Regenerate types from latest schema
supabase gen types typescript --linked > types/database.types.ts

# Restart TypeScript server in VS Code
# Press Ctrl+Shift+P → TypeScript: Restart TS Server
```

### Issue: "Module not found: Can't resolve 'wa-sqlite'"

**Solution**:
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

### Issue: "CORS error when calling Paystack API"

**Solution**:
- Never call Paystack from client-side (exposes secret key)
- Use Next.js API routes: `/api/payments/paystack-*`
- Example: `POST /api/payments/paystack-initialize` → calls Paystack server-side

### Issue: "RLS policy prevents data access"

**Solution**:
1. Verify user is authenticated: `const { data: { user } } = await supabase.auth.getUser()`
2. Check user has `tenant_id`: `SELECT tenant_id FROM users WHERE id = auth.uid()`
3. Test RLS policy: `SET LOCAL request.jwt.claim.sub = 'user-uuid'; SELECT * FROM products;`

---

## Next Steps

Once development environment is set up:

1. **Read the Constitution**: Review `.specify/memory/constitution.md` for coding standards
2. **Review Data Model**: Study `specs/001-multi-tenant-pos/data-model.md`
3. **Check API Contracts**: Reference `specs/001-multi-tenant-pos/contracts/api-schema.yaml`
4. **Start Implementation**: Follow `specs/001-multi-tenant-pos/tasks.md` (when generated)

---

## Useful Commands

```bash
# Development
npm run dev                  # Start dev server
npm run build                # Production build
npm run lint                 # Run ESLint
npx tsc --noEmit            # Type check

# Database
supabase db push            # Push migrations to Supabase
supabase db reset           # Reset database (⚠️ destroys data)
supabase gen types typescript --linked > types/database.types.ts

# Supabase Local Development (Optional)
supabase start              # Start local Supabase (Docker required)
supabase stop               # Stop local Supabase
```

---

## Additional Resources

- **Next.js Documentation**: [nextjs.org/docs](https://nextjs.org/docs)
- **Supabase Documentation**: [supabase.com/docs](https://supabase.com/docs)
- **PowerSync Documentation**: [docs.powersync.com](https://docs.powersync.com)
- **Paystack API Docs**: [paystack.com/docs/api](https://paystack.com/docs/api)
- **TypeScript Handbook**: [typescriptlang.org/docs](https://www.typescriptlang.org/docs/)

---

**Need Help?**

- Check project README.md
- Review specification: `specs/001-multi-tenant-pos/spec.md`
- Contact development team

---

**Status**: ✅ Quickstart Guide Complete | **Last Updated**: 2026-01-17
