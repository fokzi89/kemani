<script lang="ts">
    import { createEventDispatcher } from 'svelte';
    import { formatCurrency } from '$lib/storefront/pricing.js';
    import { isFeatureEnabled } from '$lib/storefront/plans.js';
    import type { PlanTier } from '$lib/types/supabase.js';

    const dispatch = createEventDispatcher();

    // Props
    export let categories: string[] = [];
    export let selectedCategory: string | null = null;
    export let minPrice: number = 0;
    export let maxPrice: number = 100000;
    export let selectedMinPrice: number = 0;
    export let selectedMaxPrice: number = 100000;
    export let branches: Array<{ id: string; name: string }> = [];
    export let selectedBranch: string | null = null;
    export let planTier: PlanTier = 'free';
    export let isOpen = false;

    // Local state
    let priceRange = [selectedMinPrice, selectedMaxPrice];

    // Computed
    $: canFilterByBranch = isFeatureEnabled(planTier, 'multiBranch');

    function handleCategoryChange(category: string | null) {
        selectedCategory = category;
        dispatch('filter', {
            category: selectedCategory,
            minPrice: priceRange[0],
            maxPrice: priceRange[1],
            branch: selectedBranch
        });
    }

    function handlePriceChange() {
        selectedMinPrice = priceRange[0];
        selectedMaxPrice = priceRange[1];
        dispatch('filter', {
            category: selectedCategory,
            minPrice: priceRange[0],
            maxPrice: priceRange[1],
            branch: selectedBranch
        });
    }

    function handleBranchChange(branch: string | null) {
        selectedBranch = branch;
        dispatch('filter', {
            category: selectedCategory,
            minPrice: priceRange[0],
            maxPrice: priceRange[1],
            branch: selectedBranch
        });
    }

    function clearFilters() {
        selectedCategory = null;
        selectedBranch = null;
        priceRange = [minPrice, maxPrice];
        selectedMinPrice = minPrice;
        selectedMaxPrice = maxPrice;
        dispatch('filter', {
            category: null,
            minPrice: minPrice,
            maxPrice: maxPrice,
            branch: null
        });
    }

    function toggleSidebar() {
        isOpen = !isOpen;
        dispatch('toggle', { isOpen });
    }
</script>

