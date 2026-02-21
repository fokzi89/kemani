<script lang="ts">
    import { createEventDispatcher } from 'svelte';
    import { cn } from "$lib/utils.js";
    import { formatCurrency } from "$lib/storefront/pricing.js";
    import type { StorefrontProductWithCatalog } from "$lib/types/supabase.js";

    const dispatch = createEventDispatcher();

    export let product: StorefrontProductWithCatalog;
    export let className: string | undefined = undefined;
    export let showAddToCart = true;
    export let showStock = false;
    export let showBrand = true;
    export let showCategory = false;
    export let imageAspectRatio: 'square' | 'portrait' | 'landscape' = 'square';
    export let size: 'sm' | 'md' | 'lg' = 'md';

    // Computed properties
    $: name = product.name || "Unnamed Product";
    $: description = product.description;
    $: brand = product.brand;
    $: category = product.category;
    $: primaryImage = product.primary_image || product.images?.[0] || "https://via.placeholder.com/300x300?text=No+Image";
    $: price = product.price || 0;
    $: compareAtPrice = product.compare_at_price;
    $: stockQuantity = product.stock_quantity || 0;
    $: isAvailable = product.is_available && stockQuantity > 0;
    $: isLowStock = stockQuantity <= (product.low_stock_threshold || 10) && stockQuantity > 0;
    $: hasDiscount = compareAtPrice != null && compareAtPrice > price;
    $: discountPercentage = hasDiscount ? Math.round(((compareAtPrice! - price) / compareAtPrice!) * 100) : 0;
    $: hasVariants = product.has_variants;

    // Styling based on size
    $: sizeClasses = {
        sm: 'text-xs',
        md: 'text-sm md:text-base',
        lg: 'text-base md:text-lg'
    };

    $: aspectRatioClasses = {
        square: 'aspect-square',
        portrait: 'aspect-[3/4]',
        landscape: 'aspect-[4/3]'
    };

    function handleClick() {
        dispatch('click', { product });
    }

    function handleAddToCart(e: Event) {
        e.preventDefault();
        e.stopPropagation();
        
        if (!isAvailable) return;
        
        dispatch('add-to-cart', { 
            product,
            quantity: 1,
            variantId: null 
        });
    }

    function handleQuickView(e: Event) {
        e.preventDefault();
        e.stopPropagation();
        dispatch('quick-view', { product });
    }

    function handleImageError(e: Event) {
        const img = e.target as HTMLImageElement;
        img.src = "https://via.placeholder.com/300x300?text=No+Image";
    }
</script>

<div
    class={cn(
        "group relative flex h-full flex-col overflow-hidden rounded-lg border bg-card text-card-foreground shadow-sm transition-all hover:shadow-md cursor-pointer",
        !isAvailable && "opacity-60",
        className,
    )}
    on:click={handleClick}
    on:keydown={(e) => e.key === 'Enter' && handleClick()}
    role="button"
    tabindex="0"
    aria-label={`View ${name}`}
>
    <!-- Image Container -->
    <div class={cn(
        "relative w-full overflow-hidden bg-muted",
        aspectRatioClasses[imageAspectRatio]
    )}>
        <img
            src={primaryImage}
            alt={name}
            loading="lazy"
            class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
            on:error={handleImageError}
        />
        
        <!-- Badges -->
        <div class="absolute top-2 left-2 flex flex-col gap-1">
            {#if hasDiscount}
                <span class="inline-flex items-center rounded-full bg-red-500 px-2 py-1 text-xs font-medium text-white">
                    -{discountPercentage}%
                </span>
            {/if}
            
            {#if !isAvailable}
                <span class="inline-flex items-center rounded-full bg-gray-500 px-2 py-1 text-xs font-medium text-white">
                    Out of Stock
                </span>
            {:else if isLowStock}
                <span class="inline-flex items-center rounded-full bg-orange-500 px-2 py-1 text-xs font-medium text-white">
                    Low Stock
                </span>
            {/if}
            
            {#if hasVariants}
                <span class="inline-flex items-center rounded-full bg-blue-500 px-2 py-1 text-xs font-medium text-white">
                    Variants
                </span>
            {/if}
        </div>

        <!-- Quick Actions -->
        <div class="absolute top-2 right-2 flex flex-col gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
            <button
                type="button"
                on:click={handleQuickView}
                class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-white/90 text-gray-700 shadow-sm hover:bg-white focus:outline-none focus:ring-2 focus:ring-primary"
                aria-label="Quick view"
                title="Quick view"
            >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
            </button>
        </div>
    </div>

    <!-- Content -->
    <div class="flex flex-1 flex-col p-3 space-y-2">
        <!-- Category & Brand -->
        {#if showCategory && category}
            <span class="text-xs text-muted-foreground uppercase tracking-wide">
                {category}
            </span>
        {/if}

        <!-- Product Name -->
        <h3
            class={cn(
                "line-clamp-2 font-medium leading-tight group-hover:text-primary transition-colors",
                sizeClasses[size]
            )}
            title={name}
        >
            {name}
        </h3>

        <!-- Brand -->
        {#if showBrand && brand}
            <p class="text-xs text-muted-foreground">
                by {brand}
            </p>
        {/if}

        <!-- Description (for larger sizes) -->
        {#if description && size === 'lg'}
            <p class="text-xs text-muted-foreground line-clamp-2">
                {description}
            </p>
        {/if}

        <!-- Stock Info -->
        {#if showStock}
            <div class="text-xs text-muted-foreground">
                {#if stockQuantity > 0}
                    {stockQuantity} in stock
                {:else}
                    Out of stock
                {/if}
            </div>
        {/if}

        <!-- Price and Actions -->
        <div class="mt-auto flex items-end justify-between gap-2 pt-2">
            <div class="flex flex-col">
                {#if hasDiscount}
                    <span class="text-xs text-muted-foreground line-through">
                        {formatCurrency(compareAtPrice ?? 0)}
                    </span>
                {/if}
                <span class={cn(
                    "font-bold text-primary",
                    size === 'sm' ? 'text-sm' : size === 'lg' ? 'text-xl' : 'text-lg'
                )}>
                    {formatCurrency(price)}
                </span>
            </div>

            {#if showAddToCart}
                <button
                    type="button"
                    on:click={handleAddToCart}
                    disabled={!isAvailable}
                    class={cn(
                        "inline-flex items-center justify-center rounded-md bg-primary text-primary-foreground shadow transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50",
                        size === 'sm' ? 'h-7 w-7' : size === 'lg' ? 'h-10 w-10' : 'h-8 w-8'
                    )}
                    aria-label="Add to cart"
                    title={isAvailable ? "Add to cart" : "Out of stock"}
                >
                    {#if isAvailable}
                        <!-- Plus Icon -->
                        <svg
                            class={cn(size === 'sm' ? 'w-3 h-3' : size === 'lg' ? 'w-5 h-5' : 'w-4 h-4')}
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                        </svg>
                    {:else}
                        <!-- X Icon -->
                        <svg
                            class={cn(size === 'sm' ? 'w-3 h-3' : size === 'lg' ? 'w-5 h-5' : 'w-4 h-4')}
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    {/if}
                </button>
            {/if}
        </div>
    </div>
</div>
