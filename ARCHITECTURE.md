# Architecture Documentation

## Overview

This is a multi-platform monorepo that supports both a **Multi-Tenant POS System** and a **Healthcare Consultation System**. The architecture uses SvelteKit for customer-facing web interfaces and Flutter for admin/professional interfaces.

## Technology Choices

### Frontend Frameworks

#### SvelteKit (Public-Facing Web)
- **Marketing website** - Landing page, pricing, features
- **Storefront** - E-commerce functionality
- **Healthcare customer interface** - Patient/customer consultations

**Why SvelteKit:**
- Superior SEO and performance for public pages
- Built-in SSR and static site generation
- Lightweight and fast
- Great developer experience with Svelte 5
- Tailwind CSS 4 integration

#### Flutter (Admin/Professional Interfaces)
- **POS admin** - Point-of-sale administration and management
- **Healthcare medic interface** - Healthcare provider/medic tools

**Why Flutter:**
- Cross-platform (web, mobile, desktop) from single codebase
- Native performance
- Rich UI components for complex dashboards
- Better for internal tools requiring offline-first capabilities
- Supabase Flutter SDK support

### Backend

**Supabase**
- PostgreSQL database with Row-Level Security (RLS)
- Built-in authentication
- Real-time subscriptions
- Edge functions (if needed)
- Storage for files/images

## Application Structure

```
apps/
├── marketing_sveltekit/      # Marketing site (SvelteKit)
│   ├── src/
│   │   ├── routes/           # SvelteKit file-based routing
│   │   ├── lib/              # Shared components and utilities
│   │   └── app.html          # HTML template
│   ├── static/               # Static assets
│   ├── package.json
│   └── svelte.config.js
│
├── storefront/               # E-commerce storefront (SvelteKit)
│   └── [Similar structure to marketing_sveltekit]
│
├── healthcare_customer/      # Healthcare customer UI (SvelteKit) [TO BE CREATED]
│   ├── src/
│   │   ├── routes/
│   │   │   ├── +page.svelte              # Home/dashboard
│   │   │   ├── consultations/            # View consultations
│   │   │   ├── book/                     # Book new consultation
│   │   │   └── profile/                  # User profile
│   │   └── lib/
│   │       ├── components/               # Reusable components
│   │       ├── stores/                   # Svelte stores
│   │       └── supabase.ts               # Supabase client
│   └── package.json
│
├── pos_admin/                # POS admin (Flutter) [TO BE CREATED]
│   ├── lib/
│   │   ├── main.dart                     # Entry point
│   │   ├── screens/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── products_screen.dart
│   │   │   ├── inventory_screen.dart
│   │   │   ├── sales_screen.dart
│   │   │   └── analytics_screen.dart
│   │   ├── widgets/                      # Reusable widgets
│   │   ├── models/                       # Data models
│   │   ├── services/
│   │   │   ├── supabase_service.dart     # Supabase integration
│   │   │   └── auth_service.dart         # Authentication
│   │   └── utils/                        # Utilities
│   ├── pubspec.yaml
│   └── README.md
│
├── healthcare_medic/         # Healthcare medic UI (Flutter) [TO BE CREATED]
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── consultations_screen.dart
│   │   │   ├── patients_screen.dart
│   │   │   ├── schedule_screen.dart
│   │   │   └── profile_screen.dart
│   │   ├── widgets/
│   │   ├── models/
│   │   ├── services/
│   │   │   └── supabase_service.dart
│   │   └── utils/
│   ├── pubspec.yaml
│   └── README.md
│
└── web_client/               # Legacy Flutter web client
    └── build/web/            # Built output
```

## Database Schema

### Multi-Tenant POS System

**Core Tables:**
- `tenants` - Business/tenant information
- `users` - User accounts with tenant association
- `products` - Products with tenant isolation
- `inventory` - Stock management
- `sales` - Transaction records
- `receipts` - Sale receipts
- `staff` - Staff members per tenant
- `analytics` - Business analytics data

**Key Features:**
- Row-Level Security (RLS) enforces tenant isolation
- All tables have `tenant_id` foreign key
- Policies ensure users only access their tenant's data

### Healthcare Consultation System

**Core Tables:**
- `healthcare_providers` - Medical professionals
- `patients` - Patient records
- `consultations` - Consultation sessions
- `consultation_notes` - Session notes
- `appointments` - Scheduled appointments
- `prescriptions` - Medication prescriptions (if applicable)

**Key Features:**
- Privacy-first design with RLS
- HIPAA-compliant data handling considerations
- Patient-provider relationship management

## Data Flow

### SvelteKit Apps

```
User Request → SvelteKit Server
              ↓
         Load Function (SSR)
              ↓
    Supabase Query (with RLS)
              ↓
         Page Component
              ↓
    Client-side Interactivity
```

**Authentication Flow:**
1. User signs in via Supabase Auth
2. Session stored in cookies (httpOnly, secure)
3. Load functions access session for SSR
4. Client-side Supabase client uses same session

