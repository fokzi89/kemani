<script lang="ts">
    import { onMount, createEventDispatcher } from 'svelte';
    import { page } from '$app/stores';
    import SearchBar from './SearchBar.svelte';
    import FilterSidebar from './FilterSidebar.svelte';
    import FilterButton from './FilterButton.svelte';
    import ProductList from './ProductList.svelte';
    import { createSearchService } from '$lib/services/search.js';
    import { createSupabase } from '$lib/services/supabase.js';
    import { isFeatureEnabled } from '$lib/storefront/plans.js';
    import {
        searchActions,
        searchQuery,
        selectedCategory,
        priceRange,
        selectedBranch,
        sortBy,
        sortOrder,
        isFilterSidebarOpen,
        isLoading,
        searchResults,
        availableCategories,
        availablePriceRange,
        activeFilters,
        currentFilters
    } from '$lib/stores/search.js';
    import type { PlanTier } from '$lib/types/supabase.js';

    const dispatch = createEventDispatcher();

    // Props
    export let branchId: string;
    export let tenantId: string;
    export let planTier: PlanTier = 'free';
    export let branches: Array<{ id: string; name: string }> = [];
    export let initialQuery = '';
    export let showAddToCart = true;

    // Local state
    let searchService: ReturnType<typeof createSearchService>;
    let currentPage = 0;
    let hasMore = true;
    let loadingMore = false;

    // Reactive statements
    $: canFilterByBranch = isFeatureEnabled(planTier, 'multiBranch');
    $: products = $searchResults?.products || [];
    $: totalResults = $searchResults?.total || 0;

    onMount(async () => {
        // Initialize search service
        const supabase = createSupabase(fetch, {});
        searchService = createSearchService(supabase);

        // Set initial query from URL or prop
        const urlQuery = $page.url.searchParams.get('q') || initialQuery;
        if (urlQuery) {
            searchActions.setQuery(urlQuery);
        }

        // Load initial results
        await performSearch();
    });

    async function performSearch(loadMore = false) {
        if (!searchService) return;

        try {
            if (!loadMore) {
                searchActions.setLoading(true);
                currentPage = 0;
            } else {
                loadingMore = true;
            }

            const filters = {
                ...$currentFilters,
                limit: 20,
                offset: loadMore ? currentPage * 20 : 0
            };

            let result;
            
            if (canFilterByBranch && $selectedBranch) {
                // Use multi-branch search for Business plan
                result = await searchService.searchProductsMultiBranch(tenantId, {
                    ...filters,
                    branchIds: [$selectedBranch]
                });
            } else if (canFilterByBranch && branches.length > 1) {
                // Search across all branches for Business plan
                result = await searchService.searchProductsMultiBranch(tenantId, filters);
            } else {
                // Single branch search
                result = await searchService.searchProducts(branchId, filters);
            }

            if (loadMore && $searchResults) {
                // Append to existing results
                result.products = [...$searchResults.products, ...result.products];
            }

            searchActions.setResults(result);
            hasMore = result.hasMore;
            
            if (loadMore) {
                currentPage++;
            }

            // Update URL with search query
            if ($searchQuery && !loadMore) {
                const url = new URL(window.location.href);
                url.searchParams.set('q', $searchQuery);
                window.history.replaceState({}, '', url.toString());
            }

        } catch (error) {
            console.error('Search failed:', error);
            dispatch('error', { message: 'Search failed. Please try again.' });
        } finally {
            searchActions.setLoading(false);
            loadingMore = false;
        }
    }

    async function loadMore() {
        if (!hasMore || loadingMore) return;
        await performSearch(true);
    }

    function handleSearch(event: CustomEvent<{ query: string }>) {
        searchActions.setQuery(event.detail.query);
        performSearch();
    }

    function handleFilter(event: CustomEvent) {
        const { category, minPrice, maxPrice, branch } = event.detail;
        
        searchActions.setCategory(category);
        searchActions.setPriceRange(minPrice, maxPrice);
        
        if (canFilterByBranch) {
            searchActions.setBranch(branch);
        }
        
        performSearch();
    }

    function handleSort(newSortBy: typeof $sortBy, newSortOrder: typeof $sortOrder = 'asc') {
        searchActions.setSorting(newSortBy, newSortOrder);
        performSearch();
    }

    function handleClearFilters() {
        searchActions.clearFilters();
        performSearch();
    }

    function handleToggleFilters() {
        searchActions.toggleFilterSidebar();
    }

    function handleUpgradePrompt(event: CustomEvent<{ feature: string }>) {
        dispatch('upgrade-prompt', event.detail);
    }

    function handleProductClick(product: any) {
        dispatch('product-click', { product });
    }

    // Reactive search when filters change
    $: if (searchService) {
        // Debounce search when query changes
        const timeoutId = setTimeout(() => {
            if ($searchQuery !== ($searchResults?.filters.appliedFilters.query || '')) {
                performSearch();
            }
        }, 300);

        return () => clearTimeout(timeoutId);
    }
</script>

