<script lang="ts">
    import { createEventDispatcher } from 'svelte';
    import ProductCard from './ProductCard.svelte';
    import { cn } from '$lib/utils.js';
    import type { StorefrontProductWithCatalog } from '$lib/types/supabase.js';

    const dispatch = createEventDispatcher();

    export let products: StorefrontProductWithCatalog[] = [];
    export let loading = false;
    export let columns: 1 | 2 | 3 | 4 | 5 | 6 = 4;
    export let gap: 'sm' | 'md' | 'lg' = 'md';
    export let cardSize: 'sm' | 'md' | 'lg' = 'md';
    export let showAddToCart = true;
    export let showStock = false;
    export let showBrand = true;
    export let showCategory = false;
    export let imageAspectRatio: 'square' | 'portrait' | 'landscape' = 'square';
    export let emptyMessage = 'No products found';
    export let emptyDescription = 'Try adjusting your search or filters';
    export let className: string | undefined = undefined;

    // Grid configuration
    $: gridClasses = {
        1: 'grid-cols-1',
        2: 'grid-cols-1 sm:grid-cols-2',
        3: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3',
        4: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4',
        5: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5',
        6: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-6'
    };

    $: gapClasses = {
        sm: 'gap-2',
        md: 'gap-4',
        lg: 'gap-6'
    };

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

<div class={cn("w-full", className)}>
    {#if loading}
        <!-- Loading Skeleton -->
        <div class={cn(
            "grid",
            gridClasses[columns],
            gapClasses[gap]
        )}>
            {#each Array(columns * 2) as _}
                <div class="bg-muted animate-pulse rounded-lg">
                    <div class={cn(
                        "w-full bg-muted-foreground/10 rounded-t-lg",
                        imageAspectRatio === 'square' ? 'aspect-square' : 
                        imageAspectRatio === 'portrait' ? 'aspect-[3/4]' : 'aspect-[4/3]'
                    )}></div>
                    <div class="p-3 space-y-2">
                        <div class="h-4 bg-muted-foreground/10 rounded"></div>
                        <div class="h-3 bg-muted-foreground/10 rounded w-2/3"></div>
                        <div class="flex justify-between items-end pt-2">
                            <div class="h-5 bg-muted-foreground/10 rounded w-16"></div>
                            <div class="h-8 w-8 bg-muted-foreground/10 rounded"></div>
                        </div>
                    </div>
                </div>
            {/each}
        </div>
    {:else if products.length > 0}
        <!-- Products Grid -->
        <div class={cn(
            "grid",
            gridClasses[columns],
            gapClasses[gap]
        )}>
            {#each products as product (product.id)}
                <ProductCard
                    {product}
                    size={cardSize}
                    {showAddToCart}
                    {showStock}
                    {showBrand}
                    {showCategory}
                    {imageAspectRatio}
                    on:click={handleProductClick}
                    on:add-to-cart={handleAddToCart}
                    on:quick-view={handleQuickView}
                />
            {/each}
        </div>
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