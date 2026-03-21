# POS Admin - Flutter to SvelteKit Migration Plan

## Migration Status: In Progress

This document tracks the migration of the POS Admin from Flutter to SvelteKit for the MVP phase.

---

## Directory Structure

```
apps/pos_sveltekit/
├── src/
│   ├── lib/
│   │   ├── components/        # Shared UI components
│   │   ├── supabase.ts        # Supabase client
│   │   └── utils/             # Utility functions
│   ├── routes/
│   │   ├── auth/              # Authentication pages
│   │   ├── products/          # Product management
│   │   ├── customers/         # Customer management
│   │   ├── orders/            # Order management
│   │   ├── pos/               # Point of Sale interface
│   │   ├── analytics/         # Analytics & reports
│   │   ├── settings/          # Settings & configuration
│   │   ├── +layout.svelte     # Main layout with sidebar
│   │   └── +page.svelte       # Dashboard
│   ├── app.css                # Global styles
│   └── app.html               # HTML template
├── package.json
├── tailwind.config.js
├── svelte.config.js
├── vite.config.ts
└── tsconfig.json
```

---

## Pages to Migrate

### ✅ COMPLETED

1. **Main Layout** (`+layout.svelte`)
   - Sidebar navigation
   - Mobile responsive menu
   - Auth gating
   - Logout functionality

2. **Dashboard** (`+page.svelte`)
   - Stats overview
   - Quick actions
   - Business metrics

### 🚧 IN PROGRESS

None currently

### ⏳ TODO - PHASE 1 (Core MVP Features)

#### Authentication (`/auth`)
- [ ] `/auth/login` - Login page
- [ ] `/auth/signup` - Signup page
- [ ] `/auth/forgot-password` - Password reset
- [ ] `/auth/email-confirmation` - Email confirmation pending

#### Onboarding (`/onboarding`)
- [ ] `/onboarding/country` - Country selection
- [ ] `/onboarding/business-setup` - Business/tenant setup
- [ ] `/onboarding/profile` - Profile completion

#### Point of Sale (`/pos`)
- [ ] `/pos` - Main POS interface for making sales
- [ ] `/pos/cart` - Shopping cart view
- [ ] `/pos/pending` - Pending/saved sales

#### Products (`/products`)
- [ ] `/products` - Product list with search/filter
- [ ] `/products/new` - Add new product
- [ ] `/products/[id]` - Product detail view
- [ ] `/products/[id]/edit` - Edit product

#### Customers (`/customers`)
- [ ] `/customers` - Customer list
- [ ] `/customers/new` - Add new customer
- [ ] `/customers/[id]` - Customer detail & history
- [ ] `/customers/[id]/edit` - Edit customer

#### Orders (`/orders`)
- [ ] `/orders` - Order list
- [ ] `/orders/[id]` - Order detail

### ⏳ TODO - PHASE 2 (Enhanced Features)

#### Analytics (`/analytics`)
- [ ] `/analytics` - Analytics dashboard
- [ ] `/analytics/products` - Product performance
- [ ] `/analytics/sales` - Sales trends
- [ ] `/analytics/customers` - Customer insights

#### Staff Management (`/staff`)
- [ ] `/staff` - Staff list
- [ ] `/staff/invite` - Invite new staff
- [ ] `/staff/[id]` - Staff profile
- [ ] `/staff/[id]/permissions` - Manage permissions

#### Settings (`/settings`)
- [ ] `/settings` - General settings
- [ ] `/settings/business` - Business information
- [ ] `/settings/branches` - Branch management
- [ ] `/settings/taxes` - Tax configuration
- [ ] `/settings/integrations` - Third-party integrations

### ⏳ TODO - PHASE 3 (Advanced Features)

#### Chat/Communication (`/chat`)
- [ ] `/chat` - Chat interface
- [ ] `/chat/team` - Team chat
- [ ] `/chat/support` - Customer support
- [ ] `/chat/ai-assistant` - AI assistant

#### Inventory (`/inventory`)
- [ ] `/inventory` - Inventory overview
- [ ] `/inventory/transfers` - Inter-branch transfers
- [ ] `/inventory/adjustments` - Stock adjustments

---

## Key Features Checklist

### Core POS Functionality
- [ ] Barcode scanning support
- [ ] Multiple payment methods (Cash, Card, Transfer)
- [ ] Print receipts
- [ ] Customer loyalty points
- [ ] Discounts & promotions
- [ ] Tax calculations

### Offline Capability
- [ ] Local database (IndexedDB/Hive alternative)
- [ ] Offline sale recording
- [ ] Background sync when online
- [ ] Conflict resolution

### Multi-tenant Features
- [ ] Tenant isolation (RLS)
- [ ] Branch-based access control
- [ ] Role-based permissions
- [ ] Staff management

### Data Management
- [ ] Bulk product import/export (CSV)
- [ ] Customer data import
- [ ] Backup/restore functionality

---

## Database Tables Used

- `tenants` - Business/organization information
- `branches` - Store locations
- `users` - User accounts (admin, staff, cashiers)
- `products` - Product catalog
- `customers` - Customer information
- `customer_addresses` - Delivery addresses
- `sales` - Transaction records
- `sale_items` - Line items for sales
- `orders` - Customer orders
- `order_items` - Order line items
- `inventory_transactions` - Stock movements
- `staff_attendance` - Staff clock in/out

---

## Component Library

Reusable components to build:

- [ ] `Modal.svelte` - Modal dialogs
- [ ] `Table.svelte` - Data tables with sorting/filtering
- [ ] `SearchBar.svelte` - Search input
- [ ] `ProductCard.svelte` - Product display card
- [ ] `CustomerCard.svelte` - Customer info card
- [ ] `StatCard.svelte` - Dashboard stat cards
- [ ] `Form components` (Input, Select, Checkbox, etc.)
- [ ] `DatePicker.svelte` - Date selection
- [ ] `BarcodeScanner.svelte` - Barcode scanning
- [ ] `Receipt.svelte` - Receipt template for printing

---

## Migration Notes

### Differences from Flutter

1. **State Management**:
   - Flutter: Provider pattern
   - SvelteKit: Svelte 5 runes ($state, $derived)

2. **Routing**:
   - Flutter: Named routes
   - SvelteKit: File-based routing

3. **Offline Capability**:
   - Flutter: Hive local database
   - SvelteKit: IndexedDB or PouchDB

4. **Styling**:
   - Flutter: Material Design widgets
   - SvelteKit: Tailwind CSS

### API Integration

All Supabase integration is already set up in `src/lib/supabase.ts`. Use the same patterns as healthcare_medic:

```typescript
import { supabase } from '$lib/supabase';

// Example: Fetch products
const { data, error } = await supabase
  .from('products')
  .select('*')
  .eq('tenant_id', tenantId);
```

---

## Development Workflow

1. Install dependencies: `npm install`
2. Start dev server: `npm run dev` (runs on http://localhost:5175)
3. Build for production: `npm run build`
4. Type check: `npm run check`

---

## Next Steps

1. ✅ Create basic layout and dashboard
2. ⏭️ Build authentication pages
3. ⏭️ Implement POS interface
4. ⏭️ Build product management
5. ⏭️ Build customer management
6. ⏭️ Build order management
7. ⏭️ Add analytics
8. ⏭️ Implement offline capability

---

## Notes

- Focus on MVP features first (Phase 1)
- Reuse components from healthcare_medic where applicable
- Maintain consistency with existing Tailwind theme
- Test on mobile devices for responsive design
- Ensure all tenant data is properly isolated via RLS policies
