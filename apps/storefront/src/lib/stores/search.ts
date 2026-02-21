import { writable, derived, get } from 'svelte/store';
import type { SearchFilters, SearchResult } from '$lib/services/search.js';

// Search state
export const searchQuery = writable<string>('');
export const selectedCategory = writable<string | null>(null);
export const priceRange = writable<{ min: number; max: number }>({ min: 0, max: 100000 });
export const selectedBranch = writable<string | null>(null);
export const sortBy = writable<'name' | 'price' | 'created_at' | 'relevance'>('name');
export const sortOrder = writable<'asc' | 'desc'>('asc');

// UI state
export const isFilterSidebarOpen = writable<boolean>(false);
export const isLoading = writable<boolean>(false);

// Search results
export const searchResults = writable<SearchResult | null>(null);
export const availableCategories = writable<string[]>([]);
export const availablePriceRange = writable<{ min: number; max: number }>({ min: 0, max: 100000 });

// Derived stores
export const activeFilters = derived(
    [searchQuery, selectedCategory, priceRange, selectedBranch, availablePriceRange],
    ([$searchQuery, $selectedCategory, $priceRange, $selectedBranch, $availablePriceRange]) => {
        const filters: SearchFilters = {};
        let count = 0;

        if ($searchQuery.trim()) {
            filters.query = $searchQuery.trim();
            count++;
        }

        if ($selectedCategory) {
            filters.category = $selectedCategory;
            count++;
        }

        if ($priceRange.min > $availablePriceRange.min || $priceRange.max < $availablePriceRange.max) {
            filters.minPrice = $priceRange.min;
            filters.maxPrice = $priceRange.max;
            count++;
        }

        if ($selectedBranch) {
            filters.branchId = $selectedBranch;
            count++;
        }

        return { filters, count };
    }
);

export const currentFilters = derived(
    [searchQuery, selectedCategory, priceRange, selectedBranch, sortBy, sortOrder],
    ([$searchQuery, $selectedCategory, $priceRange, $selectedBranch, $sortBy, $sortOrder]) => ({
        query: $searchQuery.trim() || undefined,
        category: $selectedCategory || undefined,
        minPrice: $priceRange.min,
        maxPrice: $priceRange.max,
        branchId: $selectedBranch || undefined,
        sortBy: $sortBy,
        sortOrder: $sortOrder
    })
);

// Actions
export const searchActions = {
    setQuery: (query: string) => {
        searchQuery.set(query);
    },

    setCategory: (category: string | null) => {
        selectedCategory.set(category);
    },

    setPriceRange: (min: number, max: number) => {
        priceRange.set({ min, max });
    },

    setBranch: (branchId: string | null) => {
        selectedBranch.set(branchId);
    },

    setSorting: (by: 'name' | 'price' | 'created_at' | 'relevance', order: 'asc' | 'desc' = 'asc') => {
        sortBy.set(by);
        sortOrder.set(order);
    },

    clearFilters: () => {
        searchQuery.set('');
        selectedCategory.set(null);
        selectedBranch.set(null);
        const availableRange = get(availablePriceRange);
        priceRange.set(availableRange);
    },

    toggleFilterSidebar: () => {
        isFilterSidebarOpen.update(open => !open);
    },

    closeFilterSidebar: () => {
        isFilterSidebarOpen.set(false);
    },

    setLoading: (loading: boolean) => {
        isLoading.set(loading);
    },

    setResults: (results: SearchResult) => {
        searchResults.set(results);
        availableCategories.set(results.filters.categories);
        availablePriceRange.set(results.filters.priceRange);
        
        // Update price range if it's not been manually set
        const currentPriceRange = get(priceRange);
        const availableRange = results.filters.priceRange;
        
        if (currentPriceRange.min === 0 && currentPriceRange.max === 100000) {
            priceRange.set(availableRange);
        }
    },

    reset: () => {
        searchQuery.set('');
        selectedCategory.set(null);
        selectedBranch.set(null);
        priceRange.set({ min: 0, max: 100000 });
        sortBy.set('name');
        sortOrder.set('asc');
        isFilterSidebarOpen.set(false);
        isLoading.set(false);
        searchResults.set(null);
        availableCategories.set([]);
        availablePriceRange.set({ min: 0, max: 100000 });
    }
};

// Utility functions
export function getActiveFiltersCount(): number {
    return get(activeFilters).count;
}

export function getCurrentFilters(): SearchFilters {
    return get(currentFilters);
}

export function hasActiveFilters(): boolean {
    return getActiveFiltersCount() > 0;
}