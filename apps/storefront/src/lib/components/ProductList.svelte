<script lang="ts">
    import { createEventDispatcher } from 'svelte';
    import ProductGrid from './ProductGrid.svelte';
    import ProductCard from './ProductCard.svelte';
    import { cn } from '$lib/utils.js';
    import { formatCurrency } from '$lib/storefront/pricing.js';
    import type { StorefrontProductWithCatalog } from '$lib/types/supabase.js';

    const dispatch = createEventDispatcher();

    export let products: StorefrontProductWithCatalog[] = [];
    export let loading = false;
    export let viewMode: 'grid' | 'list' = 'grid';
    export let gridColumns: 1 | 2 | 3 | 4 | 5 | 6 = 4;
    export let showViewToggle = true;
    export let showAddToCart = true;
    export let showStock = false;
    export let showBrand = true;
    export let showCategory = false;
    export let emptyMessage = 'No products found';
    export let emptyDescription = 'Try adjusting your search or filters';
    export let className: string | undefined = undefined;

    function handleViewModeChange(mode: 'grid' | 'list') {
        viewMode = mode;
        dispatch('view-mode-change', { viewMode: mode });
    }

    function handleProductClick(event: CustomEvent) {
        dispatch('product-click', event.detail);
    }

    function handleAddToCart(event: CustomEvent) {
        dispatch('add-to-cart', event.detail);
    }

    function handleQuickView(event: CustomEvent) {
        dispatch('quick-view', event.detail);
    }
</script>

