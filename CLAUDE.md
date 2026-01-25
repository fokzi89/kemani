# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Next.js 16 application (App Router) with TypeScript, React 19, and Tailwind CSS 4. The project integrates with Supabase via MCP server and includes a SpecKit workflow system for structured feature development.

## Development Commands

### Core Commands
```bash
npm run dev          # Start development server at http://localhost:3000
npm run build        # Build production application
npm start            # Start production server
npm run lint         # Run ESLint
```

### ESLint Configuration
- Uses Next.js's flat config format (`eslint.config.mjs`)
- Configured with `eslint-config-next/core-web-vitals` and `eslint-config-next/typescript`
- Ignores: `.next/`, `out/`, `build/`, `next-env.d.ts`

## Architecture

### Application Structure
- **App Router**: Uses Next.js 16 App Router (`app/` directory)
- **TypeScript**: Strict mode enabled with ES2017 target
- **Path Aliases**: `@/*` maps to project root
- **Styling**: Tailwind CSS 4 with PostCSS
- **Fonts**: Geist Sans and Geist Mono via `next/font/google`

### Key Files
- `app/layout.tsx`: Root layout with font configuration and metadata
- `app/page.tsx`: Home page component
- `app/globals.css`: Global styles and Tailwind directives
- `next.config.ts`: Next.js configuration (currently empty)
- `tsconfig.json`: TypeScript configuration with strict mode

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

### File Editing
- The main application entry point is `app/page.tsx`
- Layout modifications go in `app/layout.tsx`
- Global styles in `app/globals.css`
- All TypeScript files use strict mode

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
