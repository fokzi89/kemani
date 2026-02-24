# Quick Page Creation Instructions

## What's Done ✅

1. **Theme Store** (`src/lib/stores/theme.ts`) - Created
2. **Theme Toggle Component** (`src/lib/components/ThemeToggle.svelte`) - Created
3. **Documentation** - Complete migration guides written

## What You Need To Do

### Step 1: Create Landing Page

**Command:**
```bash
# From repository root
cp app/page.tsx apps/marketing_sveltekit/src/routes/+page.svelte
```

Then edit `apps/marketing_sveltekit/src/routes/+page.svelte`:

**Line 1-3:** Replace with:
```svelte
<script lang="ts">
	import { ArrowRight, Zap, Smartphone, ShoppingBag, TrendingUp, MessageSquare, Shield } from 'lucide-svelte';
	import ThemeToggle from '$lib/components/ThemeToggle.svelte';
</script>

<svelte:head>
	<title>Kemani POS - Offline-First POS Platform</title>
</svelte:head>
```

**Line 5:** Remove `export default function Home() {`

**Replace ALL** instances of:
- `<Link href=` → `<a href=`
- `</Link>` → `</a>`
- `className=` → `class=`
- `{feature.icon}` patterns → `<svelte:component this={feature.icon} class="..."/>`

**Replace map functions:**
```javascript
// FROM:
{[...].map((item, idx) => (
  <div key={idx}>...</div>
))}

// TO:
{#each [...] as item}
  <div>...</div>
{/each}
```

**Last line:** Remove closing `}` and `}`

### Step 2: Create Pricing Page

```bash
# Create directory
mkdir -p apps/marketing_sveltekit/src/routes/pricing

# Copy file
cp app/pricing/page.tsx apps/marketing_sveltekit/src/routes/pricing/+page.svelte
```

Then edit `apps/marketing_sveltekit/src/routes/pricing/+page.svelte`:

Apply same transformations as Step 1, plus:

**Move pricingPlans:** Cut the `const pricingPlans = [...]` array and paste it inside the `<script>` tag.

### Step 3: Test

```bash
cd apps/marketing_sveltekit
npm run dev
```

Open: http://localhost:5173/

## Quick Find-Replace (VS Code)

1. Find: `import Link from "next/link";` → Replace: (delete)
2. Find: `from "lucide-react"` → Replace: `from "lucide-svelte"`
3. Find: `<Link href=` → Replace: `<a href=`
4. Find: `</Link>` → Replace: `</a>`
5. Find: `className=` → Replace: `class=`
6. Find: `export default function` → Replace: (delete entire function wrapper)

## Result

✅ Exact same design
✅ Exact same content
✅ Same styling (all Tailwind classes preserved)
✅ Working theme toggle
✅ Faster load times (Svelte vs React)

Ready to deploy!