<div class={cn("w-full space-y-4", className)}>
    <!-- View Toggle -->
    {#if showViewToggle}
        <div class="flex items-center justify-end">
            <div class="inline-flex rounded-md border border-input bg-background p-1">
                <button
                    type="button"
                    on:click={() => handleViewModeChange('grid')}
                    class={cn(
                        "inline-flex items-center justify-center rounded px-3 py-1.5 text-sm font-medium transition-colors",
                        viewMode === 'grid' 
                            ? "bg-primary text-primary-foreground shadow-sm" 
                            : "text-muted-foreground hover:text-foreground"
                    )}
                    aria-label="Grid view"
                >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
                    </svg>
                </button>
                <button
                    type="button"
                    on:click={() => handleViewModeChange('list')}
                    class={cn(
                        "inline-flex items-center justify-center rounded px-3 py-1.5 text-sm font-medium transition-colors",
                        viewMode === 'list' 
                            ? "bg-primary text-primary-foreground shadow-sm" 
                            : "text-muted-foreground hover:text-foreground"
                    )}
                    aria-label="List view"
                >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 10h16M4 14h16M4 18h16" />
                    </svg>
                </button>
            </div>
        </div>
    {/if}

    <!-- Content -->
    {#if viewMode === 'grid'}
        <ProductGrid
            {products}
            {loading}
            columns={gridColumns}
            {showAddToCart}
            {showStock}
            {showBrand}
            {showCategory}
            {emptyMessage}
            {emptyDescription}
            on:product-click={handleProductClick}
            on:add-to-cart={handleAddToCart}
            on:quick-view={handleQuickView}
        >
            <slot name="empty-action" slot="empty-action" />
        </ProductGrid>
    {:else}
        <!-- List View -->
        <div class="space-y-4">
            {#if loading}
                <!-- Loading Skeleton for List View -->
                {#each Array(5) as _}
                    <div class="flex gap-4 p-4 border rounded-lg bg-card animate-pulse">
                        <div class="w-24 h-24 bg-muted rounded-lg flex-shrink-0"></div>
                        <div class="flex-1 space-y-2">
                            <div class="h-5 bg-muted rounded w-3/4"></div>
                            <div class="h-4 bg-muted rounded w-1/2"></div>
                            <div class="h-4 bg-muted rounded w-1/4"></div>
                        </div>
                        <div class="flex flex-col justify-between items-end">
                            <div class="h-6 bg-muted rounded w-16"></div>
                            <div class="h-8 w-8 bg-muted rounded"></div>
                        </div>
                    </div>
                {/each}
            {:else if products.length > 0}
                {#each products as product (product.id)}
                    <div 
                        class="flex gap-4 p-4 border rounded-lg bg-card hover:shadow-md transition-shadow cursor-pointer group"
                        on:click={() => handleProductClick({ detail: { product } })}
                        on:keydown={(e) => e.key === 'Enter' && handleProductClick({ detail: { product } })}
                        role="button"
                        tabindex="0"
                    >
                        <!-- Image -->
                        <div class="w-24 h-24 flex-shrink-0 rounded-lg overflow-hidden bg-muted">
                            <img
                                src={product.primary_image || product.images?.[0] || "https://via.placeholder.com/96x96?text=No+Image"}
                                alt={product.name || "Product"}
                                class="w-full h-full object-cover group-hover:scale-105 transition-transform"
                                loading="lazy"
                            />
                        </div>

                        <!-- Content -->
                        <div class="flex-1 min-w-0">
                            <div class="space-y-1">
                                {#if showCategory && product.category}
                                    <p class="text-xs text-muted-foreground uppercase tracking-wide">
                                        {product.category}
                                    </p>
                                {/if}
                                
                                <h3 class="font-medium text-foreground group-hover:text-primary transition-colors line-clamp-2">
                                    {product.name || "Unnamed Product"}
                                </h3>
                                
                                {#if showBrand && product.brand}
                                    <p class="text-sm text-muted-foreground">
                                        by {product.brand}
                                    </p>
                                {/if}
                                
                                {#if product.description}
                                    <p class="text-sm text-muted-foreground line-clamp-2">
                                        {product.description}
                                    </p>
                                {/if}
                                
                                {#if showStock}
                                    <p class="text-xs text-muted-foreground">
                                        {#if (product.stock_quantity || 0) > 0}
                                            {product.stock_quantity} in stock
                                        {:else}
                                            Out of stock
                                        {/if}
                                    </p>
                                {/if}
                            </div>
                        </div>

                        <!-- Price and Actions -->
                        <div class="flex flex-col justify-between items-end">
                            <div class="text-right">
                                {#if product.compare_at_price && product.compare_at_price > (product.price || 0)}
                                    <p class="text-sm text-muted-foreground line-through">
                                        {formatCurrency(product.compare_at_price)}
                                    </p>
                                {/if}
                                <p class="text-lg font-bold text-primary">
                                    {formatCurrency(product.price || 0)}
                                </p>
                            </div>

                            {#if showAddToCart}
                                <button
                                    type="button"
                                    on:click={(e) => {
                                        e.preventDefault();
                                        e.stopPropagation();
                                        handleAddToCart({ detail: { product, quantity: 1, variantId: null } });
                                    }}
                                    disabled={!product.is_available || (product.stock_quantity || 0) <= 0}
                                    class="inline-flex h-8 w-8 items-center justify-center rounded-md bg-primary text-primary-foreground shadow transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50"
                                    aria-label="Add to cart"
                                >
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                    </svg>
                                </button>
                            {/if}
                        </div>
                    </div>
                {/each}
            {:else}
                <!-- Empty State -->
                <div class="flex flex-col items-center justify-center py-12 text-center">
                    <div class="w-16 h-16 mb-4 text-muted-foreground">
                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" class="w-full h-full">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M9 1L5 3l4 2 4-2-4-2z" />
                        </svg>
                    </div>
                    <h3 class="text-lg font-medium text-foreground mb-2">
                        {emptyMessage}
                    </h3>
                    <p class="text-muted-foreground mb-4 max-w-sm">
                        {emptyDescription}
                    </p>
                    <slot name="empty-action" />
                </div>
            {/if}
        </div>
    {/if}
</div>