<div class="flex h-full">
    <!-- Filter Sidebar -->
    <FilterSidebar
        categories={$availableCategories}
        selectedCategory={$selectedCategory}
        minPrice={$availablePriceRange.min}
        maxPrice={$availablePriceRange.max}
        selectedMinPrice={$priceRange.min}
        selectedMaxPrice={$priceRange.max}
        {branches}
        selectedBranch={$selectedBranch}
        {planTier}
        isOpen={$isFilterSidebarOpen}
        on:filter={handleFilter}
        on:toggle={handleToggleFilters}
        on:upgrade-prompt={handleUpgradePrompt}
    />

    <!-- Main Content -->
    <div class="flex-1 flex flex-col min-w-0">
        <!-- Search Header -->
        <div class="bg-background border-b p-4 space-y-4">
            <!-- Search Bar and Filter Button -->
            <div class="flex gap-3">
                <div class="flex-1">
                    <SearchBar
                        value={$searchQuery}
                        placeholder="Search products, brands, categories..."
                        disabled={$isLoading}
                        on:search={handleSearch}
                    />
                </div>
                <FilterButton
                    activeFiltersCount={$activeFilters.count}
                    on:toggle={handleToggleFilters}
                />
            </div>

            <!-- Results Summary and Sort -->
            <div class="flex items-center justify-between">
                <div class="text-sm text-muted-foreground">
                    {#if $isLoading}
                        Searching...
                    {:else if totalResults > 0}
                        {totalResults} product{totalResults !== 1 ? 's' : ''} found
                        {#if $searchQuery}
                            for "{$searchQuery}"
                        {/if}
                    {:else if $searchQuery || $activeFilters.count > 0}
                        No products found
                    {:else}
                        All products
                    {/if}
                </div>

                <!-- Sort Options -->
                <div class="flex items-center gap-2">
                    <span class="text-sm text-muted-foreground">Sort by:</span>
                    <select
                        value={`${$sortBy}-${$sortOrder}`}
                        on:change={(e) => {
                            const [by, order] = e.currentTarget.value.split('-');
                            handleSort(by as typeof $sortBy, order as typeof $sortOrder);
                        }}
                        class="text-sm border rounded px-2 py-1 focus:ring-2 focus:ring-primary focus:border-transparent"
                    >
                        <option value="name-asc">Name (A-Z)</option>
                        <option value="name-desc">Name (Z-A)</option>
                        <option value="price-asc">Price (Low to High)</option>
                        <option value="price-desc">Price (High to Low)</option>
                        <option value="created_at-desc">Newest First</option>
                        {#if $searchQuery}
                            <option value="relevance-desc">Relevance</option>
                        {/if}
                    </select>
                </div>
            </div>

            <!-- Active Filters -->
            {#if $activeFilters.count > 0}
                <div class="flex flex-wrap gap-2">
                    {#if $searchQuery}
                        <span class="inline-flex items-center gap-1 px-2 py-1 bg-primary text-primary-foreground text-xs rounded-full">
                            Search: "{$searchQuery}"
                            <button
                                type="button"
                                on:click={() => {
                                    searchActions.setQuery('');
                                    performSearch();
                                }}
                                class="hover:bg-primary-foreground hover:text-primary rounded-full p-0.5"
                            >
                                <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                                </svg>
                            </button>
                        </span>
                    {/if}

                    {#if $selectedCategory}
                        <span class="inline-flex items-center gap-1 px-2 py-1 bg-secondary text-secondary-foreground text-xs rounded-full">
                            Category: {$selectedCategory}
                            <button
                                type="button"
                                on:click={() => {
                                    searchActions.setCategory(null);
                                    performSearch();
                                }}
                                class="hover:bg-secondary-foreground hover:text-secondary rounded-full p-0.5"
                            >
                                <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                                </svg>
                            </button>
                        </span>
                    {/if}

                    <button
                        type="button"
                        on:click={handleClearFilters}
                        class="text-xs text-muted-foreground hover:text-foreground underline"
                    >
                        Clear all filters
                    </button>
                </div>
            {/if}
        </div>

        <!-- Products Grid -->
        <div class="flex-1 p-4 overflow-y-auto">
            <ProductList
                products={products}
                loading={$isLoading && products.length === 0}
                viewMode="grid"
                gridColumns={4}
                {showAddToCart}
                showStock={false}
                showBrand={true}
                showCategory={false}
                emptyMessage={$searchQuery || $activeFilters.count > 0 ? "No products found" : "No products available"}
                emptyDescription={$searchQuery || $activeFilters.count > 0 ? "Try adjusting your search or filters" : "No products are currently available"}
                on:product-click={handleProductClick}
                on:add-to-cart={(e) => dispatch('add-to-cart', e.detail)}
                on:quick-view={(e) => dispatch('quick-view', e.detail)}
            >
                <div slot="empty-action">
                    {#if $activeFilters.count > 0}
                        <button
                            type="button"
                            on:click={handleClearFilters}
                            class="text-primary hover:underline"
                        >
                            Clear all filters
                        </button>
                    {/if}
                </div>
            </ProductList>

            <!-- Load More Button -->
            {#if hasMore && products.length > 0}
                <div class="flex justify-center mt-8">
                    <button
                        type="button"
                        on:click={loadMore}
                        disabled={loadingMore}
                        class="px-6 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        {loadingMore ? 'Loading...' : 'Load More'}
                    </button>
                </div>
            {/if}
        </div>
    </div>
</div>