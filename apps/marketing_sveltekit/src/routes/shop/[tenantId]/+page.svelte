<script lang="ts">
  import { Search, ShoppingCart, MapPin, Star, Home, Package } from 'lucide-svelte';
  import ProductCard from '$lib/components/ProductCard.svelte';
  import type { PageData } from './$types';

  // Data from +page.server.ts (SSR)
  let { data }: { data: PageData } = $props();

  const { storeDetails, products, categories, tenantId, category, searchQuery } = data;

  function formatPrice(amount: number): string {
    return new Intl.NumberFormat('en-NG', {
      style: 'currency',
      currency: 'NGN',
    }).format(amount);
  }

  const brandColor = storeDetails.settings?.brandColor || '#16a34a';
</script>

<svelte:head>
  <title>{storeDetails.name} - Shop Online</title>
  <meta name="description" content="Browse {storeDetails.name}'s catalog and order online. {storeDetails.settings?.storeDescription || ''}" />
</svelte:head>

<div class="min-h-screen bg-slate-50 dark:bg-slate-900">
  <!-- Header -->
  <header class="sticky top-0 z-10 bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 shadow-sm">
    <div class="container mx-auto px-4 h-16 flex items-center justify-between gap-4">
      <!-- Store Name -->
      <div class="flex items-center gap-2 min-w-0">
        {#if storeDetails.settings?.logo}
          <img src={storeDetails.settings.logo} alt={storeDetails.name} class="h-8 w-8 rounded" />
        {/if}
        <a href="/shop/{tenantId}" class="flex items-center gap-2">
          <h1 class="text-xl font-bold truncate hover:text-emerald-600 dark:hover:text-emerald-400 transition" style="color: {brandColor}">
            {storeDetails.name}
          </h1>
        </a>
      </div>

      <!-- Search (Desktop) -->
      <div class="flex-1 max-w-md hidden md:block">
        <form method="GET" action="/shop/{tenantId}" class="relative">
          <Search class="absolute left-2.5 top-2.5 h-4 w-4 text-slate-400" />
          <input
            type="search"
            name="q"
            value={searchQuery || ''}
            placeholder="Search products..."
            class="w-full pl-9 pr-3 py-2 bg-slate-50 dark:bg-slate-700 border border-slate-200 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-emerald-500 dark:focus:ring-emerald-400"
          />
        </form>
      </div>

      <!-- Actions -->
      <div class="flex items-center gap-4">
        <a href="/shop/{tenantId}/cart" class="relative p-2 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-lg transition">
          <ShoppingCart class="h-5 w-5 theme-heading" />
          <span class="absolute -top-1 -right-1 bg-emerald-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
            0
          </span>
        </a>
        <a href="/" class="hidden sm:block px-4 py-2 text-sm hover:bg-slate-100 dark:hover:bg-slate-700 rounded-lg transition theme-heading">
          <Home class="h-4 w-4" />
        </a>
      </div>
    </div>

    <!-- Search (Mobile) -->
    <div class="md:hidden px-4 pb-3">
      <form method="GET" action="/shop/{tenantId}" class="relative">
        <Search class="absolute left-2.5 top-2.5 h-4 w-4 text-slate-400" />
        <input
          type="search"
          name="q"
          value={searchQuery || ''}
          placeholder="Search products..."
          class="w-full pl-9 pr-3 py-2 bg-slate-50 dark:bg-slate-700 border border-slate-200 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-emerald-500"
        />
      </form>
    </div>
  </header>

  <!-- Hero Banner -->
  <div class="bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700">
    <div class="container mx-auto px-4 py-8 md:py-12 text-center">
      <h2 class="text-3xl md:text-4xl font-bold theme-heading mb-4">
        {storeDetails.settings?.storeName || `Welcome to ${storeDetails.name}`}
      </h2>
      <p class="theme-text-muted max-w-2xl mx-auto mb-6">
        {storeDetails.settings?.storeDescription || 'Browse our catalog and order online for convenient delivery.'}
      </p>
      <div class="flex flex-wrap justify-center gap-4 text-sm theme-text-muted">
        <span class="flex items-center gap-1">
          <MapPin class="h-4 w-4 text-emerald-500" />
          Local Delivery Available
        </span>
        <span>•</span>
        <span class="flex items-center gap-1">
          <Star class="h-4 w-4 text-yellow-500 fill-yellow-500" />
          4.8 Rating
        </span>
        <span>•</span>
        <span class="flex items-center gap-1">
          <Package class="h-4 w-4 text-emerald-500" />
          Fast Shipping
        </span>
      </div>
    </div>
  </div>

  <!-- Main Content -->
  <main class="container mx-auto px-4 py-8">
    <!-- Categories -->
    {#if categories.length > 0}
      <div class="mb-8 overflow-x-auto pb-2 scrollbar-hide">
        <div class="flex gap-2 min-w-max">
          <a
            href="/shop/{tenantId}"
            class="px-4 py-2 rounded-full text-sm font-medium transition whitespace-nowrap {!category ? 'bg-emerald-600 text-white' : 'bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 theme-heading hover:bg-slate-50 dark:hover:bg-slate-700'}"
          >
            All Items
          </a>
          {#each categories as cat}
            <a
              href="/shop/{tenantId}?category={cat}"
              class="px-4 py-2 rounded-full text-sm font-medium transition whitespace-nowrap {category === cat ? 'bg-emerald-600 text-white' : 'bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 theme-heading hover:bg-slate-50 dark:hover:bg-slate-700'}"
            >
              {cat}
            </a>
          {/each}
        </div>
      </div>
    {/if}

    <!-- Search Results Info -->
    {#if searchQuery}
      <div class="mb-6 flex items-center justify-between">
        <p class="theme-text-muted">
          {products.length} {products.length === 1 ? 'result' : 'results'} for "{searchQuery}"
        </p>
        <a href="/shop/{tenantId}" class="text-sm text-emerald-600 dark:text-emerald-400 hover:underline">
          Clear search
        </a>
      </div>
    {/if}

    <!-- Product Grid -->
    {#if products && products.length > 0}
      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 md:gap-6">
        {#each products as product}
          <ProductCard {product} {tenantId} {formatPrice} />
        {/each}
      </div>
    {:else}
      <div class="text-center py-12">
        <Search class="h-12 w-12 mx-auto theme-text-muted mb-4" />
        <h3 class="text-lg font-medium theme-heading">No products found</h3>
        <p class="theme-text-muted mt-2">
          {#if searchQuery}
            Try adjusting your search term.
          {:else if category}
            No products in this category yet.
          {:else}
            This store doesn't have any products yet.
          {/if}
        </p>
        {#if searchQuery || category}
          <a href="/shop/{tenantId}" class="inline-block mt-4 px-6 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-500 transition">
            View all products
          </a>
        {/if}
      </div>
    {/if}
  </main>

  <!-- Footer -->
  <footer class="bg-slate-900 text-slate-300 py-12 mt-12 border-t border-slate-800">
    <div class="container mx-auto px-4 text-center">
      <div class="flex items-center justify-center mb-4">
        <span class="text-xl font-bold text-emerald-400">{storeDetails.name}</span>
      </div>
      <p class="text-sm text-slate-400 mb-6">
        Powered by <a href="/" class="text-emerald-400 hover:text-emerald-300 transition">Kemani POS</a>
      </p>
      <div class="flex flex-wrap justify-center gap-6 text-sm">
        <a href="/shop/{tenantId}/about" class="hover:text-emerald-400 transition">About</a>
        <a href="/shop/{tenantId}/contact" class="hover:text-emerald-400 transition">Contact</a>
        <a href="/privacy" class="hover:text-emerald-400 transition">Privacy</a>
        <a href="/terms" class="hover:text-emerald-400 transition">Terms</a>
      </div>
    </div>
  </footer>
</div>

<style>
  .scrollbar-hide::-webkit-scrollbar {
    display: none;
  }
  .scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }
</style>
