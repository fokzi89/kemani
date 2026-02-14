# SvelteKit Migration Guide - Marketing Pages

**Created**: 2026-02-11
**Target**: Landing page, Pricing, and Marketplace storefront
**From**: Next.js 16 (React)
**To**: SvelteKit (Svelte 5)
**Purpose**: SEO-optimized marketing pages with server-side rendering

---

## Table of Contents

1. [Why SvelteKit for Marketing](#why-sveltekit)
2. [Setup & Installation](#setup--installation)
3. [Project Structure](#project-structure)
4. [Page-by-Page Migration](#page-by-page-migration)
5. [Styling Migration](#styling-migration)
6. [Data Fetching](#data-fetching)
7. [Deployment](#deployment)

---

## Why SvelteKit for Marketing

### Advantages Over Next.js for Marketing

| Feature | Next.js | SvelteKit | Winner |
|---------|---------|-----------|--------|
| **Bundle Size** | ~200-300KB | ~30-50KB | ✅ SvelteKit |
| **Performance** | Good | Excellent | ✅ SvelteKit |
| **SEO** | Excellent | Excellent | 🟰 Tie |
| **Learning Curve** | Medium | Low | ✅ SvelteKit |
| **Build Speed** | Moderate | Fast | ✅ SvelteKit |
| **Runtime** | React (bulky) | Svelte (minimal) | ✅ SvelteKit |

**Key Benefits:**
- ⚡ **50-70% smaller bundle** compared to Next.js
- 🚀 **Faster page loads** for marketing visitors
- 📈 **Better Lighthouse scores** (90+ easily)
- 💰 **Lower hosting costs** (faster builds, less bandwidth)
- 🎯 **SEO optimized** with SSR/SSG built-in

---

## Setup & Installation

### Step 1: Install Node.js (Already Have)

Verify:
```bash
node --version  # Should be v18+
npm --version   # Should be v9+
```

### Step 2: Create SvelteKit Project

```bash
cd C:\Users\AFOKE\kemani\apps
npm create svelte@latest marketing_sveltekit
```

**Prompts & Answers:**
```
┌  Welcome to SvelteKit!
│
◆  Which Svelte app template?
│  ● SvelteKit demo app
│  ○ Skeleton project
│  ○ Library project
└

◆  Add type checking with TypeScript?
│  ● Yes, using TypeScript syntax
│  ○ Yes, using JavaScript with JSDoc comments
│  ○ No
└

◆  Select additional options (use arrow keys/space to select)
│  ◻ Add ESLint for code linting
│  ◼ Add Prettier for code formatting
│  ◼ Add Vitest for unit testing
│  ◻ Try the Svelte 5 preview (experimental)
└
```

**Recommended Selection:**
- Template: **SvelteKit demo app** (gives you examples)
- TypeScript: **Yes, using TypeScript syntax**
- Options: **Prettier** + **Vitest**

### Step 3: Install Dependencies

```bash
cd marketing_sveltekit
npm install

# Install Tailwind CSS
npx svelte-add@latest tailwindcss
npm install

# Install additional packages
npm install @supabase/supabase-js
npm install lucide-svelte  # Svelte version of Lucide icons
```

### Step 4: Verify Setup

```bash
npm run dev
```

Open http://localhost:5173 → Should see SvelteKit welcome page

---

## Project Structure

### Recommended Folder Structure

```
marketing_sveltekit/
├── src/
│   ├── routes/
│   │   ├── +layout.svelte              # Root layout (nav, footer)
│   │   ├── +page.svelte                # Landing page (/)
│   │   ├── +page.server.ts             # Landing page data loading
│   │   ├── pricing/
│   │   │   ├── +page.svelte            # Pricing page (/pricing)
│   │   │   └── +page.server.ts
│   │   ├── shop/
│   │   │   └── [tenantId]/
│   │   │       ├── +page.svelte        # Storefront (/shop/[tenantId])
│   │   │       ├── +page.server.ts
│   │   │       ├── +layout.svelte      # Marketplace layout
│   │   │       ├── products/
│   │   │       │   └── [productId]/
│   │   │       │       └── +page.svelte
│   │   │       ├── cart/
│   │   │       │   └── +page.svelte
│   │   │       └── profile/
│   │   │           └── +page.svelte
│   │   └── track/
│   │       └── [trackingCode]/
│   │           └── +page.svelte
│   ├── lib/
│   │   ├── components/                 # Reusable components
│   │   │   ├── Nav.svelte
│   │   │   ├── Footer.svelte
│   │   │   ├── ThemeToggle.svelte
│   │   │   └── ProductCard.svelte
│   │   ├── services/
│   │   │   ├── supabase.ts
│   │   │   └── marketplace.ts
│   │   └── types/
│   │       └── index.ts
│   ├── app.html                        # HTML template
│   └── app.css                         # Global styles (Tailwind)
├── static/
│   ├── favicon.png
│   └── robots.txt
├── svelte.config.js
├── tailwind.config.js
├── tsconfig.json
└── package.json
```

### Key Differences from Next.js

| Next.js | SvelteKit | Purpose |
|---------|-----------|---------|
| `app/page.tsx` | `routes/+page.svelte` | Page component |
| `app/layout.tsx` | `routes/+layout.svelte` | Layout component |
| `export default function Page()` | `<script>` then HTML | Component syntax |
| Server Components | `+page.server.ts` | Server-side data |
| `useEffect` | `$effect` (Svelte 5) | Side effects |
| `useState` | `$state` (Svelte 5) | State management |

---

## Page-by-Page Migration

### Page 1: Landing Page

#### Next.js Code (app/page.tsx)

```tsx
// app/page.tsx (Next.js)
import Link from "next/link";
import { ArrowRight } from "lucide-react";

export default function Home() {
  return (
    <div className="min-h-screen">
      <h1>Your Business Never Stops</h1>
      <Link href="/pricing">View Pricing</Link>
    </div>
  );
}
```

#### SvelteKit Equivalent (src/routes/+page.svelte)

```svelte
<!-- src/routes/+page.svelte -->
<script lang="ts">
  import { ArrowRight } from 'lucide-svelte';
</script>

<div class="min-h-screen">
  <h1>Your Business Never Stops</h1>
  <a href="/pricing">View Pricing</a>
</div>
```

**Key Differences:**
- ✅ No `import Link` - use regular `<a>` tags (SvelteKit handles routing)
- ✅ Icons from `lucide-svelte` instead of `lucide-react`
- ✅ `<script>` block at top, HTML at bottom
- ✅ No `export default function` - just write HTML directly

#### Full Landing Page Migration

**File: `src/routes/+page.svelte`**

```svelte
<script lang="ts">
  import { ArrowRight, Zap, Smartphone, ShoppingBag, TrendingUp, MessageSquare, Shield } from 'lucide-svelte';
  import ThemeToggle from '$lib/components/ThemeToggle.svelte';

  const features = [
    {
      icon: Zap,
      title: 'Offline-First POS',
      description: 'Process sales and print receipts even when internet is down.'
    },
    {
      icon: ShoppingBag,
      title: 'Online Marketplace',
      description: 'Reach nearby customers with your digital storefront.'
    },
    // ... more features
  ];

  const trustBadges = [
    { label: 'Start Free', value: '₦0' },
    { label: 'Works Offline', value: '24/7' },
    { label: 'Nigeria-First', value: 'Built for You' },
    { label: 'From', value: '₦5K/mo' },
  ];
</script>

<svelte:head>
  <title>Kemani POS - Offline-First POS for Nigerian Businesses</title>
  <meta name="description" content="Nigeria's first offline-first POS platform. Process sales, manage inventory, and serve customers — even when the internet doesn't cooperate." />
</svelte:head>

<div class="min-h-screen theme-gradient-page transition-theme">
  <!-- Navigation -->
  <nav class="border-b theme-nav backdrop-blur-md fixed top-0 w-full z-50 transition-theme">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between items-center h-16">
        <a href="/" class="flex items-center">
          <span class="text-2xl font-bold theme-logo transition-theme">Kemani</span>
          <span class="ml-2 text-sm theme-logo-subtitle transition-theme">POS</span>
        </a>
        <div class="hidden md:flex items-center gap-6">
          <a href="#features" class="theme-nav-link transition text-sm">Features</a>
          <a href="#benefits" class="theme-nav-link transition text-sm">Benefits</a>
          <a href="/pricing" class="theme-nav-link transition text-sm">Pricing</a>
          <ThemeToggle />
          <a href="/login" class="px-4 py-2 theme-btn-outline border rounded-lg transition text-sm">
            Sign In
          </a>
          <a href="/register" class="px-4 py-2 bg-gradient-to-r from-emerald-600 to-green-600 text-white rounded-lg hover:from-emerald-500 hover:to-green-500 transition text-sm font-medium">
            Start Free
          </a>
        </div>
      </div>
    </div>
  </nav>

  <!-- Hero Section -->
  <section class="pt-24 pb-16 px-4 sm:px-6 lg:px-8">
    <div class="max-w-6xl mx-auto">
      <div class="text-center">
        <h1 class="text-4xl sm:text-5xl md:text-6xl font-bold theme-heading mb-6 leading-tight">
          Your Business Never Stops.
          <br />
          <span class="text-transparent bg-clip-text bg-gradient-to-r from-emerald-600 to-green-600 dark:from-emerald-400 dark:to-green-300">
            Neither Should Your POS.
          </span>
        </h1>
        <p class="text-lg sm:text-xl theme-text-muted mb-8 max-w-3xl mx-auto leading-relaxed">
          Nigeria's first offline-first POS platform. Process sales, manage inventory, and serve customers — even when the internet doesn't cooperate.
        </p>
        <div class="flex flex-col sm:flex-row gap-4 justify-center items-center">
          <a href="/register?plan=free" class="inline-flex items-center justify-center w-full sm:w-auto px-8 py-3 bg-gradient-to-r from-emerald-600 to-green-600 text-white font-semibold rounded-lg hover:from-emerald-500 hover:to-green-500 transition shadow-lg">
            Start Free Forever
            <ArrowRight class="ml-2 h-5 w-5" />
          </a>
          <a href="#features" class="inline-flex items-center justify-center w-full sm:w-auto px-8 py-3 theme-btn-outline backdrop-blur-md font-semibold rounded-lg border transition">
            Learn More
          </a>
        </div>
        <p class="mt-4 text-sm theme-text-muted">
          Forever free plan • No credit card required • Upgrade anytime
        </p>
      </div>

      <!-- Trust Badges -->
      <div class="mt-16 grid grid-cols-2 sm:grid-cols-4 gap-4 max-w-4xl mx-auto">
        {#each trustBadges as badge}
          <div class="text-center bg-white/5 backdrop-blur-sm rounded-lg p-4 border border-emerald-500/20 hover:border-emerald-400/40 transition">
            <div class="text-2xl sm:text-3xl font-bold theme-logo">{badge.value}</div>
            <div class="text-xs sm:text-sm theme-text-muted mt-1">{badge.label}</div>
          </div>
        {/each}
      </div>
    </div>
  </section>

  <!-- Features Section -->
  <section id="features" class="py-16 sm:py-20">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="text-center mb-12">
        <h2 class="text-3xl sm:text-4xl font-bold theme-heading mb-4">
          Everything You Need to Run Your Business
        </h2>
        <p class="text-base sm:text-lg theme-text-muted max-w-2xl mx-auto">
          From in-store sales to online orders, delivery to analytics — all in one platform.
        </p>
      </div>

      <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {#each features as feature}
          <div class="p-6 bg-white/5 backdrop-blur-md rounded-xl hover:bg-white/10 transition border border-emerald-500/20 hover:border-emerald-400/40 group">
            <div class="w-12 h-12 bg-emerald-500/20 rounded-lg flex items-center justify-center mb-4 group-hover:bg-emerald-500/30 transition">
              <svelte:component this={feature.icon} class="h-6 w-6 theme-logo" />
            </div>
            <h3 class="text-lg font-semibold theme-heading mb-2">{feature.title}</h3>
            <p class="text-sm theme-text-muted leading-relaxed">{feature.description}</p>
          </div>
        {/each}
      </div>
    </div>
  </section>

  <!-- Footer -->
  <footer class="bg-gray-900 text-gray-300 py-12 border-t border-emerald-800/30">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="grid md:grid-cols-4 gap-8">
        <div>
          <div class="flex items-center mb-4">
            <span class="text-2xl font-bold text-emerald-400">Kemani</span>
            <span class="ml-2 text-sm text-emerald-300/70">POS</span>
          </div>
          <p class="text-sm text-gray-400">
            Offline-first POS platform built for Nigerian businesses.
          </p>
        </div>

        <div>
          <h3 class="text-white font-semibold mb-4">Product</h3>
          <ul class="space-y-2 text-sm">
            <li><a href="#features" class="hover:text-emerald-400 transition">Features</a></li>
            <li><a href="/pricing" class="hover:text-emerald-400 transition">Pricing</a></li>
            <li><a href="#demo" class="hover:text-emerald-400 transition">Demo</a></li>
          </ul>
        </div>

        <div>
          <h3 class="text-white font-semibold mb-4">Support</h3>
          <ul class="space-y-2 text-sm">
            <li><a href="/docs" class="hover:text-emerald-400 transition">Documentation</a></li>
            <li><a href="/support" class="hover:text-emerald-400 transition">Help Center</a></li>
            <li><a href="/contact" class="hover:text-emerald-400 transition">Contact Us</a></li>
          </ul>
        </div>

        <div>
          <h3 class="text-white font-semibold mb-4">Legal</h3>
          <ul class="space-y-2 text-sm">
            <li><a href="/privacy" class="hover:text-emerald-400 transition">Privacy Policy</a></li>
            <li><a href="/terms" class="hover:text-emerald-400 transition">Terms of Service</a></li>
          </ul>
        </div>
      </div>

      <div class="border-t border-gray-800 mt-8 pt-8 text-center text-sm text-gray-400">
        <p>&copy; {new Date().getFullYear()} Kemani POS. All rights reserved. Built with ❤️ for Nigerian businesses.</p>
      </div>
    </div>
  </footer>
</div>

<style>
  /* Any component-specific styles here */
  /* Most styling via Tailwind classes above */
</style>
```

**Key SvelteKit Features Used:**
- ✅ `<svelte:head>` for SEO meta tags
- ✅ `{#each}` for loops (like `.map()` in React)
- ✅ `<svelte:component this={Icon}>` for dynamic components
- ✅ Regular `<a>` tags (SvelteKit handles client-side navigation)
- ✅ No `useState` - just use variables in `<script>`

---

### Page 2: Pricing Page

**File: `src/routes/pricing/+page.svelte`**

```svelte
<script lang="ts">
  import { Check, ArrowRight, Zap, TrendingUp, Crown, Sparkles, Phone } from 'lucide-svelte';
  import ThemeToggle from '$lib/components/ThemeToggle.svelte';

  const pricingPlans = [
    {
      name: "Free",
      icon: Zap,
      description: "Get started with basic POS features",
      price: "₦0",
      period: "/month",
      annual: "Forever free",
      features: [
        "1 branch location",
        "1 staff user",
        // ... rest of features
      ],
      limitations: [
        "No offline mode",
        // ... rest
      ],
      cta: "Start Free Forever",
      href: "/auth/signup?plan=free",
      popular: false,
      color: "gray"
    },
    // ... rest of plans
  ];
</script>

<svelte:head>
  <title>Pricing - Kemani POS</title>
  <meta name="description" content="Simple, transparent pricing. Start free, upgrade when you need more." />
</svelte:head>

<div class="min-h-screen theme-gradient-page transition-theme">
  <!-- Navigation (same as landing page, or extract to layout) -->

  <!-- Hero -->
  <section class="pt-24 pb-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-4xl mx-auto text-center">
      <h1 class="text-4xl sm:text-5xl md:text-6xl font-bold theme-heading mb-6">
        Simple, Transparent Pricing
      </h1>
      <p class="text-lg sm:text-xl theme-text-muted mb-6">
        Start free, upgrade when you need more. No hidden fees, no surprises.
      </p>
    </div>
  </section>

  <!-- Pricing Cards -->
  <section class="pb-16 px-4 sm:px-6 lg:px-8">
    <div class="max-w-7xl mx-auto">
      <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        {#each pricingPlans.slice(0, 3) as plan}
          <div class="relative bg-white/5 backdrop-blur-md rounded-xl shadow-lg border {plan.popular ? 'border-emerald-500/60 ring-2 ring-emerald-500/20 lg:scale-105' : 'border-emerald-800/30'}">
            {#if plan.popular}
              <div class="absolute top-0 right-0 bg-gradient-to-r from-emerald-600 to-green-600 text-white px-3 py-1 text-xs font-semibold rounded-bl-lg">
                Most Popular
              </div>
            {/if}

            <div class="p-6">
              <!-- Header -->
              <div class="flex items-center mb-3">
                <div class="w-10 h-10 bg-emerald-500/20 rounded-lg flex items-center justify-center mr-3">
                  <svelte:component this={plan.icon} class="h-5 w-5 theme-logo" />
                </div>
                <h3 class="text-xl font-bold theme-heading">{plan.name}</h3>
              </div>
              <p class="text-sm theme-text-muted mb-6">{plan.description}</p>

              <!-- Pricing -->
              <div class="mb-5">
                <div class="flex items-baseline">
                  <span class="text-3xl sm:text-4xl font-bold theme-heading">{plan.price}</span>
                  <span class="theme-text-muted ml-2 text-sm">{plan.period}</span>
                </div>
                <p class="text-xs mt-1 font-medium theme-logo">{plan.annual}</p>
              </div>

              <!-- CTA -->
              <a href={plan.href} class="block w-full py-2.5 px-6 text-center text-sm font-semibold rounded-lg transition {plan.popular ? 'bg-gradient-to-r from-emerald-600 to-green-600 text-white hover:from-emerald-500 hover:to-green-500' : 'bg-emerald-500/20 text-emerald-300 hover:bg-emerald-500/30'}">
                {plan.cta}
              </a>

              <!-- Features -->
              <div class="mt-6 space-y-3">
                <div class="text-sm font-semibold theme-heading mb-2">What's included:</div>
                <ul class="space-y-2">
                  {#each plan.features as feature}
                    <li class="flex items-start">
                      <Check class="h-4 w-4 theme-logo mr-2 flex-shrink-0 mt-0.5" />
                      <span class="theme-text-muted text-xs leading-relaxed">{feature}</span>
                    </li>
                  {/each}
                </ul>

                {#if plan.limitations.length > 0}
                  <div class="mt-4 pt-4 border-t border-emerald-800/30">
                    <div class="text-xs theme-text-muted opacity-70 space-y-1">
                      <div class="font-medium mb-1">Not included:</div>
                      {#each plan.limitations as limitation}
                        <div>• {limitation}</div>
                      {/each}
                    </div>
                  </div>
                {/if}
              </div>
            </div>
          </div>
        {/each}
      </div>
    </div>
  </section>

  <!-- Footer -->
</div>
```

**Svelte Syntax Highlights:**
- `{#if}` for conditionals (vs `{condition &&}` in React)
- `{#each array as item}` for loops
- ` No need for `key` prop - Svelte handles it
- Template expressions in attributes: `class={variable}`

---

### Page 3: Marketplace Storefront (Dynamic Route)

**File: `src/routes/shop/[tenantId]/+page.server.ts`**

```typescript
// Server-side data loading
import type { PageServerLoad } from './$types';
import { error } from '@sveltejs/kit';
import { MarketplaceService } from '$lib/services/marketplace';

export const load: PageServerLoad = async ({ params, url }) => {
  const { tenantId } = params;
  const category = url.searchParams.get('category');
  const searchQuery = url.searchParams.get('q');

  // Resolve tenant ID if slug
  let resolvedTenantId = tenantId;
  const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(tenantId);

  if (!isUuid) {
    try {
      resolvedTenantId = await MarketplaceService.getTenantIdBySlug(tenantId);
    } catch (e) {
      throw error(404, 'Store not found');
    }
  }

  // Fetch data
  try {
    const [storeDetails, products] = await Promise.all([
      MarketplaceService.getStorefrontDetails(resolvedTenantId),
      MarketplaceService.getStorefrontProducts(resolvedTenantId, category)
    ]);

    // Filter by search query
    const filteredProducts = searchQuery
      ? products.filter(p => p.name.toLowerCase().includes(searchQuery.toLowerCase()))
      : products;

    return {
      storeDetails,
      products: filteredProducts,
      tenantId: resolvedTenantId,
      category,
      searchQuery
    };
  } catch (e) {
    throw error(404, 'Store not found');
  }
};
```

**File: `src/routes/shop/[tenantId]/+page.svelte`**

```svelte
<script lang="ts">
  import { Search, ShoppingCart, MapPin, Star } from 'lucide-svelte';
  import { Button } from '$lib/components/ui/button';
  import ProductCard from '$lib/components/ProductCard.svelte';
  import type { PageData } from './$types';

  // Data from +page.server.ts
  export let data: PageData;

  const { storeDetails, products, tenantId } = data;

  function formatPrice(amount: number) {
    return new Intl.NumberFormat('en-NG', {
      style: 'currency',
      currency: 'NGN',
    }).format(amount);
  }
</script>

<svelte:head>
  <title>{storeDetails.name} - Shop Online</title>
  <meta name="description" content="Browse {storeDetails.name}'s catalog and order online." />
</svelte:head>

<div class="min-h-screen bg-slate-50">
  <!-- Header -->
  <header class="sticky top-0 z-10 bg-white border-b shadow-sm">
    <div class="container mx-auto px-4 h-16 flex items-center justify-between gap-4">
      <div class="flex items-center gap-2">
        <h1 class="text-xl font-bold truncate" style="color: {storeDetails.brandColor || '#000'}">
          {storeDetails.name}
        </h1>
      </div>

      <!-- Search (Desktop) -->
      <div class="flex-1 max-w-md hidden md:block">
        <form method="GET" class="relative">
          <Search class="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <input
            type="search"
            name="q"
            value={data.searchQuery || ''}
            placeholder="Search products..."
            class="w-full pl-9 pr-3 py-2 bg-slate-50 border border-slate-200 rounded-md focus:outline-none focus:ring-2 focus:ring-emerald-500"
          />
        </form>
      </div>

      <div class="flex items-center gap-4">
        <a href="/{tenantId}/cart">
          <button class="relative p-2 hover:bg-slate-100 rounded-lg">
            <ShoppingCart class="h-5 w-5" />
          </button>
        </a>
        <a href="/login">
          <button class="px-4 py-2 text-sm hover:bg-slate-100 rounded-lg">Sign In</button>
        </a>
      </div>
    </div>
  </header>

  <!-- Hero -->
  <div class="bg-white border-b">
    <div class="container mx-auto px-4 py-8 md:py-12 text-center">
      <h2 class="text-3xl md:text-4xl font-bold mb-4">
        {storeDetails.settings?.storeName || `Welcome to ${storeDetails.name}`}
      </h2>
      <p class="text-muted-foreground max-w-2xl mx-auto mb-6">
        {storeDetails.settings?.storeDescription || 'Browse our catalog and order online.'}
      </p>
      <div class="flex justify-center gap-2 text-sm text-muted-foreground">
        <span class="flex items-center gap-1"><MapPin class="h-4 w-4" /> Local Delivery</span>
        <span>•</span>
        <span class="flex items-center gap-1"><Star class="h-4 w-4 text-yellow-500 fill-yellow-500" /> 4.8 Rating</span>
      </div>
    </div>
  </div>

  <!-- Main Content -->
  <main class="container mx-auto px-4 py-8">
    <!-- Categories -->
    <div class="mb-8 overflow-x-auto pb-2">
      <div class="flex gap-2 min-w-max">
        <a href="/shop/{tenantId}" class="px-4 py-2 rounded-full {!data.category ? 'bg-emerald-600 text-white' : 'bg-white border hover:bg-slate-50'}">
          All Items
        </a>
        <a href="/shop/{tenantId}?category=food" class="px-4 py-2 rounded-full {data.category === 'food' ? 'bg-emerald-600 text-white' : 'bg-white border hover:bg-slate-50'}">
          Food & Drinks
        </a>
      </div>
    </div>

    <!-- Product Grid -->
    {#if products && products.length > 0}
      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 md:gap-6">
        {#each products as product}
          <ProductCard {product} {tenantId} {formatPrice} />
        {/each}
      </div>
    {:else}
      <div class="text-center py-12">
        <Search class="h-12 w-12 mx-auto text-slate-400 mb-4" />
        <h3 class="text-lg font-medium">No products found</h3>
        <p class="text-muted-foreground mt-2">Try adjusting your search or filter.</p>
      </div>
    {/if}
  </main>

  <!-- Footer -->
  <footer class="bg-slate-900 text-slate-300 py-12 mt-12">
    <!-- Footer content -->
  </footer>
</div>
```

**SvelteKit Features:**
- ✅ `+page.server.ts` for SSR data fetching
- ✅ `export let data` receives server data
- ✅ Type safety with `PageData` from `./$types`
- ✅ Forms use native HTML (no JS needed for basic search)
- ✅ `{#if products.length > 0}` with `{:else}` block

---

## Styling Migration

### Tailwind CSS (Same as Next.js)

**File: `tailwind.config.js`**

```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      colors: {
        emerald: {
          // Same colors as Next.js
        }
      }
    },
  },
  plugins: [],
}
```

**File: `src/app.css`**

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Copy all custom theme classes from Next.js app/globals.css */
.theme-gradient-page {
  @apply bg-gradient-to-br from-slate-50 to-emerald-50;
}

.theme-logo {
  @apply text-emerald-600 dark:text-emerald-400;
}

/* ... rest of theme classes */
```

**Import in layout:**

```svelte
<!-- src/routes/+layout.svelte -->
<script>
  import '../app.css';
</script>

<slot />
```

---

## Data Fetching

### Supabase Integration

**File: `src/lib/services/supabase.ts`**

```typescript
import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

export const supabase = createClient(
  PUBLIC_SUPABASE_URL,
  PUBLIC_SUPABASE_ANON_KEY
);
```

**File: `.env`** (create this)

```
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

**File: `src/lib/services/marketplace.ts`**

```typescript
import { supabase } from './supabase';
import type { Product, StoreDetails } from '$lib/types';

export class MarketplaceService {
  static async getStorefrontDetails(tenantId: string): Promise<StoreDetails> {
    const { data, error } = await supabase
      .from('tenants')
      .select('*')
      .eq('id', tenantId)
      .single();

    if (error) throw error;
    return data;
  }

  static async getStorefrontProducts(tenantId: string, category?: string): Promise<Product[]> {
    let query = supabase
      .from('products')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('published', true);

    if (category) {
      query = query.eq('category', category);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  }

  static async getTenantIdBySlug(slug: string): Promise<string> {
    const { data, error } = await supabase
      .from('tenants')
      .select('id')
      .eq('slug', slug)
      .single();

    if (error) throw error;
    return data.id;
  }
}
```

---

## Deployment

### Deploy to Vercel (Recommended)

1. **Install Vercel Adapter:**

```bash
npm install -D @sveltejs/adapter-vercel
```

2. **Update `svelte.config.js`:**

```javascript
import adapter from '@sveltejs/adapter-vercel';

export default {
  kit: {
    adapter: adapter({
      runtime: 'nodejs18.x'
    })
  }
};
```

3. **Deploy:**

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
vercel --prod
```

4. **Set Environment Variables in Vercel:**
   - Go to Vercel dashboard
   - Settings → Environment Variables
   - Add `PUBLIC_SUPABASE_URL` and `PUBLIC_SUPABASE_ANON_KEY`

### Custom Domain Setup

**In Vercel:**
1. Go to project → Settings → Domains
2. Add `yourdomain.com`
3. Add DNS records as instructed
4. Add `shop.yourdomain.com` for marketplace

**Final URLs:**
- `yourdomain.com` → Landing page
- `yourdomain.com/pricing` → Pricing
- `shop.yourdomain.com/[tenantId]` → Marketplace (or `yourdomain.com/shop/[tenantId]`)

---

## Migration Checklist

### Phase 1: Setup (Week 1)
- [ ] Create SvelteKit project
- [ ] Install dependencies (Tailwind, Supabase, Lucide)
- [ ] Set up project structure
- [ ] Configure Tailwind CSS
- [ ] Copy theme classes from Next.js

### Phase 2: Landing Page (Week 1-2)
- [ ] Create `routes/+page.svelte`
- [ ] Migrate hero section
- [ ] Migrate features section
- [ ] Migrate benefits section
- [ ] Migrate use cases section
- [ ] Migrate CTAs
- [ ] Extract nav and footer to components

### Phase 3: Pricing Page (Week 2)
- [ ] Create `routes/pricing/+page.svelte`
- [ ] Migrate pricing cards
- [ ] Migrate comparison table
- [ ] Migrate FAQ section

### Phase 4: Marketplace (Week 3)
- [ ] Create `routes/shop/[tenantId]/+page.server.ts`
- [ ] Create `routes/shop/[tenantId]/+page.svelte`
- [ ] Implement Supabase service
- [ ] Create product card component
- [ ] Implement search and filtering
- [ ] Create product detail page
- [ ] Create cart page

### Phase 5: Testing & Optimization (Week 4)
- [ ] Test all pages on mobile
- [ ] Run Lighthouse audits
- [ ] Optimize images
- [ ] Test SEO meta tags
- [ ] Test Supabase connections
- [ ] Test dynamic routes

### Phase 6: Deployment (Week 4)
- [ ] Deploy to Vercel staging
- [ ] Configure environment variables
- [ ] Set up custom domain
- [ ] Test production build
- [ ] Deploy to production

---

## Quick Command Reference

```bash
# Create project
npm create svelte@latest marketing_sveltekit

# Install dependencies
npm install

# Add Tailwind
npx svelte-add@latest tailwindcss

# Development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Deploy to Vercel
vercel --prod

# Type check
npm run check
```

---

## Key Differences Summary

| Feature | Next.js | SvelteKit |
|---------|---------|-----------|
| **File Extension** | `.tsx` | `.svelte` |
| **Routing** | `app/page.tsx` | `routes/+page.svelte` |
| **Server Data** | Server Components | `+page.server.ts` |
| **Links** | `<Link href="">` | `<a href="">` |
| **Conditionals** | `{condition &&}` | `{#if condition}` |
| **Loops** | `.map()` | `{#each}` |
| **State** | `useState` | Just use variables |
| **Effects** | `useEffect` | `$effect` (Svelte 5) |
| **Props** | `interface Props` | `export let name` |

---

## Next Steps

1. **Review this guide**
2. **Create SvelteKit project** (see Setup section)
3. **Migrate landing page first** (simplest to start)
4. **Test locally** before moving to pricing
5. **Deploy to Vercel staging** when ready

Would you like me to help you create the SvelteKit project now?

---

**Document Version**: 1.0
**Last Updated**: 2026-02-11
**Status**: Ready to Use
**Estimated Migration Time**: 3-4 weeks
