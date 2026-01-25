# Developer Quickstart Guide

**Feature**: Multi-Tenant POS-First Super App Platform
**Branch**: `001-multi-tenant-pos`
**Last Updated**: 2026-01-24

## Introduction

This guide will help you set up the multi-tenant POS platform development environment and get you productive in under 30 minutes. The platform is built with Next.js 16 (App Router), TypeScript, React 19, Tailwind CSS 4, and Supabase.

**Platform Overview**: An offline-first POS system for Nigerian independent businesses (pharmacies, supermarkets, grocery shops) with cloud sync, marketplace, delivery management, and integrations.

---

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

- **Node.js**: v20.x or higher (v25.2.1 confirmed working)
  - Check: `node --version`
  - Download: [nodejs.org](https://nodejs.org/)

- **npm**: v9.x or higher (comes with Node.js)
  - Check: `npm --version`

- **Git**: Latest version
  - Check: `git --version`
  - Download: [git-scm.com](https://git-scm.com/)

- **Supabase CLI**: For local development and migrations
  ```bash
  npm install -g supabase
  ```
  - Check: `supabase --version`
  - Docs: [supabase.com/docs/guides/cli](https://supabase.com/docs/guides/cli)

### Optional but Recommended

- **Docker Desktop**: For local Supabase instance (alternative: use cloud project)
  - Download: [docker.com](https://www.docker.com/products/docker-desktop/)

- **VSCode**: Recommended code editor with extensions:
  - ESLint
  - Prettier
  - TypeScript and JavaScript Language Features
  - Tailwind CSS IntelliSense
  - Supabase (SQL syntax highlighting)

---

## Quick Start (5 Minutes)

### 1. Clone Repository

```bash
git clone <repository-url>
cd kemani
```

### 2. Checkout Feature Branch

```bash
git checkout 001-multi-tenant-pos
```

### 3. Install Dependencies

```bash
npm install
```

This installs all dependencies including:
- Next.js 16.1.3
- React 19.2.3
- Supabase client libraries (@supabase/ssr, @supabase/supabase-js)
- Tailwind CSS 4
- PowerSync (offline sync)
- shadcn/ui components
- And more (see `package.json`)

### 4. Set Up Environment Variables

Copy the example environment file:

```bash
cp .env.example .env.local
```

Edit `.env.local` and add your configuration:

```bash
# Supabase Configuration (Required)
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# SMS Provider - Termii (Required for phone auth)
TERMII_API_KEY=your-termii-api-key
TERMII_SENDER_ID=Kemani

# App Configuration
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development

# Security
JWT_SECRET=your-random-secret-key-change-this
RATE_LIMIT_MAX_REQUESTS=3
RATE_LIMIT_WINDOW_MS=3600000

# Optional: PowerSync (for advanced offline sync)
# POWERSYNC_URL=your-powersync-url
```

**Getting Supabase Credentials**:
1. Create account at [supabase.com](https://supabase.com)
2. Create new project
3. Go to Settings → API
4. Copy `Project URL` → `NEXT_PUBLIC_SUPABASE_URL`
5. Copy `anon/public` key → `NEXT_PUBLIC_SUPABASE_ANON_KEY`
6. Copy `service_role` key → `SUPABASE_SERVICE_ROLE_KEY` (keep secret!)

**Getting Termii API Key**:
1. Sign up at [termii.com](https://termii.com)
2. Get API key from dashboard
3. Add to `.env.local`

### 5. Run Database Migrations

**Option A: Using Cloud Supabase Project**

Link your local project to Supabase:

```bash
supabase link --project-ref your-project-ref
```

Push migrations to cloud:

```bash
supabase db push
```

**Option B: Using Local Supabase (Docker)**

Start local Supabase:

```bash
supabase start
```

This will:
- Start PostgreSQL database
- Start Supabase services (Auth, Storage, Realtime)
- Apply all migrations in `supabase/migrations/`
- Output local credentials

### 6. Generate TypeScript Types

After migrations are applied, generate TypeScript types from database:

```bash
# For cloud database
supabase gen types typescript --project-ref your-project-ref > types/database.types.ts

# For local database
supabase gen types typescript --local > types/database.types.ts
```

### 7. Start Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

**You're ready to develop! 🚀**

---

## Project Structure Overview

```
kemani/
├── app/                          # Next.js 16 App Router
│   ├── (auth)/                   # Auth route group (login, register)
│   ├── (dashboard)/              # Dashboard route group (authenticated)
│   │   ├── pos/                  # POS interface
│   │   ├── inventory/            # Inventory management
│   │   ├── orders/               # Order management
│   │   ├── customers/            # Customer management
│   │   ├── staff/                # Staff management
│   │   ├── delivery/             # Delivery management
│   │   ├── analytics/            # Analytics dashboards
│   │   ├── settings/             # Tenant settings
│   │   └── integrations/         # E-commerce, WhatsApp integrations
│   ├── (marketplace)/            # Public marketplace route group
│   │   └── [tenantSlug]/         # Dynamic tenant storefronts
│   ├── (landing)/                # Landing and marketing pages
│   ├── api/                      # API routes
│   │   ├── auth/                 # Auth endpoints (OTP)
│   │   ├── pos/                  # POS operations
│   │   ├── sync/                 # Offline sync endpoints
│   │   ├── webhooks/             # Webhook handlers
│   │   └── chat/                 # AI chat agent endpoints
│   ├── components/               # Shared components
│   │   └── ui/                   # UI primitives (buttons, forms, modals)
│   ├── layout.tsx                # Root layout
│   ├── page.tsx                  # Landing page
│   └── globals.css               # Global styles
│
├── lib/                          # Shared business logic
│   ├── auth/                     # Authentication utilities
│   │   ├── otp.ts                # OTP generation/verification
│   │   └── session.ts            # Session management
│   ├── db/                       # Database utilities (if needed)
│   ├── integrations/             # Third-party integrations
│   │   ├── woocommerce.ts        # WooCommerce sync (planned)
│   │   ├── shopify.ts            # Shopify sync (planned)
│   │   ├── whatsapp.ts           # WhatsApp Business API (planned)
│   │   └── payments.ts           # Paystack/Flutterwave (planned)
│   ├── offline/                  # Offline-first utilities
│   │   ├── storage.ts            # Local storage abstraction (planned)
│   │   ├── queue.ts              # Sync queue management (planned)
│   │   └── conflict.ts           # Conflict resolution (planned)
│   └── utils/                    # General utilities
│       ├── validation.ts         # Zod schemas
│       ├── formatting.ts         # Number, date, currency formatting
│       ├── errors.ts             # Error handling
│       ├── logger.ts             # Logging utilities
│       ├── distance.ts           # Distance calculations
│       └── index.ts              # Utility exports
│
├── types/                        # TypeScript type definitions
│   ├── database.types.ts         # Supabase generated types
│   ├── modules.d.ts              # Module declarations
│   └── api.types.ts              # API request/response types (planned)
│
├── components/                   # Additional shared components
│   └── ui/                       # shadcn/ui components
│
├── supabase/                     # Supabase configuration
│   └── migrations/               # Database migrations (25+ files)
│       ├── 001_extensions_and_enums.sql
│       ├── 002_core_tables.sql
│       ├── 003_product_inventory_tables.sql
│       └── ... (see directory for full list)
│
├── specs/                        # Feature specifications
│   └── 001-multi-tenant-pos/     # This feature
│       ├── spec.md               # Feature specification
│       ├── plan.md               # Implementation plan
│       ├── data-model.md         # Database schema
│       ├── quickstart.md         # This file
│       ├── contracts/            # API contracts (to be created)
│       └── tasks.md              # Implementation tasks
│
├── .specify/                     # SpecKit workflow system
│   ├── templates/                # Spec, plan, tasks templates
│   ├── memory/                   # Constitution and memory
│   │   └── constitution.md       # Code standards and principles
│   └── scripts/                  # Automation scripts
│
├── public/                       # Static assets
├── tests/                        # Test files (when written)
├── package.json                  # Dependencies and scripts
├── tsconfig.json                 # TypeScript configuration
├── next.config.ts                # Next.js configuration
├── tailwind.config.ts            # Tailwind CSS configuration
└── .env.local                    # Environment variables (not committed)
```

### Where to Find What

| What You Need | Where to Look |
|---------------|---------------|
| **Components** | `app/components/` (shared), `components/ui/` (primitives) |
| **API Routes** | `app/api/` |
| **Business Logic** | `lib/` |
| **Type Definitions** | `types/` |
| **Migrations** | `supabase/migrations/` |
| **Specifications** | `specs/001-multi-tenant-pos/` |
| **Code Standards** | `.specify/memory/constitution.md` |
| **Utilities** | `lib/utils/` |

---

## Common Development Tasks

### Running the App

```bash
# Development server (http://localhost:3000)
npm run dev

# Production build
npm run build

# Start production server (after build)
npm start
```

### Code Quality

```bash
# Type checking
npx tsc --noEmit

# Linting
npm run lint

# Linting with auto-fix
npm run lint -- --fix
```

### Testing

Tests are optional but recommended for critical paths. When tests are written:

```bash
# Run all tests (if test script exists)
npm test

# Run E2E tests (if configured)
npm run test:e2e

# Run specific test file
npm test path/to/test.test.ts
```

### Database Operations

```bash
# Create new migration
supabase migration new migration_name

# Push migrations to cloud database
supabase db push

# Pull remote schema changes
supabase db pull

# Reset local database (destructive!)
supabase db reset

# Generate TypeScript types from database schema
supabase gen types typescript --local > types/database.types.ts

# For cloud database
supabase gen types typescript --project-ref your-project-ref > types/database.types.ts
```

### Local Supabase Development

```bash
# Start Supabase services (requires Docker)
supabase start

# Stop Supabase services
supabase stop

# View Supabase status
supabase status

# Access local Studio UI
# Opens at: http://localhost:54323
```

---

## Key Workflows

### 1. Creating a New API Endpoint

**Example**: Create a new endpoint to fetch products.

**File**: `app/api/products/route.ts`

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import type { Database } from '@/types/database.types';

export async function GET(request: NextRequest) {
  try {
    const supabase = createClient<Database>(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY!
    );

    const { data, error } = await supabase
      .from('products')
      .select('*')
      .limit(50);

    if (error) {
      return NextResponse.json(
        { error: error.message },
        { status: 500 }
      );
    }

    return NextResponse.json({ products: data });
  } catch (error) {
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
```

**Test**:
```bash
curl http://localhost:3000/api/products
```

### 2. Adding a New Database Table

**Step 1**: Create migration

```bash
supabase migration new add_promotions_table
```

**Step 2**: Edit migration file in `supabase/migrations/`

```sql
CREATE TABLE promotions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  discount_percent DECIMAL(5,2),
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policy
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "promotions_tenant_isolation" ON promotions
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Index
CREATE INDEX idx_promotions_tenant_id ON promotions(tenant_id);

-- Updated at trigger
CREATE TRIGGER set_promotions_updated_at BEFORE UPDATE ON promotions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

**Step 3**: Apply migration

```bash
supabase db push
```

**Step 4**: Regenerate types

```bash
supabase gen types typescript --local > types/database.types.ts
```

### 3. Building a New Component

**Example**: Create a product card component.

**File**: `app/components/product-card.tsx`

```typescript
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardFooter } from '@/components/ui/card';

interface ProductCardProps {
  id: string;
  name: string;
  price: number;
  imageUrl?: string;
  onAddToCart: (id: string) => void;
}

export default function ProductCard({
  id,
  name,
  price,
  imageUrl,
  onAddToCart,
}: ProductCardProps) {
  const [isAdding, setIsAdding] = useState(false);

  const handleClick = async () => {
    setIsAdding(true);
    await onAddToCart(id);
    setIsAdding(false);
  };

  return (
    <Card className="w-full">
      {imageUrl && (
        <img
          src={imageUrl}
          alt={name}
          className="w-full h-48 object-cover rounded-t-lg"
        />
      )}
      <CardContent className="pt-4">
        <h3 className="font-semibold text-lg">{name}</h3>
        <p className="text-xl font-bold text-green-600 mt-2">
          ₦{price.toLocaleString()}
        </p>
      </CardContent>
      <CardFooter>
        <Button
          onClick={handleClick}
          disabled={isAdding}
          className="w-full"
        >
          {isAdding ? 'Adding...' : 'Add to Cart'}
        </Button>
      </CardFooter>
    </Card>
  );
}
```

**Usage**:

```typescript
import ProductCard from '@/app/components/product-card';

<ProductCard
  id="123"
  name="Paracetamol"
  price={500}
  onAddToCart={handleAddToCart}
/>
```

### 4. Writing Tests (When Needed)

Tests are optional but recommended for critical paths. Example integration test:

**File**: `tests/integration/auth.test.ts`

```typescript
import { describe, it, expect } from 'vitest';
// or import from your chosen testing framework

describe('Authentication', () => {
  it('should send OTP to valid phone number', async () => {
    const response = await fetch('http://localhost:3000/api/auth/send-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phoneNumber: '+2348012345678' }),
    });

    expect(response.status).toBe(200);
    const data = await response.json();
    expect(data.success).toBe(true);
  });
});
```

### 5. Working Offline (Testing Offline Features)

The platform is offline-first. To test offline functionality:

**In Chrome DevTools**:
1. Open DevTools (F12)
2. Network tab → "Offline" checkbox
3. Or "No throttling" → "Offline"

**Testing Offline POS**:
1. Start the app online
2. Go to POS interface
3. Enable offline mode in DevTools
4. Process a sale
5. Check IndexedDB for pending sync queue
6. Re-enable network
7. Verify automatic sync to Supabase

**Debugging Offline Storage**:

- **Chrome DevTools** → Application → IndexedDB → `kemani_offline`
- Inspect tables: `products`, `sales`, `sync_queue`

---

## Environment Variables Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL | `https://abc123.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon/public key | `eyJhbG...` (long string) |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key (server-only) | `eyJhbG...` (long string) |
| `TERMII_API_KEY` | Termii SMS API key for OTP | `TL...` |
| `TERMII_SENDER_ID` | SMS sender name | `Kemani` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NEXT_PUBLIC_APP_URL` | Base URL of your app | `http://localhost:3000` |
| `NODE_ENV` | Environment | `development` |
| `JWT_SECRET` | JWT signing secret | Generate random string |
| `RATE_LIMIT_MAX_REQUESTS` | Max API requests per window | `3` |
| `RATE_LIMIT_WINDOW_MS` | Rate limit window (ms) | `3600000` (1 hour) |
| `POWERSYNC_URL` | PowerSync URL (advanced offline) | - |
| `PAYSTACK_SECRET_KEY` | Paystack payment gateway | - |
| `FLUTTERWAVE_SECRET_KEY` | Flutterwave payment gateway | - |
| `OPENAI_API_KEY` | OpenAI for AI chat agent | - |
| `WHATSAPP_BUSINESS_API_KEY` | WhatsApp Business API | - |

### Development vs Production

**Development** (`.env.local`):
- Use local Supabase or cloud dev project
- Use Termii test mode
- Enable verbose logging

**Production** (Vercel/hosting platform):
- Use production Supabase project
- Use production API keys
- Disable verbose logging
- Enable rate limiting

---

## Troubleshooting

### Common Errors and Solutions

#### 1. "Module not found" errors

**Error**: `Cannot find module '@/lib/...'`

**Solution**:
```bash
# Clear Next.js cache
rm -rf .next
npm run dev
```

#### 2. Supabase connection issues

**Error**: `Failed to connect to Supabase`

**Solutions**:
- Check `.env.local` has correct `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- Verify keys don't have trailing spaces
- Check Supabase project is active in dashboard
- For local Supabase: Ensure Docker is running and `supabase start` succeeded

#### 3. Type generation problems

**Error**: `supabase gen types` fails

**Solutions**:
```bash
# For local development
supabase db reset
supabase gen types typescript --local > types/database.types.ts

# For cloud database
supabase gen types typescript --project-ref your-project-ref --schema public > types/database.types.ts
```

#### 4. Build errors

**Error**: `Type error: ...` or `Build failed`

**Solutions**:
```bash
# Check TypeScript errors
npx tsc --noEmit

# Fix linting errors
npm run lint -- --fix

# Clear cache and rebuild
rm -rf .next
npm run build
```

#### 5. Database migration conflicts

**Error**: `Migration already applied` or `Migration conflicts`

**Solutions**:
```bash
# For local development (destructive!)
supabase db reset

# For production - manually resolve conflicts
# Check migration history:
supabase migration list

# Create new migration to fix conflicts
supabase migration new fix_migration_conflict
```

#### 6. Port already in use

**Error**: `Port 3000 is already in use`

**Solutions**:
```bash
# Windows: Kill process on port 3000
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Or use different port
PORT=3001 npm run dev
```

#### 7. Environment variables not loading

**Error**: `process.env.NEXT_PUBLIC_... is undefined`

**Solutions**:
- Ensure `.env.local` exists in project root
- Restart dev server after changing `.env.local`
- Check variable names start with `NEXT_PUBLIC_` for client-side access
- For server-only variables, access in API routes or Server Components only

#### 8. Migration order issues

**Error**: Migrations fail due to dependency conflicts

**Solution**:
The project has 25+ migration files. They should be applied in order:
1. `001_extensions_and_enums.sql` (extensions, enums)
2. `002_core_tables.sql` (tenants, users, branches)
3. `003_product_inventory_tables.sql` (products, categories)
4. `004_customer_sales_tables.sql` (customers, sales)
5. And so on...

If migrations fail:
```bash
# Reset and reapply (local only!)
supabase db reset

# For cloud - manually check which migrations applied
SELECT * FROM supabase_migrations.schema_migrations;
```

---

## Resources

### Project Documentation

- **[spec.md](./spec.md)**: Feature specification with user stories and requirements
- **[plan.md](./plan.md)**: Technical implementation plan and architecture
- **[data-model.md](./data-model.md)**: Complete database schema and relationships
- **[tasks.md](./tasks.md)**: Implementation tasks and progress tracking
- **[constitution.md](../../.specify/memory/constitution.md)**: Code standards and principles

### External Documentation

#### Next.js 16
- [Next.js Docs](https://nextjs.org/docs)
- [App Router Guide](https://nextjs.org/docs/app)
- [Server Components](https://nextjs.org/docs/app/building-your-application/rendering/server-components)
- [Data Fetching](https://nextjs.org/docs/app/building-your-application/data-fetching)

#### React 19
- [React Docs](https://react.dev/)
- [Hooks Reference](https://react.dev/reference/react)

#### Supabase
- [Supabase Docs](https://supabase.com/docs)
- [Database Guide](https://supabase.com/docs/guides/database)
- [Auth Guide](https://supabase.com/docs/guides/auth)
- [Realtime Guide](https://supabase.com/docs/guides/realtime)
- [CLI Reference](https://supabase.com/docs/reference/cli)

#### TypeScript
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
- [TypeScript with React](https://react-typescript-cheatsheet.netlify.app/)

#### Tailwind CSS 4
- [Tailwind Docs](https://tailwindcss.com/docs)
- [Utility Classes](https://tailwindcss.com/docs/utility-first)

#### Testing (Optional)
- [Vitest Docs](https://vitest.dev/)
- [Playwright Docs](https://playwright.dev/)
- [Testing Library](https://testing-library.com/)

#### Offline-First
- [PowerSync Docs](https://docs.powersync.com/)
- [IndexedDB API](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API)

### Nigerian-Specific Integrations

- **SMS**: [Termii Docs](https://developers.termii.com/)
- **Payments**:
  - [Paystack Docs](https://paystack.com/docs)
  - [Flutterwave Docs](https://developer.flutterwave.com/docs)
- **WhatsApp**: [WhatsApp Business API](https://developers.facebook.com/docs/whatsapp)

---

## Getting Help

### Internal Resources

1. **Specifications**: Check `specs/001-multi-tenant-pos/` for detailed requirements
2. **Constitution**: Review `.specify/memory/constitution.md` for code standards
3. **Data Model**: Reference `specs/001-multi-tenant-pos/data-model.md` for database schema

### Team Communication

- Ask questions in team chat/Slack
- Create GitHub issues for bugs or feature requests
- Use pull requests for code review discussions

### External Resources

- **Next.js Discord**: [nextjs.org/discord](https://nextjs.org/discord)
- **Supabase Discord**: [discord.supabase.com](https://discord.supabase.com)
- **Stack Overflow**: Tag questions with `nextjs`, `supabase`, `typescript`

---

## Next Steps

Now that you're set up, here's what to work on:

### For New Developers

1. **Explore the codebase**:
   - Read `specs/001-multi-tenant-pos/spec.md` to understand the feature
   - Browse `app/` directory to see route structure
   - Check `lib/` for business logic
   - Review existing migrations in `supabase/migrations/`

2. **Run the app**:
   - Start dev server: `npm run dev`
   - Open [http://localhost:3000](http://localhost:3000)
   - Explore landing page, auth flows, dashboard

3. **Make a small change**:
   - Edit `app/page.tsx` to change landing page text
   - See hot reload in action
   - Create a pull request

### For Active Development

1. **Check tasks**: Review `specs/001-multi-tenant-pos/tasks.md` for current tasks
2. **Pick a task**: Start with tasks marked as "pending" in your phase
3. **Create feature branch**: Follow `[number]-[short-name]` pattern
4. **Develop**: Follow constitution guidelines in `.specify/memory/constitution.md`
5. **Test**: Verify changes work offline and online
6. **Submit PR**: Include spec references and clear description

### Learning Path

**Week 1**: Understand architecture, set up environment, explore codebase
**Week 2**: Build simple components, understand offline sync
**Week 3**: Implement features, write tests (optional)
**Week 4**: Code reviews, refine, contribute to documentation

---

## Appendix

### Naming Conventions

- **Files**: `kebab-case.ts`, `PascalCase.tsx` (components)
- **Components**: `PascalCase` (e.g., `ProductCard`)
- **Functions**: `camelCase` (e.g., `handleAddToCart`)
- **Types/Interfaces**: `PascalCase` (e.g., `Product`, `CartItem`)
- **Constants**: `SCREAMING_SNAKE_CASE` (e.g., `MAX_ITEMS`)
- **Database tables**: `snake_case` (e.g., `product_categories`)

### Keyboard Shortcuts (VSCode)

| Action | Shortcut |
|--------|----------|
| Quick Open File | `Ctrl+P` / `Cmd+P` |
| Go to Definition | `F12` |
| Find References | `Shift+F12` |
| Rename Symbol | `F2` |
| Format Document | `Shift+Alt+F` |
| Command Palette | `Ctrl+Shift+P` / `Cmd+Shift+P` |
| Toggle Terminal | `` Ctrl+` `` |

### Git Workflow Tips

```bash
# Create feature branch
git checkout -b 3-inventory-import

# Stage changes
git add .

# Commit with clear message
git commit -m "feat: Add CSV inventory import feature"

# Push to remote
git push origin 3-inventory-import

# Create pull request on GitHub/GitLab
```

### Performance Tips

- Use Server Components by default (faster initial load)
- Use `'use client'` only when needed (interactivity, hooks)
- Lazy load heavy components with `dynamic()`
- Optimize images with `next/image`
- Enable Turbopack for faster builds: `next dev --turbo`

### Database Schema Reference

The project has comprehensive database schema with 25+ tables:

**Core Tables**:
- `tenants` - Multi-tenant businesses
- `users` - User accounts with roles
- `branches` - Physical locations
- `staff_invites` - Email invitations for staff

**Product Management**:
- `products` - Product catalog
- `product_categories` - Product categorization
- `product_variants` - Product variations
- `inventory_transactions` - Inventory audit log

**Sales & Transactions**:
- `sales` - Completed sales
- `sale_items` - Line items
- `customers` - Customer profiles
- `customer_addresses` - Delivery addresses

**Orders & Delivery**:
- `orders` - Customer orders
- `order_items` - Order line items
- `deliveries` - Delivery tasks
- `riders` - Delivery personnel

**Integrations**:
- `ecommerce_connections` - Platform integrations
- `sync_logs` - Sync operation logs
- `chat_conversations` - AI chat sessions
- `chat_messages` - Chat message history
- `whatsapp_messages` - WhatsApp communication

**Monetization**:
- `subscriptions` - Subscription plans
- `commissions` - Platform commission tracking
- `invoices` - Monthly billing

**Utilities**:
- `staff_attendance` - Time tracking
- `receipts` - Transaction receipts
- `sync_queue` - Offline sync queue
- `audit_logs` - System audit trail

See `specs/001-multi-tenant-pos/data-model.md` for complete schema documentation.

---

**Happy coding! 🚀**

If you get stuck, check the [Troubleshooting](#troubleshooting) section or reach out to the team.

---

**Status**: ✅ Quickstart Guide Complete | **Version**: 2.0.0 | **Last Updated**: 2026-01-24
