<!--
  SYNC IMPACT REPORT

  Version: 0.0.0 → 1.0.0 (MAJOR - Initial constitution establishment)

  Modified Principles: N/A (New constitution)

  Added Sections:
  - All 7 Core Principles (TypeScript & Type Safety, Component Architecture, Testing Strategy,
    Performance Standards, User Experience, Security & Data Privacy, Accessibility Standards)
  - Development Workflow
  - Quality Gates
  - Performance Standards
  - Security Requirements
  - Governance

  Removed Sections: N/A (New constitution)

  Templates Requiring Updates:
  - ✅ .specify/templates/plan-template.md - Constitution Check section already present
  - ✅ .specify/templates/spec-template.md - Already aligned with user story requirements
  - ✅ .specify/templates/tasks-template.md - Already aligned with test-optional approach

  Follow-up TODOs: None
-->

# Kemani Constitution

## Core Principles

### I. TypeScript & Type Safety

TypeScript strict mode MUST be enabled for all source code. Type `any` is prohibited except when interfacing with untyped third-party libraries, and MUST be documented with justification. All React components MUST have explicit prop type definitions. Type assertions (`as`) require inline comments explaining why type inference failed.

**Rationale**: Type safety catches errors at compile time, improves IDE support, and serves as living documentation. Next.js 16 with React 19 benefits significantly from strict typing, especially with Server Components and Client Components distinction.

### II. Component Architecture

Components MUST follow the Single Responsibility Principle - one clear purpose per component. Server Components are the default; Client Components (`'use client'`) MUST be explicitly justified and scoped as narrowly as possible. Shared components go in `app/components/`, page-specific components stay colocated with their page. Component files MUST export a single default component matching the filename.

**Rationale**: Clear component boundaries improve maintainability, testability, and leverage Next.js 16 App Router optimizations. Server-first architecture reduces client-side JavaScript and improves performance.

### III. Testing Strategy (RECOMMENDED)

Test-Driven Development (TDD) is RECOMMENDED but not mandatory. When tests are written, they SHOULD be created before implementation and MUST fail before the feature is built. Integration tests are prioritized over unit tests for user-facing features. Critical paths (authentication, data mutations, payment flows) MUST have test coverage. Test files use `.test.ts` or `.test.tsx` extensions and are colocated with source files or in `__tests__/` directories.

**Rationale**: Tests provide confidence during refactoring and prevent regressions. Integration tests validate real user scenarios. The flexible approach balances quality with development velocity, allowing teams to choose when strict TDD adds value.

### IV. Performance Standards

All pages MUST meet Core Web Vitals targets: LCP < 2.5s, FID < 100ms, CLS < 0.1. Client-side JavaScript bundles MUST remain under 200KB gzipped per route. Images MUST use Next.js Image component with proper sizing and lazy loading. Third-party scripts MUST use Next.js Script component with appropriate loading strategies. Dynamic imports MUST be used for heavy components not needed on initial render.

**Rationale**: Performance directly impacts user experience, SEO rankings, and conversion rates. Next.js 16 provides excellent optimization primitives that must be used correctly.

### V. User Experience

All interactive elements MUST provide visual feedback within 100ms of user interaction. Forms MUST validate on blur and provide clear error messages. Loading states MUST be shown for operations exceeding 200ms. Navigation MUST feel instant using Next.js Link component and prefetching. All user-facing text MUST be clear, concise, and actionable.

**Rationale**: Users expect modern web applications to feel responsive and provide clear feedback. Poor UX leads to user frustration and abandonment.

### VI. Security & Data Privacy

All user input MUST be validated on both client and server. Sensitive data MUST NOT be logged or exposed in client-side code. Authentication tokens MUST be stored in HTTP-only cookies, never localStorage. All external API calls MUST be made from Server Components or Route Handlers, never directly from Client Components. CORS policies MUST be explicitly configured, never use wildcard `*` in production.

**Rationale**: Security vulnerabilities can lead to data breaches, regulatory violations, and user trust loss. Defense in depth protects user data.

### VII. Accessibility Standards

All interactive elements MUST be keyboard accessible. Color MUST NOT be the only means of conveying information. Images MUST have descriptive alt text. Form inputs MUST have associated labels. Heading hierarchy MUST be semantic (h1 → h2 → h3, no skipping). ARIA attributes MUST be used correctly or not at all. All pages MUST be navigable with screen readers.

**Rationale**: Accessibility is a legal requirement in many jurisdictions and a moral imperative. Accessible applications serve a wider audience and often improve usability for all users.

## Development Workflow

### Branch Strategy

