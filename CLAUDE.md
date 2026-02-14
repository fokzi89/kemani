# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **monorepo** with multiple applications:

1. **Flutter Mobile App** (Admin/POS) - **[Separate Repository]**
   - Purpose: Point of Sale system and Admin portal for business owners
   - Tech Stack: Flutter, Dart
   - Platform: iOS & Android mobile apps
   - Consumes: Next.js API Server

2. **Next.js API Server** (Root) - TypeScript, Node.js
   - Location: Root directory (`app/api/`, `lib/`)
   - Purpose: REST API server for Flutter mobile app (40+ routes)
   - Tech Stack: Next.js 16 App Router (API routes only, no UI)
   - APIs: Analytics, Inventory, Sales, Staff, Branches, Sync, etc.

3. **SvelteKit Marketing Website** (Customer-Facing)
   - Location: `apps/marketing_sveltekit/`
   - Purpose: Landing page, Pricing, Business registration
   - Tech Stack: SvelteKit 2.x, Svelte 5, Tailwind CSS 4
   - Deployment: Primary domain (e.g., `kemani.com`)
   - APIs: 5 routes (auth, tenants)

4. **SvelteKit Storefront** (Customer Ecommerce)
   - Location: `apps/storefront/`
   - Purpose: E-commerce storefront for customers to browse and purchase products
   - Tech Stack: SvelteKit 2.x, Svelte 5, Tailwind CSS 4
   - Deployment: Subdomain per tenant (e.g., `store.tenant.com`)
   - APIs: 12 routes (products, orders, customers, chat, payments)

**Architecture**:
- Flutter mobile app → Next.js API Server (40 routes)
- SvelteKit apps → Own APIs (17 routes total)
- All apps → Shared Supabase database with RLS for multi-tenancy
- Project integrates with Supabase via MCP server
- Includes SpecKit workflow system for structured feature development

## Development Commands

### Next.js API Server (Root)
```bash
npm run dev          # Start API server at http://localhost:3000
npm run build        # Build for production
npm start            # Start production server
npm run lint         # Run ESLint
```

### SvelteKit Marketing Website
```bash
cd apps/marketing_sveltekit
npm run dev          # Start dev server at http://localhost:5173
npm run build        # Build for production
npm run preview      # Preview production build
npm run check        # Type check
```

### SvelteKit Storefront
```bash
cd apps/storefront
npm run dev          # Start dev server at http://localhost:5174
npm run build        # Build for production
npm run preview      # Preview production build
npm run check        # Type check
```

### ESLint Configuration
- Uses Next.js's flat config format (`eslint.config.mjs`)
- Configured with `eslint-config-next/core-web-vitals` and `eslint-config-next/typescript`
- Ignores: `.next/`, `out/`, `build/`, `next-env.d.ts`

## Architecture

### Application Structure

**Next.js API Server** (Root):
- **API Routes**: `app/api/*` - REST endpoints for Flutter mobile app
- **Shared Utilities**: `lib/*` - Business logic, database services, integrations
- **TypeScript**: Strict mode enabled
- **Path Aliases**: `@/*` maps to project root

**SvelteKit Apps**:
- **Marketing**: Landing, pricing, business registration pages
- **Storefront**: Customer ecommerce storefront
- **Path Aliases**: `$lib/*` for each app
- **Styling**: Tailwind CSS 4 with PostCSS
- **Type Safety**: TypeScript with Svelte 5

### Key Directories
- `app/api/`: Next.js API routes (40+ endpoints for Flutter)
- `lib/`: Shared business logic and utilities
- `apps/marketing_sveltekit/`: Marketing website (5 API routes)
- `apps/storefront/`: Ecommerce storefront (12 API routes)
- `supabase/`: Database migrations and schema
- `specs/`: SpecKit feature specifications

### MCP Integration
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

### API Development (Next.js)
- API routes in `app/api/` serve Flutter mobile app
- Shared utilities in `lib/` (auth, database, integrations)
- Use `@/` path alias for imports
- All TypeScript files use strict mode

### Frontend Development (SvelteKit)
- **Marketing**: Edit `apps/marketing_sveltekit/src/routes/`
- **Storefront**: Edit `apps/storefront/src/routes/`
- Use `$lib/` path alias for imports
- Each app has its own API routes (`src/routes/api/`)
- Shared utilities copied to each app's `src/lib/`

### Adding New Features
When adding significant features, consider using the SpecKit workflow:
1. Run `/speckit.specify [feature description]` to create structured specification
2. Follow the workflow sequence through planning and implementation
3. This ensures proper documentation and architectural consistency

### Branch Naming
SpecKit creates branches as `[number]-[short-name]` where:
- Number is auto-incremented based on existing branches/specs
- Short name is 2-4 words derived from feature description
- Example: `1-user-auth`, `2-analytics-dashboard`

### TypeScript Configuration Notes
- Module resolution: `bundler` (Next.js 16 requirement)
- JSX: `react-jsx` (React 19)
- Incremental compilation enabled
- JSON imports allowed
