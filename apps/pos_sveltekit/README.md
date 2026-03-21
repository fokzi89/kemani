# POS Admin - SvelteKit

Modern, responsive Point-of-Sale administration dashboard built with SvelteKit, Tailwind CSS, and Supabase.

## Tech Stack

- **Framework:** SvelteKit 2.0 with Svelte 5 (runes mode)
- **Styling:** Tailwind CSS 4
- **Backend:** Supabase (PostgreSQL + Auth)
- **Icons:** lucide-svelte
- **Language:** TypeScript

## Features

### ✅ Currently Implemented

- Dashboard with business metrics
- Responsive sidebar navigation
- Authentication gating
- Multi-tenant support

### 🚧 In Development

See [MIGRATION_PLAN.md](./MIGRATION_PLAN.md) for detailed feature roadmap.

**Phase 1 (MVP):**
- Authentication (Login, Signup, Onboarding)
- POS Interface (Sales processing)
- Product Management (CRUD)
- Customer Management
- Order Management

**Phase 2:**
- Analytics & Reporting
- Staff Management
- Advanced Settings

**Phase 3:**
- Chat/Communication
- Inventory Management
- Offline Capability

## Getting Started

### Prerequisites

- Node.js 18+
- npm or pnpm
- Supabase account

### Installation

```bash
# Navigate to the app directory
cd apps/pos_sveltekit

# Install dependencies
npm install

# Start development server
npm run dev
```

The app will be available at: **http://localhost:5175**

### Environment Setup

Create a `.env` file in the app root:

```env
PUBLIC_SUPABASE_URL=your_supabase_project_url
PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

Or use the shared Supabase credentials from `apps/healthcare_medic/src/lib/supabase.ts`.

## Project Structure

```
pos_sveltekit/
├── src/
│   ├── lib/
│   │   ├── components/        # Reusable UI components
│   │   ├── supabase.ts        # Supabase client configuration
│   │   └── utils/             # Utility functions
│   ├── routes/
│   │   ├── auth/              # Authentication pages
│   │   │   └── login/
│   │   ├── products/          # Product management (TODO)
│   │   ├── customers/         # Customer management (TODO)
│   │   ├── orders/            # Order management (TODO)
│   │   ├── pos/               # POS interface (TODO)
│   │   ├── analytics/         # Analytics (TODO)
│   │   ├── settings/          # Settings (TODO)
│   │   ├── +layout.svelte     # Main layout with sidebar
│   │   └── +page.svelte       # Dashboard page
│   ├── app.css                # Global styles (Tailwind)
│   └── app.html               # HTML shell
├── static/                    # Static assets
├── MIGRATION_PLAN.md          # Feature roadmap
├── package.json
├── tailwind.config.js
├── svelte.config.js
├── vite.config.ts
└── tsconfig.json
```

## Database Tables

The app uses the following Supabase tables with Row-Level Security (RLS):

- `tenants` - Business/organization information
- `branches` - Store locations
- `users` - User accounts (linked to tenants)
- `products` - Product catalog (tenant-scoped)
- `customers` - Customer information (tenant-scoped)
- `sales` - Transaction records
- `sale_items` - Line items for sales
- `orders` - Customer orders
- `order_items` - Order line items

## Development

```bash
# Run development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Type checking
npm run check

# Type checking in watch mode
npm run check:watch
```

## Deployment

Build the app for production:

```bash
npm run build
```

The built files will be in the `build/` directory, ready to deploy to:
- Vercel
- Netlify
- Cloudflare Pages
- Any static hosting service

## Migration from Flutter

This app replaces the previous Flutter-based POS admin (`apps/pos_admin`) for faster development and better web performance.

### Why SvelteKit?

1. **Faster Development:** Component-based architecture with less boilerplate
2. **Better Performance:** Optimized for web with server-side rendering
3. **Easier Maintenance:** TypeScript + Svelte's reactive system
4. **Smaller Bundle:** Svelte compiles to vanilla JavaScript
5. **Shared Components:** Reuse components from healthcare_medic

See [MIGRATION_PLAN.md](./MIGRATION_PLAN.md) for the complete migration roadmap.

## Contributing

1. Check [MIGRATION_PLAN.md](./MIGRATION_PLAN.md) for TODO items
2. Pick a feature to implement
3. Follow the existing code patterns
4. Test on mobile and desktop
5. Ensure RLS policies are working correctly

## License

[Your License Here]
