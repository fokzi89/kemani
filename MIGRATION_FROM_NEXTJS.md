# Migration from Next.js to SvelteKit/Flutter

## Overview

This document describes the migration of the Kemani project from a Next.js monolithic architecture to a multi-platform architecture using SvelteKit and Flutter.

## Migration Summary

**Date:** February 24, 2026

**Previous Architecture:**
- Next.js 16 with App Router
- React 19 components
- Next.js API routes
- Single monolithic application

**New Architecture:**
- **SvelteKit apps** for public-facing web (marketing, storefront, healthcare customer)
- **Flutter apps** for admin interfaces (POS admin, healthcare medic)
- **Supabase** for backend (unchanged)
- **Monorepo** structure with independent apps

## What Was Removed

### Configuration Files
- `next.config.ts` - Next.js configuration
- `middleware.ts` - Next.js Edge middleware
- `tsconfig.json` - TypeScript configuration (Next.js specific)
- `postcss.config.mjs` - PostCSS configuration
- `tailwind.config.ts` - Tailwind configuration (root level)
- `eslint.config.mjs` - ESLint configuration (Next.js specific)
- `components.json` - shadcn/ui configuration
- `package.json` & `package-lock.json` - Root dependencies

### Application Code
- **`app/` directory** - All Next.js pages and routes
  - Route groups: `(auth)`, `(pos)`, `(admin)`
  - Pages: login, register, verify-otp, POS, inventory, analytics, sales
  - `app/api/` - All 20 API routes (auth, sales, products, analytics, webhooks)

### Components and UI
- **`components/` directory** - All React components
  - UI components (shadcn/ui): buttons, cards, forms, dialogs, etc.
  - Feature components: auth, POS, sales, offline sync
  - Layout components: header, sidebar, footer
  - Providers: theme, PowerSync, sales auto-sync

### Hooks and Utilities
- **`hooks/` directory** - All React hooks
  - useAuth, useNetworkStatus, useQueueCount, useSyncManager, etc.

- **`lib/` directory** - All Next.js-specific utilities
  - Supabase client/server/middleware integration
  - Auth utilities (OTP, session, SMS, tenant)
  - POS utilities (inventory, products, receipts, transactions)
  - Analytics, sync, offline support
  - IndexedDB integration
  - Payment integrations (Paystack, Flutterwave)
  - Validation schemas

### Public Assets
- **`public/` directory** - Next.js specific assets
  - next.svg, vercel.svg
  - manifest.json (PWA)
  - Various SVG icons

### Type Definitions
- **`types/` directory** - TypeScript definitions
  - database.types.ts (Supabase types - will be regenerated per app)
  - modules.d.ts

### Scripts
- **`scripts/` directory** - Next.js specific scripts
  - Database type generation
  - Table verification scripts
  - RLS policy verification

## What Was Preserved

### Database
- **`supabase/` directory** - All database migrations
  - Multi-tenant POS system migrations
  - Healthcare consultation system migrations
  - RLS policies

### Documentation
- **`specs/` directory** - SpecKit feature specifications
- **`docs/` directory** - Documentation files
- Migration guides and testing documentation

### Configuration
- **`.specify/` directory** - SpecKit workflow system
- **`.claude/` directory** - Claude Code configuration
- **`.env.example`** - Environment variable template
- **`.gitignore`** - Git ignore rules

### Existing Apps
- **`apps/marketing_sveltekit/`** - Already created SvelteKit marketing site
- **`apps/storefront/`** - Existing storefront (needs completion)
- **`apps/web_client/`** - Legacy Flutter web client

## New Architecture

### Apps to be Created

1. **Healthcare Customer Interface** (SvelteKit)
   - Location: `apps/healthcare_customer/`
   - Purpose: Patient/customer consultation booking and management
   - Tech: SvelteKit, Tailwind CSS, Supabase

2. **POS Admin** (Flutter)
   - Location: `apps/pos_admin/`
   - Purpose: Point-of-sale administration dashboard
   - Tech: Flutter, Supabase Flutter SDK
   - Platforms: Web, Windows, Android, iOS

3. **Healthcare Medic Interface** (Flutter)
   - Location: `apps/healthcare_medic/`
   - Purpose: Healthcare provider/medic tools
   - Tech: Flutter, Supabase Flutter SDK
   - Platforms: Web, mobile, desktop

### Technology Mapping

