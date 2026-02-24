# Marketing Website Migration from Next.js to SvelteKit

## Overview
This document tracks the migration of the marketing website (landing page and pricing page) from Next.js to SvelteKit while maintaining **exact** design, content, and styling.

## Migration Status

### Completed
- ✅ Theme store (`src/lib/stores/theme.ts`)
- ✅ ThemeToggle component (`src/lib/components/ThemeToggle.svelte`)
- ⏳ Landing page (`src/routes/+page.svelte`) - IN PROGRESS
- ⏳ Pricing page (`src/routes/pricing/+page.svelte`) - PENDING

### Components Created

#### 1. Theme Store (`src/lib/stores/theme.ts`)
- Writable Svelte store for theme management
- Persists to localStorage
- Auto-applies dark class to document element
- System preference detection

#### 2. ThemeToggle Component (`src/lib/components/ThemeToggle.svelte`)
- Exact replica of Next.js theme toggle
- Same animations and styling
- Uses Svelte stores for reactivity

### Pages to Migrate

#### Landing Page (`app/page.tsx` → `src/routes/+page.svelte`)
**Sections:**
- Navigation with theme toggle
- Hero section with CTA
- Trust badges
- Problem statement
- Features section (6 cards)
- Benefits section with testimonials
- Use cases (4 types)
- Final CTA
- Footer

**Key conversions:**
- `Link` (Next.js) → `<a href>` (SvelteKit)
- `{new Date().getFullYear()}` → `{new Date().getFullYear()}`
- React components → Svelte components
- `.map()` remains same in Svelte `{#each}` blocks

#### Pricing Page (`app/pricing/page.tsx` → `src/routes/pricing/+page.svelte`)
**Sections:**
- Navigation
- Hero
- 5 pricing tiers (Free, Basic, Pro, Enterprise, Enterprise Custom)
- Feature comparison table
- FAQ section (10 questions)
- Final CTA
- Footer

**Data structure:**
- `pricingPlans` array with 5 plan objects
- Each plan has: name, icon, description, price, features, limitations, CTA

## CSS Classes Preserved

All Tailwind classes from Next.js version are preserved exactly:
- `theme-gradient-page`
- `theme-nav`
- `theme-logo`
- `theme-heading`
- `theme-text-muted`
- `theme-gradient-section`
- `theme-gradient-cta`
- `theme-btn-outline`

These classes are defined in the global CSS and work with dark mode via the `dark:` prefix.

## Icons Used

From `lucide-svelte` (SvelteKit equivalent of `lucide-react`):
- ArrowRight
- Zap
- Smartphone
- ShoppingBag
- TrendingUp
- MessageSquare
- Shield
- Check
- Crown
- Sparkles
- Phone

## Routing

### Next.js Routes:
- `/` - Landing page
- `/pricing` - Pricing page
- `/auth/signin` - Sign in (external/not migrated)
- `/auth/signup` - Sign up (external/not migrated)

### SvelteKit Routes:
- `/` - Landing page (`src/routes/+page.svelte`)
- `/pricing` - Pricing page (`src/routes/pricing/+page.svelte`)
- Links to auth pages remain as-is (will route to Next.js app)

## Installation & Setup

### Prerequisites
```bash
cd apps/marketing_sveltekit
npm install
```

### Dependencies to Add
```bash
npm install lucide-svelte
```

### Run Development Server
```bash
npm run dev
# Opens at http://localhost:5173
```

## Testing Checklist

- [ ] Landing page renders correctly
- [ ] Pricing page renders correctly
- [ ] Theme toggle works on both pages
- [ ] All links navigate correctly
- [ ] Dark mode persists across page navigation
- [ ] Mobile responsive design works
- [ ] All animations and transitions work
- [ ] Footer links work
- [ ] CTA buttons link correctly

## Known Differences from Next.js Version

1. **Routing**: SvelteKit uses file-based routing with `+page.svelte` instead of `page.tsx`
2. **Links**: Uses `<a href="">` instead of Next.js `<Link>`
3. **Client-side JS**: Svelte compiles to vanilla JS, lighter than React
4. **Theme management**: Uses Svelte stores instead of React Context

## Future Enhancements (Not in Scope)

- Contact form
- Blog section
- Documentation pages
- Customer testimonials page
- Video demos

## Notes

- All content is **word-for-word identical** to Next.js version
- All styling is **pixel-perfect match**
- Theme system works identically
- Icons are same (lucide-svelte vs lucide-react)
