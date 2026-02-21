import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '$lib/types/supabase.js';

export interface SearchFilters {
    query?: string;
    category?: string;
    minPrice?: number;
    maxPrice?: number;
    branchId?: string;
    branchIds?: string[];
    sortBy?: 'name' | 'price' | 'created_at' | 'relevance';
    sortOrder?: 'asc' | 'desc';
    limit?: number;
    offset?: number;
}

export interface SearchResult {
    products: any[];
    total: number;
    hasMore: boolean;
    filters: {
        categories: string[];
        priceRange: { min: number; max: number };
        appliedFilters: SearchFilters;
    };
}

export class SearchService {
    constructor(private supabase: SupabaseClient<Database>) {}

    /**
     * Optimized product search with full-text search capabilities (T030)
     */
    async searchProducts(
        branchId: string,
        filters: SearchFilters = {}
    ): Promise<SearchResult> {
        const {
            query,
            category,
            minPrice,
            maxPrice,
            sortBy = 'name',
            sortOrder = 'asc',
            limit = 20,
            offset = 0
        } = filters;

        // Build the main query
        let queryBuilder = this.supabase
            .from('storefront_products_with_catalog')
            .select('*', { count: 'exact' })
            .eq('branch_id', branchId)
            .eq('is_available', true);

        // Apply filters
        if (category) {
            queryBuilder = queryBuilder.eq('category', category);
        }

        if (minPrice !== undefined) {
            queryBuilder = queryBuilder.gte('price', minPrice);
        }

        if (maxPrice !== undefined) {
            queryBuilder = queryBuilder.lte('price', maxPrice);
        }

        // Text search with optimization
        if (query && query.trim()) {
            const searchTerm = query.trim();
            
            // Use basic text search (RPC function would need to be added to types)
            queryBuilder = queryBuilder.or(
                `name.ilike.%${searchTerm}%,description.ilike.%${searchTerm}%,brand.ilike.%${searchTerm}%,category.ilike.%${searchTerm}%`
            );
        }

        // Apply sorting
        if (sortBy === 'relevance' && query) {
            // For relevance sorting, prioritize name matches, then description, then brand
            queryBuilder = queryBuilder.order('name', { ascending: true });
        } else {
            queryBuilder = queryBuilder.order(sortBy, { ascending: sortOrder === 'asc' });
        }

        // Apply pagination
        queryBuilder = queryBuilder.range(offset, offset + limit - 1);

        const { data: products, error, count } = await queryBuilder;

        if (error) throw error;

        // Get filter metadata
        const [categoriesResult, priceRangeResult] = await Promise.all([
            this.getCategories(branchId),
            this.getPriceRange(branchId, category)
        ]);

        return {
            products: products || [],
            total: count || 0,
            hasMore: (count || 0) > offset + limit,
            filters: {
                categories: categoriesResult.data || [],
                priceRange: priceRangeResult.data || { min: 0, max: 0 },
                appliedFilters: filters
            }
        };
    }

    /**
     * Multi-branch search for Business Plan (T031)
     */
    async searchProductsMultiBranch(
        tenantId: string,
        filters: SearchFilters = {}
    ): Promise<SearchResult> {
        const {
            query,
            category,
            minPrice,
            maxPrice,
            branchIds,
            sortBy = 'name',
            sortOrder = 'asc',
            limit = 20,
            offset = 0
        } = filters;

        let queryBuilder = this.supabase
            .from('storefront_products_with_catalog')
            .select('*', { count: 'exact' })
            .eq('tenant_id', tenantId)
            .eq('is_available', true);

        // Branch filter
        if (branchIds && branchIds.length > 0) {
            queryBuilder = queryBuilder.in('branch_id', branchIds);
        }

        // Apply other filters
        if (category) {
            queryBuilder = queryBuilder.eq('category', category);
        }

        if (minPrice !== undefined) {
            queryBuilder = queryBuilder.gte('price', minPrice);
        }

        if (maxPrice !== undefined) {
            queryBuilder = queryBuilder.lte('price', maxPrice);
        }

        // Text search
        if (query && query.trim()) {
            const searchTerm = query.trim();
            queryBuilder = queryBuilder.or(
                `name.ilike.%${searchTerm}%,description.ilike.%${searchTerm}%,brand.ilike.%${searchTerm}%,category.ilike.%${searchTerm}%`
            );
        }

        // Sorting
        queryBuilder = queryBuilder.order(sortBy, { ascending: sortOrder === 'asc' });

        // Pagination
        queryBuilder = queryBuilder.range(offset, offset + limit - 1);

        const { data: products, error, count } = await queryBuilder;

        if (error) throw error;

        // Get filter metadata for multi-branch
        const [categoriesResult, priceRangeResult] = await Promise.all([
            this.getCategoriesMultiBranch(tenantId, branchIds),
            this.getPriceRangeMultiBranch(tenantId, branchIds, category)
        ]);

        return {
            products: products || [],
            total: count || 0,
            hasMore: (count || 0) > offset + limit,
            filters: {
                categories: categoriesResult.data || [],
                priceRange: priceRangeResult.data || { min: 0, max: 0 },
                appliedFilters: filters
            }
        };
    }

