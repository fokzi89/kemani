/**
 * Example usage of the search and filter functionality
 * This file demonstrates how to use the search components and services
 */

import { createSearchService } from '$lib/services/search.js';
import { createSupabase } from '$lib/services/supabase.js';
import { searchActions, getCurrentFilters } from '$lib/stores/search.js';

// Example 1: Basic search setup
export async function exampleBasicSearch() {
    // Create search service
    const supabase = createSupabase(fetch, {});
    const searchService = createSearchService(supabase);
    
    // Perform a basic search
    const results = await searchService.searchProducts('branch-id-123', {
        query: 'laptop',
        limit: 10
    });
    
    console.log('Search Results:', results);
    console.log(`Found ${results.total} products`);
    console.log('Available categories:', results.filters.categories);
    console.log('Price range:', results.filters.priceRange);
    
    return results;
}

// Example 2: Advanced filtering
export async function exampleAdvancedFiltering() {
    const supabase = createSupabase(fetch, {});
    const searchService = createSearchService(supabase);
    
    // Search with multiple filters
    const results = await searchService.searchProducts('branch-id-123', {
        query: 'phone',
        category: 'electronics',
        minPrice: 50000, // ₦50,000
        maxPrice: 200000, // ₦200,000
        sortBy: 'price',
        sortOrder: 'asc',
        limit: 20
    });
    
    console.log('Filtered Results:', results);
    return results;
}

// Example 3: Multi-branch search (Business Plan)
export async function exampleMultiBranchSearch() {
    const supabase = createSupabase(fetch, {});
    const searchService = createSearchService(supabase);
    
    // Search across multiple branches
    const results = await searchService.searchProductsMultiBranch('tenant-id-123', {
        query: 'shoes',
        branchIds: ['branch-1', 'branch-2', 'branch-3'],
        category: 'fashion',
        sortBy: 'relevance',
        limit: 30
    });
    
    console.log('Multi-branch Results:', results);
    return results;
}

// Example 4: Using search store
export function exampleSearchStore() {
    // Set search parameters using the store
    searchActions.setQuery('smartphone');
    searchActions.setCategory('electronics');
    searchActions.setPriceRange(30000, 150000);
    
    // Get current filters
    const filters = getCurrentFilters();
    console.log('Current filters:', filters);
    
    // Clear all filters
    searchActions.clearFilters();
    
    // Toggle filter sidebar
    searchActions.toggleFilterSidebar();
}

// Example 5: Search suggestions
export async function exampleSearchSuggestions() {
    const supabase = createSupabase(fetch, {});
    const searchService = createSearchService(supabase);
    
    // Get search suggestions
    const suggestions = await searchService.getSearchSuggestions('branch-id-123', 'sam');
    
    console.log('Search suggestions:', suggestions);
    // Output: ['Samsung Galaxy', 'Samsung TV', 'Sample Product', ...]
    
    return suggestions;
}

// Example 6: Component usage in Svelte
export const exampleComponentUsage = `
<script>
    import ProductSearch from '$lib/components/ProductSearch.svelte';
    
    let branchId = 'branch-123';
    let tenantId = 'tenant-123';
    let planTier = 'pro';
    let branches = [
        { id: 'branch-1', name: 'Main Store' },
        { id: 'branch-2', name: 'Mall Branch' }
    ];
    
    function handleProductClick(event) {
        const { product } = event.detail;
        console.log('Product clicked:', product);
        // Navigate to product page
    }
    
    function handleUpgradePrompt(event) {
        const { feature } = event.detail;
        console.log('Upgrade needed for:', feature);
        // Show upgrade modal
    }
</script>

<ProductSearch
    {branchId}
    {tenantId}
    {planTier}
    {branches}
    initialQuery="search term"
    on:product-click={handleProductClick}
    on:upgrade-prompt={handleUpgradePrompt}
    on:error={(e) => console.error(e.detail.message)}
/>
`;

// Example 7: Filter sidebar usage
export const exampleFilterSidebarUsage = `
<script>
    import FilterSidebar from '$lib/components/FilterSidebar.svelte';
    
    let categories = ['electronics', 'fashion', 'home'];
    let selectedCategory = null;
    let branches = [
        { id: 'branch-1', name: 'Main Store' },
        { id: 'branch-2', name: 'Mall Branch' }
    ];
    let isOpen = false;
    
    function handleFilter(event) {
        const { category, minPrice, maxPrice, branch } = event.detail;
        console.log('Filters applied:', { category, minPrice, maxPrice, branch });
        // Apply filters to search
    }
</script>

<FilterSidebar
    {categories}
    {selectedCategory}
    minPrice={0}
    maxPrice={100000}
    selectedMinPrice={0}
    selectedMaxPrice={100000}
    {branches}
    selectedBranch={null}
    planTier="pro"
    {isOpen}
    on:filter={handleFilter}
    on:toggle={() => isOpen = !isOpen}
    on:upgrade-prompt={(e) => console.log('Upgrade needed:', e.detail.feature)}
/>
`;

// Example 8: Plan-based feature access
export function examplePlanFeatures() {
    // This would be imported at the top of the file in real usage
    // import { isFeatureEnabled } from '$lib/storefront/plans.js';
    
    const planTier = 'pro';
    
    // Check if multi-branch filtering is available
    // const canFilterByBranch = isFeatureEnabled(planTier, 'multiBranch');
    console.log('Can filter by branch: (check with isFeatureEnabled)');
    
    // Show different UI based on plan
    console.log('Show branch filter options or upgrade prompt based on plan');
}

// Run all examples
export function runSearchExamples() {
    console.log('=== SEARCH EXAMPLES ===');
    
    console.log('\n1. Basic Search:');
    exampleBasicSearch();
    
    console.log('\n2. Advanced Filtering:');
    exampleAdvancedFiltering();
    
    console.log('\n3. Multi-branch Search:');
    exampleMultiBranchSearch();
    
    console.log('\n4. Search Store:');
    exampleSearchStore();
    
    console.log('\n5. Search Suggestions:');
    exampleSearchSuggestions();
    
    console.log('\n6. Plan Features:');
    examplePlanFeatures();
    
    console.log('\n7. Component Usage:');
    console.log(exampleComponentUsage);
    
    console.log('\n8. Filter Sidebar Usage:');
    console.log(exampleFilterSidebarUsage);
}