<!-- Mobile overlay -->
{#if isOpen}
    <div 
        class="fixed inset-0 z-40 bg-black bg-opacity-50 lg:hidden"
        on:click={toggleSidebar}
        on:keydown={(e) => e.key === 'Escape' && toggleSidebar()}
        role="button"
        tabindex="0"
        aria-label="Close filters"
    ></div>
{/if}

<!-- Filter Sidebar -->
<div class="
    fixed inset-y-0 left-0 z-50 w-80 bg-background border-r transform transition-transform duration-300 ease-in-out lg:relative lg:translate-x-0 lg:w-64
    {isOpen ? 'translate-x-0' : '-translate-x-full'}
">
    <!-- Header -->
    <div class="flex items-center justify-between p-4 border-b">
        <h2 class="text-lg font-semibold">Filters</h2>
        <div class="flex items-center gap-2">
            <button
                type="button"
                on:click={clearFilters}
                class="text-sm text-muted-foreground hover:text-foreground"
            >
                Clear all
            </button>
            <button
                type="button"
                on:click={toggleSidebar}
                class="lg:hidden p-1 rounded-md hover:bg-muted"
                aria-label="Close filters"
            >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
            </button>
        </div>
    </div>

    <!-- Filter Content -->
    <div class="p-4 space-y-6 overflow-y-auto h-full pb-20">
        <!-- Categories -->
        {#if categories.length > 0}
            <div class="space-y-3">
                <h3 class="font-medium text-sm text-muted-foreground uppercase tracking-wide">Category</h3>
                <div class="space-y-2">
                    <label class="flex items-center space-x-2 cursor-pointer">
                        <input
                            type="radio"
                            name="category"
                            value=""
                            checked={selectedCategory === null}
                            on:change={() => handleCategoryChange(null)}
                            class="w-4 h-4 text-primary border-gray-300 focus:ring-primary"
                        />
                        <span class="text-sm">All Categories</span>
                    </label>
                    {#each categories as category}
                        <label class="flex items-center space-x-2 cursor-pointer">
                            <input
                                type="radio"
                                name="category"
                                value={category}
                                checked={selectedCategory === category}
                                on:change={() => handleCategoryChange(category)}
                                class="w-4 h-4 text-primary border-gray-300 focus:ring-primary"
                            />
                            <span class="text-sm capitalize">{category}</span>
                        </label>
                    {/each}
                </div>
            </div>
        {/if}

        <!-- Price Range -->
        <div class="space-y-3">
            <h3 class="font-medium text-sm text-muted-foreground uppercase tracking-wide">Price Range</h3>
            <div class="space-y-4">
                <!-- Price inputs -->
                <div class="grid grid-cols-2 gap-2">
                    <div>
                        <label for="min-price" class="block text-xs text-muted-foreground mb-1">Min</label>
                        <input
                            id="min-price"
                            type="number"
                            bind:value={priceRange[0]}
                            on:change={handlePriceChange}
                            min={minPrice}
                            max={priceRange[1]}
                            class="w-full px-2 py-1 text-sm border rounded-md focus:ring-2 focus:ring-primary focus:border-transparent"
                        />
                    </div>
                    <div>
                        <label for="max-price" class="block text-xs text-muted-foreground mb-1">Max</label>
                        <input
                            id="max-price"
                            type="number"
                            bind:value={priceRange[1]}
                            on:change={handlePriceChange}
                            min={priceRange[0]}
                            max={maxPrice}
                            class="w-full px-2 py-1 text-sm border rounded-md focus:ring-2 focus:ring-primary focus:border-transparent"
                        />
                    </div>
                </div>

                <!-- Price range display -->
                <div class="text-sm text-muted-foreground">
                    {formatCurrency(priceRange[0])} - {formatCurrency(priceRange[1])}
                </div>

                <!-- Range slider -->
                <div class="relative">
                    <input
                        type="range"
                        bind:value={priceRange[0]}
                        on:input={handlePriceChange}
                        min={minPrice}
                        max={maxPrice}
                        step="100"
                        class="absolute w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer slider-thumb"
                    />
                    <input
                        type="range"
                        bind:value={priceRange[1]}
                        on:input={handlePriceChange}
                        min={minPrice}
                        max={maxPrice}
                        step="100"
                        class="absolute w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer slider-thumb"
                    />
                </div>
            </div>
        </div>

        <!-- Branch Location (Business Plan only) -->
        {#if canFilterByBranch && branches.length > 1}
            <div class="space-y-3">
                <h3 class="font-medium text-sm text-muted-foreground uppercase tracking-wide">
                    Branch Location
                    <span class="ml-1 px-1.5 py-0.5 text-xs bg-primary text-primary-foreground rounded">PRO</span>
                </h3>
                <div class="space-y-2">
                    <label class="flex items-center space-x-2 cursor-pointer">
                        <input
                            type="radio"
                            name="branch"
                            value=""
                            checked={selectedBranch === null}
                            on:change={() => handleBranchChange(null)}
                            class="w-4 h-4 text-primary border-gray-300 focus:ring-primary"
                        />
                        <span class="text-sm">All Branches</span>
                    </label>
                    {#each branches as branch}
                        <label class="flex items-center space-x-2 cursor-pointer">
                            <input
                                type="radio"
                                name="branch"
                                value={branch.id}
                                checked={selectedBranch === branch.id}
                                on:change={() => handleBranchChange(branch.id)}
                                class="w-4 h-4 text-primary border-gray-300 focus:ring-primary"
                            />
                            <span class="text-sm">{branch.name}</span>
                        </label>
                    {/each}
                </div>
            </div>
        {:else if !canFilterByBranch && branches.length > 1}
            <!-- Upgrade prompt for branch filtering -->
            <div class="space-y-3">
                <h3 class="font-medium text-sm text-muted-foreground uppercase tracking-wide">Branch Location</h3>
                <div class="p-3 bg-muted rounded-lg">
                    <p class="text-sm text-muted-foreground mb-2">
                        Filter by branch location with Pro plan
                    </p>
                    <button
                        type="button"
                        class="text-sm text-primary hover:underline"
                        on:click={() => dispatch('upgrade-prompt', { feature: 'multiBranch' })}
                    >
                        Upgrade to Pro →
                    </button>
                </div>
            </div>
        {/if}
    </div>
</div>

<style>
    /* Custom range slider styles */
    .slider-thumb::-webkit-slider-thumb {
        appearance: none;
        height: 16px;
        width: 16px;
        border-radius: 50%;
        background: hsl(var(--primary));
        cursor: pointer;
        border: 2px solid white;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
    }

    .slider-thumb::-moz-range-thumb {
        height: 16px;
        width: 16px;
        border-radius: 50%;
        background: hsl(var(--primary));
        cursor: pointer;
        border: 2px solid white;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
    }
</style>