### Flutter Apps

```
User Action → Flutter Widget
             ↓
        Service Layer
             ↓
    Supabase Flutter SDK
             ↓
   Real-time Subscriptions
             ↓
      State Management
             ↓
      UI Update (rebuild)
```

**State Management:**
- Consider using Riverpod, Bloc, or Provider
- Supabase real-time for live updates
- Local caching for offline support (if needed)

## Security

### Row-Level Security (RLS)

All Supabase tables have RLS enabled with policies:

**Multi-tenant isolation:**
```sql
-- Example policy for products table
CREATE POLICY "Users can only view their tenant's products"
  ON products FOR SELECT
  USING (tenant_id = auth.tenant_id());
```

**Healthcare privacy:**
```sql
-- Example policy for consultations
CREATE POLICY "Patients can view their own consultations"
  ON consultations FOR SELECT
  USING (patient_id = auth.uid() OR provider_id = auth.uid());
```

### Authentication

- Email/password authentication via Supabase Auth
- OTP verification for enhanced security (POS)
- Magic links for passwordless login (optional)
- OAuth providers (Google, etc.) for public apps

### API Security

- All API calls go through Supabase (no custom backend needed)
- JWT tokens validate requests
- Rate limiting via Supabase edge functions (if needed)
- CORS configured for allowed origins

## Deployment

### SvelteKit Apps

**Recommended Platforms:**
- **Vercel** (optimal for SvelteKit)
- **Netlify**
- **Cloudflare Pages**

**Build command:**
```bash
npm run build
```

**Environment Variables:**
```
PUBLIC_SUPABASE_URL=https://xxx.supabase.co
PUBLIC_SUPABASE_ANON_KEY=xxx
```

### Flutter Apps

**Web:**
```bash
flutter build web --release
```
Deploy to:
- Firebase Hosting
- Vercel
- Cloudflare Pages
- Any static hosting

**Mobile (iOS/Android):**
```bash
flutter build apk --release      # Android
flutter build ipa --release      # iOS
```
Deploy to:
- Google Play Store
- Apple App Store
- Firebase App Distribution (beta testing)

**Desktop (Windows/macOS/Linux):**
```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

### Supabase

Supabase projects can be:
- Hosted on Supabase Cloud (easiest)
- Self-hosted with Docker

**Migrations:**
```bash
# Via Supabase CLI
supabase db push

# Or via MCP tools in Claude Code
```

## Development Workflow

### 1. Feature Specification (SpecKit)
```bash
/speckit.specify [feature description]
```

### 2. Implementation Planning
```bash
/speckit.plan
```

### 3. Task Generation
```bash
/speckit.tasks
```

### 4. Implementation
```bash
/speckit.implement
```

### 5. Testing
- SvelteKit: Vitest + Playwright
- Flutter: Flutter test framework + integration tests
- Supabase: pgTAP for database tests

## Monorepo Management

### Workspace Structure

Currently independent apps. Consider adding:
- Root `package.json` with workspaces (for npm)
- Shared packages (e.g., `packages/shared-types`)
- Unified build scripts

### Shared Code

**Option 1: Supabase-generated types**
- Generate TypeScript types from Supabase schema
- Share between SvelteKit apps
- Generate Dart types for Flutter apps

**Option 2: Shared packages**
```
packages/
├── shared-types/        # TypeScript/Dart type definitions
├── shared-utils/        # Common utilities
└── shared-config/       # Shared configuration
```

## Performance Considerations

### SvelteKit
- Use `+page.server.ts` for SSR data loading
- Implement static site generation where possible
- Lazy load components with `import()`
- Use SvelteKit's built-in caching

### Flutter
- Implement pagination for large lists
- Use `ListView.builder` for efficient rendering
- Cache images and assets locally
- Consider offline-first architecture with local database

### Supabase
- Use appropriate indexes on frequently queried columns
- Implement database-level pagination
- Use Supabase realtime selectively (don't subscribe to everything)
- Consider caching frequently accessed data

## Future Enhancements

1. **Monorepo tooling** - Turborepo or Nx for build orchestration
2. **Shared component library** - Reusable UI components across apps
3. **API Gateway** - If custom business logic needed beyond Supabase
4. **Offline-first** - PWA for SvelteKit, local database for Flutter
5. **Analytics** - Integrated analytics across all platforms
6. **Monitoring** - Error tracking (Sentry) and performance monitoring
7. **CI/CD** - Automated testing and deployment pipelines

## Migration Notes

This project was previously built with Next.js. All Next.js code has been removed in favor of the SvelteKit/Flutter architecture for better separation of concerns and platform-specific optimizations.

**Key changes:**
- Next.js App Router → SvelteKit file-based routing
- React components → Svelte components or Flutter widgets
- Next.js API routes → Direct Supabase client calls
- next-auth → Supabase Auth
- Vercel deployment → Multi-platform deployment strategy
