# Kemani POS - SvelteKit Marketing Site

This is the marketing website for Kemani POS, built with SvelteKit for optimal performance and SEO.

## 🎯 What's Included

### Pages
- **Landing Page** (`/`) - Full-featured homepage with hero, features, benefits, testimonials
- **Pricing Page** (`/pricing`) - 4 pricing tiers (Free, Professional, Business, Enterprise) with FAQ
- **Marketplace** (`/shop/[tenantId]`) - Dynamic storefront for each tenant with:
  - Server-side rendering (SSR) for SEO
  - Product grid with search and filtering
  - Category navigation
  - Shopping cart integration ready

### Components
- **ThemeToggle** - Light/dark mode switcher with localStorage persistence
- **ProductCard** - Reusable product display component
- **Navigation** - Responsive header with theme toggle

### Features
- ✅ **Svelte 5 Runes** - Modern reactive state management
- ✅ **Tailwind CSS 4** - Latest styling with CSS variables
- ✅ **Server-Side Rendering** - Optimized for SEO
- ✅ **Dark Mode** - Full theme support with neon effects
- ✅ **Type Safety** - Full TypeScript support
- ✅ **Supabase Ready** - Marketplace service integration

## 🚀 Getting Started

### Prerequisites
- Node.js 18+
- npm or yarn

### Installation

```bash
cd apps/marketing_sveltekit
npm install
```

### Environment Variables

Create a `.env` file (see `.env.example`):

```bash
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
```

### Development

```bash
npm run dev
```

Visit http://localhost:5173 (or next available port)

### Build for Production

```bash
npm run build
npm run preview  # Preview production build locally
```

## 📁 Project Structure

```
src/
├── routes/
│   ├── +layout.svelte              # Root layout
│   ├── +page.svelte                # Landing page
│   ├── pricing/
│   │   └── +page.svelte            # Pricing page
│   └── shop/
│       └── [tenantId]/
│           ├── +page.server.ts     # SSR data loading
│           └── +page.svelte        # Marketplace storefront
├── lib/
│   ├── components/
│   │   ├── ThemeToggle.svelte
│   │   └── ProductCard.svelte
│   ├── services/
│   │   ├── supabase.ts
│   │   └── marketplace.ts
│   └── types/
│       └── index.ts
├── app.css                          # Global styles with theme
└── app.html                         # HTML template
```

## 🎨 Theming

The site includes comprehensive theming with:
- CSS variables for colors
- Light/dark mode support
- Neon effects in dark mode
- Glassmorphism utilities
- Custom scrollbar styling

Theme classes available:
- `.theme-gradient-page` - Page background
- `.theme-heading` - Text headings
- `.theme-text-muted` - Muted text
- `.theme-logo` - Brand colors
- `.theme-nav-link` - Navigation links
- `.theme-btn-outline` - Outline buttons

## 🔌 Supabase Integration

The marketplace uses Supabase for data:

### Required Tables
- `tenants` - Store/tenant information
- `products` - Product catalog

### Services
- `MarketplaceService.getStorefrontDetails()` - Get store info
- `MarketplaceService.getStorefrontProducts()` - Get products
- `MarketplaceService.getTenantIdBySlug()` - Resolve slug to ID
- `MarketplaceService.getCategories()` - Get product categories

## 📊 Performance Benefits

### vs Next.js
- **50-70% smaller bundle** (~30-50KB vs ~200-300KB)
- **Faster page loads** - No React overhead
- **Better Lighthouse scores** - Optimized by default
- **Faster builds** - Vite-powered compilation

### SEO Features
- Server-side rendering (SSR)
- Dynamic meta tags
- Semantic HTML
- Fast page loads (Core Web Vitals)

## 🚢 Deployment

### Vercel (Recommended)

1. Install adapter:
```bash
npm install -D @sveltejs/adapter-vercel
```

2. Update `svelte.config.js`:
```js
import adapter from '@sveltejs/adapter-vercel';

export default {
  kit: {
    adapter: adapter()
  }
};
```

3. Deploy:
```bash
vercel --prod
```

4. Set environment variables in Vercel dashboard

### Other Platforms
- **Netlify** - Use `@sveltejs/adapter-netlify`
- **Cloudflare Pages** - Use `@sveltejs/adapter-cloudflare`
- **Node.js** - Use `@sveltejs/adapter-node`

## 🧪 Testing

```bash
npm run check       # Type checking
npm run build       # Production build test
```

## 📝 Key Differences from Next.js

| Feature | Next.js | SvelteKit |
|---------|---------|-----------|
| **File Extension** | `.tsx` | `.svelte` |
| **Routing** | `app/page.tsx` | `routes/+page.svelte` |
| **Server Data** | Server Components | `+page.server.ts` |
| **Links** | `<Link href="">` | `<a href="">` |
| **Conditionals** | `{condition &&}` | `{#if condition}` |
| **Loops** | `.map()` | `{#each}` |
| **State** | `useState` | `$state` (runes) |
| **Effects** | `useEffect` | `$effect` |

## 🧪 Testing Dark Mode

Dark mode is fully functional across all pages. To test:

1. **Visit any page** (landing, pricing, or marketplace)
2. **Click the theme toggle button** (Moon/Sun icon) in the navigation
3. **Verify the theme changes**:
   - Background colors shift
   - Text colors adjust
   - Accent colors change (neon green in dark mode)
4. **Refresh the page** - Theme should persist via localStorage
5. **Open in new tab** - Theme preference carries over

### How Dark Mode Works

1. **app.html** - Sets initial theme before page renders (prevents flash)
2. **ThemeToggle.svelte** - Component for toggling between light/dark
3. **app.css** - Contains all theme-specific CSS with `[data-theme="dark"]` selectors
4. **tailwind.config.js** - Configured to use `data-theme` attribute for `dark:` utilities

## 🐛 Troubleshooting

### Dark mode not working
- Clear browser cache and hard refresh (Ctrl+Shift+R)
- Check browser console for errors
- Verify `localStorage.theme` is being set (check DevTools → Application → Local Storage)
- Make sure Tailwind dark mode is configured in `tailwind.config.js`

### Tailwind CSS not working
Make sure you have `@tailwindcss/postcss` installed:
```bash
npm install -D @tailwindcss/postcss
```

### Port already in use
Vite will automatically use the next available port (5174, 5175, etc.)

### Supabase connection errors
- Check your `.env` file has correct credentials
- Verify Supabase URL and anon key
- Check network connectivity

## 📚 Resources

- [SvelteKit Documentation](https://kit.svelte.dev)
- [Svelte 5 Runes](https://svelte.dev/docs/svelte/what-are-runes)
- [Tailwind CSS 4](https://tailwindcss.com)
- [Supabase Docs](https://supabase.com/docs)

## 📄 License

Part of Kemani POS - Multi-tenant POS platform for Nigerian businesses

---

**Built with ❤️ using SvelteKit**