Features MUST be developed on feature branches following the pattern `[number]-[short-name]` where number is auto-incremented and short-name is 2-4 words (e.g., `1-user-auth`, `2-dashboard-layout`). The `master` branch is the main integration branch. Direct commits to `master` are prohibited - all changes MUST go through pull requests.

### Pull Request Requirements

All pull requests MUST:
- Have a clear title and description explaining the change
- Reference related issues or specifications (e.g., links to `specs/` directory)
- Pass all automated quality gates (see Quality Gates section)
- Receive at least one approving review from a team member
- Have no unresolved conversations before merge
- Be up-to-date with the target branch

### Code Review Process

Reviewers MUST verify:
- Adherence to all Core Principles in this constitution
- Type safety and proper TypeScript usage
- Performance implications of changes
- Security considerations
- Accessibility compliance
- Test coverage for critical paths (if tests are included)

Reviewers SHOULD provide constructive feedback and suggest improvements. Authors MUST address all review comments before merge.

## Quality Gates

All code MUST pass these automated checks before merge:

### Type Checking
```bash
npx tsc --noEmit
```
No type errors allowed. Strict mode violations are blocking.

### Linting
```bash
npm run lint
```
ESLint must pass with zero errors. Warnings should be minimized and justified.

### Build Verification
```bash
npm run build
```
Production build must complete successfully with no errors.

### Tests (if present)
If tests exist for the modified code, they MUST:
- All pass (no failing tests)
- Include new tests for new functionality
- Maintain or improve coverage for critical paths

## Performance Standards

### Core Web Vitals Targets

All pages MUST meet these targets in production:
- **Largest Contentful Paint (LCP)**: < 2.5 seconds
- **First Input Delay (FID)**: < 100 milliseconds
- **Cumulative Layout Shift (CLS)**: < 0.1

Pages failing these targets MUST have a documented performance improvement plan.

### Bundle Size Limits

- **Initial JavaScript bundle**: < 200KB gzipped per route
- **Total page weight (initial load)**: < 1MB including images
- **Third-party scripts**: < 50KB gzipped total

Exceptions MUST be justified and documented in the relevant PR.

### Monitoring

Performance MUST be monitored using:
- Next.js built-in analytics or Vercel Analytics
- Regular Lighthouse audits on production builds
- Real User Monitoring (RUM) for production traffic

Performance regressions > 10% MUST trigger investigation and remediation.

## Security Requirements

### Input Validation

All user input MUST be validated using:
- Client-side validation for immediate feedback
- Server-side validation as the authoritative check (NEVER trust client)
- Zod, Yup, or similar schema validation libraries for complex data

### Data Protection

- Sensitive data (passwords, tokens, PII) MUST NEVER be logged
- Database credentials MUST be in environment variables, NEVER committed to git
- Supabase Row Level Security (RLS) policies MUST be enabled for all tables
- API keys MUST use environment variables with appropriate scoping

### Dependency Management

- Dependencies MUST be audited monthly using `npm audit`
- Critical vulnerabilities MUST be patched within 7 days
- Major version updates MUST be tested in a non-production environment first

### Authentication & Authorization

- Use Supabase Auth or equivalent secure authentication provider
- Implement proper authorization checks on all protected routes
- Session tokens MUST expire and support refresh mechanisms
- Rate limiting MUST be implemented on all public API endpoints

## Governance

### Constitution Authority

This constitution supersedes all other development practices and documentation. When conflicts arise between this constitution and other guidelines, the constitution takes precedence.

### Amendment Procedure

Constitution amendments require:
1. Proposed changes documented in a pull request
2. Clear rationale for the change
3. Impact analysis on existing code and workflows
4. Approval from project maintainers
5. Version bump following semantic versioning (see below)
6. Update of all dependent templates and documentation

### Versioning Policy

Constitution versions follow **MAJOR.MINOR.PATCH**:
- **MAJOR**: Breaking changes (removed principles, incompatible governance changes)
- **MINOR**: New principles or sections added, material expansions
- **PATCH**: Clarifications, wording improvements, non-semantic changes

### Compliance Reviews

All pull requests MUST verify compliance with this constitution. Reviewers are responsible for ensuring adherence. Constitution violations are blocking issues that prevent merge.

### Complexity Justification

Complexity that violates constitutional principles (e.g., relaxing type safety, skipping accessibility) MUST be justified in writing and approved by project maintainers. Justifications MUST include:
- Specific principle being violated
- Why the violation is necessary
- Why simpler alternatives were rejected
- Mitigation strategies to minimize impact

### Living Document

This constitution is a living document. As the project evolves, principles may be added, refined, or removed through the amendment procedure. All changes are tracked in the Sync Impact Report at the top of this file.

---

**Version**: 1.0.0 | **Ratified**: 2026-01-17 | **Last Amended**: 2026-01-17
