# Kemani - Multi-Platform Monorepo

A multi-platform application suite supporting **Multi-Tenant POS System** and **Healthcare Consultation System**.

## Architecture

This monorepo uses:
- **SvelteKit** for public-facing web applications (marketing, storefront, healthcare customer interface)
- **Flutter** for admin/professional interfaces (POS admin, healthcare medic interface)
- **Supabase** for backend (PostgreSQL, Auth, Storage, Realtime)

## Project Structure

```
kemani/
├── apps/
│   ├── marketing_sveltekit/      # Marketing site (SvelteKit) ✅
│   ├── storefront/                # E-commerce storefront (SvelteKit)
│   ├── healthcare_customer/       # Healthcare customer UI (SvelteKit) [TBD]
│   ├── pos_admin/                 # POS admin (Flutter) [TBD]
│   ├── healthcare_medic/          # Healthcare medic UI (Flutter) [TBD]
│   └── web_client/                # Legacy Flutter web client
├── supabase/
│   └── migrations/                # Database migrations
├── specs/                         # SpecKit feature specifications
├── .specify/                      # SpecKit workflow system
└── .claude/                       # Claude Code configuration

✅ = Completed | [TBD] = To be developed
```

## Quick Start

### Prerequisites

- **Node.js** 18+ (for SvelteKit apps)
- **Flutter** 3.0+ (for Flutter apps)
- **Supabase** account and project

### SvelteKit Apps

```bash
# Navigate to any SvelteKit app
cd apps/marketing_sveltekit

# Install dependencies
npm install

# Start development server
npm run dev              # Runs on http://localhost:5173

# Build for production
npm run build

# Preview production build
npm run preview
```

### Flutter Apps

```bash
# Navigate to any Flutter app
cd apps/pos_admin

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on Windows
flutter run -d windows

# Build for production
flutter build web        # Web
flutter build apk        # Android
flutter build windows    # Windows
```

## Applications

### 1. Marketing SvelteKit (✅ Completed)
**Location:** `apps/marketing_sveltekit/`

Marketing website with landing page, pricing, and feature pages.

**Tech Stack:**
- SvelteKit 2.0
- Svelte 5
- Tailwind CSS 4
- TypeScript

### 2. Storefront (In Progress)
**Location:** `apps/storefront/`

E-commerce storefront for product sales.

### 3. Healthcare Customer Interface ([TBD])
**Location:** `apps/healthcare_customer/`

Patient/customer interface for booking and managing healthcare consultations.

**Features:**
- Book consultations
- View appointment history
- Manage profile
- Real-time notifications

### 4. POS Admin ([TBD])
**Location:** `apps/pos_admin/`

Point-of-sale administration dashboard for managing products, inventory, sales, and analytics.

**Features:**
- Product management
- Inventory tracking
- Sales processing
- Analytics dashboard
- Multi-tenant support
- Offline-first capability

**Platforms:** Web, Windows, Android, iOS

### 5. Healthcare Medic Interface ([TBD])
**Location:** `apps/healthcare_medic/`

Healthcare provider/medic interface for managing consultations and patients.

**Features:**
- Patient management
- Consultation scheduling
- Session notes
- Prescription management

**Platforms:** Web, mobile, desktop

## Database

### Supabase Setup

1. Create a Supabase project at [supabase.com](https://supabase.com)

2. Run migrations:
```bash
# Via Supabase CLI
supabase db push

# Or manually in Supabase Dashboard > SQL Editor
```

3. Configure environment variables in each app:

**SvelteKit apps** (`.env`):
```bash
PUBLIC_SUPABASE_URL=https://xxx.supabase.co
PUBLIC_SUPABASE_ANON_KEY=eyJxxx...
```

**Flutter apps** (`lib/config/supabase_config.dart` or `--dart-define`):
```dart
const supabaseUrl = 'https://xxx.supabase.co';
const supabaseAnonKey = 'eyJxxx...';
```

### Database Schema

**Multi-Tenant POS:**
- Tenants, users, products, inventory, sales, receipts, staff, analytics

**Healthcare System:**
- Healthcare providers, patients, consultations, appointments, notes

All tables use Row-Level Security (RLS) for data isolation.

## Development Workflow

This project uses **SpecKit** for structured feature development:

```bash
# 1. Create feature specification
/speckit.specify [feature description]

# 2. Clarify requirements (optional)
/speckit.clarify

# 3. Generate implementation plan
/speckit.plan

# 4. Generate tasks
/speckit.tasks

# 5. Implement
/speckit.implement

# 6. Analyze (quality check)
/speckit.analyze
```

See [CLAUDE.md](./CLAUDE.md) for detailed workflow documentation.

## Documentation

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Architecture decisions and design
- **[CLAUDE.md](./CLAUDE.md)** - Development workflow and guidelines
- **[MIGRATION_FROM_NEXTJS.md](./MIGRATION_FROM_NEXTJS.md)** - Migration guide from Next.js
- **[specs/](./specs/)** - Feature specifications

## Technology Stack

### Frontend
- **SvelteKit 2.0** - Public-facing web apps
- **Flutter 3.0+** - Admin/professional interfaces
- **Tailwind CSS 4** - Styling (SvelteKit)

### Backend
- **Supabase** - PostgreSQL, Auth, Storage, Realtime
- **Row-Level Security** - Multi-tenant data isolation

### Development Tools
- **TypeScript** - Type safety for SvelteKit
- **Dart** - Flutter programming language
- **SpecKit** - Feature development workflow
- **Supabase MCP** - Database management via Claude Code

## Deployment

### SvelteKit Apps
**Recommended:** Vercel, Netlify, or Cloudflare Pages

```bash
npm run build
```

Deploy the `.svelte-kit/` build output.

### Flutter Apps
**Web:**
```bash
flutter build web --release
```
Deploy to Firebase Hosting, Vercel, or any static host.

**Mobile:**
```bash
flutter build apk --release    # Android
flutter build ipa --release    # iOS
```
Deploy to Google Play Store / Apple App Store.

**Desktop:**
```bash
flutter build windows --release
flutter build macos --release
```

## Contributing

1. Create a feature spec: `/speckit.specify [description]`
2. Follow the SpecKit workflow
3. Create a pull request
4. Ensure tests pass

## License

[Add your license here]

## Support

For issues and questions:
- Check existing documentation in `docs/`
- Review feature specs in `specs/`
- Contact the development team

---

**Note:** This project migrated from Next.js to SvelteKit/Flutter architecture. See [MIGRATION_FROM_NEXTJS.md](./MIGRATION_FROM_NEXTJS.md) for details.
