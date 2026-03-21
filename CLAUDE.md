# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **multi-platform monorepo** with the following architecture:
- **SvelteKit**: All web applications including marketing pages, storefront, healthcare interfaces, and POS admin
- **Supabase**: Backend database and authentication (via MCP server)
- **SpecKit**: Structured feature development workflow system

## Architecture

### Multi-App Structure

The project is organized into separate applications in the `apps/` directory:

#### SvelteKit Applications
1. **`apps/marketing_sveltekit/`** - Marketing website, landing page, and pricing page
   - Tech stack: SvelteKit 2.0, Svelte 5, Tailwind CSS 4, TypeScript
   - Entry command: `npm run dev` (runs on http://localhost:5173)

2. **`apps/storefront/`** - E-commerce storefront with referral commission system
   - Tech stack: SvelteKit with Supabase integration
   - Handles customer purchases and referral tracking

3. **`apps/healthcare_customer/`** - Healthcare customer interface
   - Tech stack: SvelteKit, Tailwind CSS, Supabase
   - Customer-facing telemedicine booking and consultations

4. **`apps/healthcare_medic/`** - Healthcare provider (medic) interface
   - Tech stack: SvelteKit, Tailwind CSS, Supabase
   - Doctor/pharmacist consultation and prescription management
   - Entry command: `npm run dev` (runs on http://localhost:5174)

5. **`apps/pos_sveltekit/`** - POS admin interface (MVP Phase)
   - Tech stack: SvelteKit 2.0, Svelte 5, Tailwind CSS 4, TypeScript
   - Point-of-sale system for pharmacy, retail, diagnostic center tenants
   - Product management, sales processing, customer management
   - Entry command: `npm run dev` (runs on http://localhost:5175)
   - Migration from Flutter to SvelteKit for faster development

#### Legacy Applications
1. **`apps/web_client/`** - Legacy Flutter web client
   - Built output available in `apps/web_client/build/web/`
   - Being replaced by SvelteKit applications

### Shared Resources

- **`supabase/`** - Database migrations and schema definitions
  - **`supabase/migrations/`** - SQL migration files
  - Migrations include multi-tenant POS system and healthcare consultations

- **`specs/`** - SpecKit feature specifications
  - Each spec in format: `specs/[number]-[short-name]/`
  - Contains `spec.md`, `plan.md`, `tasks.md`, and related artifacts

- **`.specify/`** - SpecKit workflow system files
  - Templates, scripts, and memory files for structured development

## Development Commands

### SvelteKit Apps

All applications follow the same development workflow:

```bash
# Install dependencies (first time only)
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Type check and validate
npm run check
```

#### Application Ports

- **Marketing** (`apps/marketing_sveltekit`): http://localhost:5173
- **Healthcare Medic** (`apps/healthcare_medic`): http://localhost:5174
- **POS Admin** (`apps/pos_sveltekit`): http://localhost:5175
- **Storefront** (`apps/storefront`): http://localhost:5176 (if configured)
- **Healthcare Customer** (`apps/healthcare_customer`): http://localhost:5177 (if configured)

### Supabase (via MCP)

The project has Supabase MCP server enabled (`.claude/settings.local.json`). When working with database operations, use the available Supabase MCP tools for migrations, queries, and schema management.

## SpecKit Workflow System

This repository uses SpecKit, a structured feature development workflow with nine custom skills:

### Workflow Sequence
1. **`/speckit.specify`** - Create feature specification from natural language description
   - Generates branch (format: `[number]-[short-name]`)
   - Creates `specs/[number]-[short-name]/spec.md`
   - Validates specification quality with checklist
   - Focuses on WHAT users need, not HOW to implement

2. **`/speckit.clarify`** - Identify underspecified areas and resolve them
   - Asks up to 5 targeted clarification questions
   - Updates spec with answers

3. **`/speckit.plan`** - Execute implementation planning workflow
   - Runs `.specify/scripts/powershell/setup-plan.ps1`
   - Generates Phase 0: `research.md` (technical decisions)
   - Generates Phase 1: `data-model.md`, `contracts/`, `quickstart.md`
   - Updates agent context files
   - Validates against constitution if present

4. **`/speckit.tasks`** - Generate dependency-ordered tasks
   - Creates `tasks.md` from plan artifacts
   - Tasks are actionable and ordered by dependencies

5. **`/speckit.implement`** - Execute tasks from tasks.md
   - Processes and executes all defined tasks

6. **`/speckit.analyze`** - Cross-artifact consistency analysis
   - Non-destructive quality check across spec, plan, and tasks

### Supporting Skills
- **`/speckit.constitution`** - Create/update project principles and constraints
- **`/speckit.checklist`** - Generate custom checklists based on requirements
- **`/speckit.taskstoissues`** - Convert tasks to GitHub issues

### SpecKit File Locations
- **Templates**: `.specify/templates/` (spec, plan, tasks, checklist, agent-file)
- **Scripts**: `.specify/scripts/powershell/` (PowerShell scripts for workflow automation)
- **Memory**: `.specify/memory/constitution.md` (project constitution template)
- **Skills**: `.claude/commands/speckit.*.md`

### SpecKit Key Principles
- Specifications are technology-agnostic (no implementation details)
- User scenarios must be independently testable
- Maximum 3 `[NEEDS CLARIFICATION]` markers per spec
- Constitution checks gate progression between phases
- Plans generate concrete design artifacts before implementation

## Working with This Codebase

### Technology Stack Decisions

**Use SvelteKit for:**
- Marketing and landing pages
- Storefront and e-commerce
- Healthcare customer-facing interfaces
- Healthcare medic provider interfaces (doctor/pharmacist dashboards)
- **POS admin dashboards** (pharmacy, retail, diagnostic center)
- Any web-based application (public or internal)

**Why SvelteKit:**
- Faster development with less boilerplate
- Better web performance and smaller bundle sizes
- Shared components across applications
- TypeScript support and strong typing
- Server-side rendering (SSR) and static site generation (SSG)
- Easier maintenance and testing

### Adding New Features

When adding significant features, use the SpecKit workflow:
1. Run `/speckit.specify [feature description]` to create structured specification
2. Follow the workflow sequence through planning and implementation
3. This ensures proper documentation and architectural consistency

### Branch Naming

SpecKit creates branches as `[number]-[short-name]` where:
- Number is auto-incremented based on existing branches/specs
- Short name is 2-4 words derived from feature description
- Example: `1-user-auth`, `2-analytics-dashboard`, `3-healthcare-consultations`

### Database Schema

The Supabase database includes:
- **Multi-tenant POS system** with tenant isolation
- **Healthcare consultations** system
- Row-Level Security (RLS) policies for data protection
- Automated tenant scoping for all tables

Key migrations:
- `20260223_tenant_scoped_products.sql` - Tenant-scoped product management
- `20260222194504_healthcare_consultation.sql` - Healthcare consultation system

### Project Structure

```
kemani/
├── apps/
│   ├── marketing_sveltekit/     # Marketing site (SvelteKit) ✓
│   ├── storefront/               # Storefront with referral system (SvelteKit) ✓
│   ├── healthcare_customer/      # Healthcare customer UI (SvelteKit) ✓
│   ├── healthcare_medic/         # Healthcare medic provider UI (SvelteKit) ✓
│   ├── pos_sveltekit/            # POS admin (SvelteKit) ✓ MVP Phase
│   └── web_client/               # Legacy Flutter web client
├── supabase/
│   └── migrations/               # Database migrations
├── specs/                        # SpecKit feature specifications
│   ├── 001-multi-tenant-pos/     # POS system specification
│   └── 004-tenant-referral-commissions/ # Referral commission system
├── .specify/                     # SpecKit workflow system
└── .claude/                      # Claude Code configuration

✓ = Active development
```

## Environment Setup

All SvelteKit apps share the same environment configuration pattern.

### SvelteKit Apps
Create `.env` in each SvelteKit app directory:
```bash
PUBLIC_SUPABASE_URL=your_supabase_url
PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

Or configure directly in `src/lib/supabase.ts` for development.

## Migration History

### From Next.js to SvelteKit (Completed)
This project was previously built with Next.js but has been fully migrated to SvelteKit. All Next.js code, configuration, and dependencies have been removed.

### From Flutter to SvelteKit for POS Admin (March 2026)
The POS admin application has been migrated from Flutter/FlutterFlow to SvelteKit for the MVP phase:

**Reasons for migration:**
- Faster web development cycle
- Better performance for web-based POS
- Shared component library with other apps
- Easier maintenance and updates
- No dependency on FlutterFlow visual builder

**Migration status:**
- ✅ Basic structure and layout created
- ✅ Dashboard with stats
- ✅ Authentication pages (login)
- ⏳ POS interface (TODO)
- ⏳ Product management (TODO)
- ⏳ Customer management (TODO)
- ⏳ Order management (TODO)

See `apps/pos_sveltekit/MIGRATION_PLAN.md` for detailed roadmap.