| Feature | Next.js | New Stack |
|---------|---------|-----------|
| Marketing pages | React components | SvelteKit |
| Pricing page | React component | SvelteKit |
| Landing page | React component | SvelteKit |
| POS admin | React + API routes | Flutter |
| Healthcare customer | N/A | SvelteKit |
| Healthcare medic | N/A | Flutter |
| Authentication | next-auth + API routes | Supabase Auth (direct) |
| Database queries | Server components + API routes | Direct Supabase client calls |
| Offline sync | IndexedDB + custom sync | Flutter local database / Hive |
| Real-time | Supabase realtime | Supabase realtime (unchanged) |
| Styling | Tailwind CSS 4 | Tailwind CSS 4 (SvelteKit) / Flutter Material |

## Code Migration Guide

### From React to Svelte

**React Component:**
```jsx
// app/components/Button.tsx
export function Button({ onClick, children }) {
  return <button onClick={onClick}>{children}</button>
}
```

**Svelte Component:**
```svelte
<!-- lib/components/Button.svelte -->
<script lang="ts">
  export let onClick: () => void
</script>

<button on:click={onClick}>
  <slot />
</button>
```

### From React to Flutter

**React Component:**
```jsx
// app/components/ProductCard.tsx
export function ProductCard({ product, onSelect }) {
  return (
    <div onClick={() => onSelect(product)}>
      <h3>{product.name}</h3>
      <p>${product.price}</p>
    </div>
  )
}
```

**Flutter Widget:**
```dart
// lib/widgets/product_card.dart
class ProductCard extends StatelessWidget {
  final Product product;
  final Function(Product) onSelect;

  const ProductCard({required this.product, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect(product),
      child: Column(
        children: [
          Text(product.name),
          Text('\$${product.price}'),
        ],
      ),
    );
  }
}
```

### From Next.js API Routes to Supabase Direct Calls

**Next.js API Route:**
```typescript
// app/api/products/route.ts
export async function GET() {
  const supabase = createServerClient()
  const { data } = await supabase.from('products').select('*')
  return Response.json(data)
}
```

**SvelteKit Direct Call:**
```typescript
// routes/products/+page.server.ts
import { createServerClient } from '$lib/supabase'

export async function load() {
  const supabase = createServerClient()
  const { data: products } = await supabase.from('products').select('*')
  return { products }
}
```

**Flutter Direct Call:**
```dart
// services/product_service.dart
class ProductService {
  final supabase = Supabase.instance.client;

  Future<List<Product>> getProducts() async {
    final response = await supabase.from('products').select();
    return response.map((json) => Product.fromJson(json)).toList();
  }
}
```

## Benefits of New Architecture

### Separation of Concerns
- **Public web** (marketing, customer interfaces) use SvelteKit
  - Better SEO
  - Faster page loads
  - Simpler SSR

- **Admin/professional tools** use Flutter
  - Cross-platform from single codebase
  - Native performance
  - Offline-first capabilities
  - Consistent UI across platforms

### Performance
- SvelteKit apps are lighter than React equivalents
- Flutter provides native performance for admin tools
- Direct Supabase calls eliminate unnecessary API layer

### Developer Experience
- Svelte has less boilerplate than React
- Flutter hot reload for fast iteration
- Each app is independently deployable
- Clear boundaries between projects

### Scalability
- Apps can be deployed independently
- Teams can work on different apps without conflicts
- Easy to add new apps for new use cases

## Migration Checklist

- [x] Remove all Next.js configuration files
- [x] Remove Next.js app directory
- [x] Remove Next.js API routes
- [x] Remove React components
- [x] Remove React hooks
- [x] Remove Next.js utilities and libraries
- [x] Update CLAUDE.md documentation
- [x] Create ARCHITECTURE.md
- [x] Create migration documentation
- [ ] Set up healthcare_customer SvelteKit app
- [ ] Set up pos_admin Flutter app
- [ ] Set up healthcare_medic Flutter app
- [ ] Implement authentication in new apps
- [ ] Migrate business logic to new apps
- [ ] Set up CI/CD for new apps
- [ ] Deploy new apps to production

## Next Steps

1. **Set up development environment**
   - Install Flutter SDK
   - Install Node.js (for SvelteKit)
   - Install Supabase CLI

2. **Create new apps**
   - Initialize SvelteKit apps
   - Initialize Flutter apps
   - Configure Supabase clients

3. **Implement core features**
   - Authentication flow
   - Database queries
   - UI components
   - Business logic

4. **Testing**
   - Unit tests
   - Integration tests
   - E2E tests

5. **Deployment**
   - Set up hosting
   - Configure environment variables
   - Deploy to production

## Resources

- [SvelteKit Documentation](https://kit.svelte.dev/)
- [Flutter Documentation](https://flutter.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter SDK](https://supabase.com/docs/reference/dart/introduction)

## Questions?

Refer to:
- `ARCHITECTURE.md` for architectural decisions
- `CLAUDE.md` for development workflow
- `specs/` for feature specifications