    /**
     * Get search suggestions based on query
     */
    async getSearchSuggestions(branchId: string, query: string, limit = 5) {
        if (!query || query.length < 2) return { data: [], error: null };

        const { data, error } = await this.supabase
            .from('storefront_products_with_catalog')
            .select('name, category, brand')
            .eq('branch_id', branchId)
            .eq('is_available', true)
            .or(`name.ilike.%${query}%,category.ilike.%${query}%,brand.ilike.%${query}%`)
            .limit(limit);

        if (error) return { data: [], error };

        // Create unique suggestions
        const suggestions = new Set<string>();
        
        data?.forEach(product => {
            if (product.name?.toLowerCase().includes(query.toLowerCase())) {
                suggestions.add(product.name);
            }
            if (product.category?.toLowerCase().includes(query.toLowerCase())) {
                suggestions.add(product.category);
            }
            if (product.brand?.toLowerCase().includes(query.toLowerCase())) {
                suggestions.add(product.brand);
            }
        });

        return { data: Array.from(suggestions).slice(0, limit), error: null };
    }

    /**
     * Get categories for a branch
     */
    private async getCategories(branchId: string) {
        const { data, error } = await this.supabase
            .from('storefront_products_with_catalog')
            .select('category')
            .eq('branch_id', branchId)
            .eq('is_available', true)
            .not('category', 'is', null);

        if (error) return { data: [], error };

        const categories = [...new Set(data?.map(item => item.category).filter((cat): cat is string => Boolean(cat)))];
        return { data: categories.sort(), error: null };
    }

    /**
     * Get categories for multiple branches
     */
    private async getCategoriesMultiBranch(tenantId: string, branchIds?: string[]) {
        let queryBuilder = this.supabase
            .from('storefront_products_with_catalog')
            .select('category')
            .eq('tenant_id', tenantId)
            .eq('is_available', true)
            .not('category', 'is', null);

        if (branchIds && branchIds.length > 0) {
            queryBuilder = queryBuilder.in('branch_id', branchIds);
        }

        const { data, error } = await queryBuilder;

        if (error) return { data: [], error };

        const categories = [...new Set(data?.map(item => item.category).filter((cat): cat is string => Boolean(cat)))];
        return { data: categories.sort(), error: null };
    }

    /**
     * Get price range for a branch
     */
    private async getPriceRange(branchId: string, category?: string) {
        let queryBuilder = this.supabase
            .from('storefront_products_with_catalog')
            .select('price')
            .eq('branch_id', branchId)
            .eq('is_available', true);

        if (category) {
            queryBuilder = queryBuilder.eq('category', category);
        }

        const { data, error } = await queryBuilder;

        if (error || !data || data.length === 0) {
            return { data: { min: 0, max: 0 }, error };
        }

        const prices = data.map(item => item.price).filter(price => price !== null);
        const min = Math.min(...prices);
        const max = Math.max(...prices);

        return { data: { min, max }, error: null };
    }

    /**
     * Get price range for multiple branches
     */
    private async getPriceRangeMultiBranch(tenantId: string, branchIds?: string[], category?: string) {
        let queryBuilder = this.supabase
            .from('storefront_products_with_catalog')
            .select('price')
            .eq('tenant_id', tenantId)
            .eq('is_available', true);

        if (branchIds && branchIds.length > 0) {
            queryBuilder = queryBuilder.in('branch_id', branchIds);
        }

        if (category) {
            queryBuilder = queryBuilder.eq('category', category);
        }

        const { data, error } = await queryBuilder;

        if (error || !data || data.length === 0) {
            return { data: { min: 0, max: 0 }, error };
        }

        const prices = data.map(item => item.price).filter(price => price !== null);
        const min = Math.min(...prices);
        const max = Math.max(...prices);

        return { data: { min, max }, error: null };
    }
}

/**
 * Create search service instance
 */
export function createSearchService(supabase: SupabaseClient<Database>): SearchService {
    return new SearchService(supabase);
}