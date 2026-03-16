// Marketplace Service
// Feature: 001-multi-tenant-pos (User Story 3)
// Handles public product listings, search, filtering, and storefront generation

import type { SupabaseClient } from '@supabase/supabase-js';
import type {
  MarketplaceProduct,
  MarketplaceFilters,
  MarketplaceProductListResponse,
  Product
} from '../types/ecommerce';

export class MarketplaceService {
  constructor(private supabase: SupabaseClient) {}

  /**
   * Get tenant's marketplace products (public-facing)
   */
  async getMarketplaceProducts(
    tenantId: string,
    filters?: MarketplaceFilters
  ): Promise<{
    products?: MarketplaceProductListResponse;
    error?: string;
  }> {
    try {
      const page = filters?.page || 1;
      const limit = filters?.limit || 24;
      const offset = (page - 1) * limit;

      // Build query
      let query = this.supabase
        .from('products')
        .select(`
          id,
          tenant_id,
          branch_id,
          name,
          description,
          sku,
          category,
          price,
          image_url,
          stock_quantity,
          tenants!inner(business_name)
        `, { count: 'exact' })
        .eq('tenant_id', tenantId)
        .eq('is_active', true);

      // Apply filters
      if (filters?.category) {
        query = query.eq('category', filters.category);
      }

      if (filters?.search) {
        query = query.or(
          `name.ilike.%${filters.search}%,description.ilike.%${filters.search}%,sku.ilike.%${filters.search}%`
        );
      }

      if (filters?.min_price !== undefined) {
        query = query.gte('price', filters.min_price);
      }

      if (filters?.max_price !== undefined) {
        query = query.lte('price', filters.max_price);
      }

      if (filters?.in_stock_only) {
        query = query.gt('stock_quantity', 0);
      }

      // Apply sorting
      switch (filters?.sort_by) {
        case 'price_asc':
          query = query.order('price', { ascending: true });
          break;
        case 'price_desc':
          query = query.order('price', { ascending: false });
          break;
        case 'name':
          query = query.order('name', { ascending: true });
          break;
        case 'newest':
          query = query.order('created_at', { ascending: false });
          break;
        default:
          query = query.order('created_at', { ascending: false });
      }

      // Execute query with pagination
      const { data, error, count } = await query.range(offset, offset + limit - 1);

      if (error) {
        return { error: error.message };
      }

      // Transform to marketplace products
      const products: MarketplaceProduct[] = (data || []).map((p: any) => ({
        id: p.id,
        tenant_id: p.tenant_id,
        branch_id: p.branch_id,
        name: p.name,
        description: p.description,
        sku: p.sku,
        category: p.category,
        price: p.price,
        image_url: p.image_url,
        stock_quantity: p.stock_quantity,
        is_available: p.stock_quantity > 0,
        business_name: p.tenants?.business_name
      }));

      const response: MarketplaceProductListResponse = {
        products,
        pagination: {
          page,
          limit,
          total: count || 0,
          pages: Math.ceil((count || 0) / limit)
        }
      };

      return { products: response };
    } catch (error: any) {
      return { error: error.message || 'Failed to fetch marketplace products' };
    }
  }

  /**
   * Get single marketplace product details
   */
  async getMarketplaceProduct(
    productId: string,
    tenantId: string
  ): Promise<{
    product?: MarketplaceProduct;
    error?: string;
  }> {
    try {
      const { data, error } = await this.supabase
        .from('products')
        .select(`
          id,
          tenant_id,
          branch_id,
          name,
          description,
          sku,
          category,
          price,
          image_url,
          stock_quantity,
          tenants!inner(business_name)
        `)
        .eq('id', productId)
        .eq('tenant_id', tenantId)
        .eq('is_active', true)
        .single();

      if (error) {
        return { error: error.message };
      }

      const product: MarketplaceProduct = {
        id: data.id,
        tenant_id: data.tenant_id,
        branch_id: data.branch_id,
        name: data.name,
        description: data.description,
        sku: data.sku,
        category: data.category,
        price: data.price,
        image_url: data.image_url,
        stock_quantity: data.stock_quantity,
        is_available: data.stock_quantity > 0,
        business_name: (data.tenants as any)?.business_name
      };

      return { product };
    } catch (error: any) {
      return { error: error.message || 'Failed to fetch product' };
    }
  }

  /**
   * Get marketplace categories for a tenant
   */
  async getMarketplaceCategories(tenantId: string): Promise<{
    categories: Array<{ name: string; count: number }>;
    error?: string;
  }> {
    try {
      const { data, error } = await this.supabase
        .from('products')
        .select('category')
        .eq('tenant_id', tenantId)
        .eq('is_active', true)
        .not('category', 'is', null);

      if (error) {
        return { categories: [], error: error.message };
      }

      // Count products per category
      const categoryCounts: Record<string, number> = {};
      data.forEach((item: any) => {
        const category = item.category;
        categoryCounts[category] = (categoryCounts[category] || 0) + 1;
      });

      const categories = Object.entries(categoryCounts)
        .map(([name, count]) => ({ name, count }))
        .sort((a, b) => b.count - a.count);

      return { categories };
    } catch (error: any) {
      return { categories: [], error: error.message || 'Failed to fetch categories' };
    }
  }

  /**
   * Get tenant storefront information
   */
  async getStorefrontInfo(tenantId: string): Promise<{
    storefront?: {
      tenant_id: string;
      business_name: string;
      description?: string;
      logo_url?: string;
      primary_color?: string;
      is_accepting_orders: boolean;
      branches: Array<{
        id: string;
        name: string;
        address?: string;
      }>;
    };
    error?: string;
  }> {
    try {
      const { data: tenant, error: tenantError } = await this.supabase
        .from('tenants')
        .select(`
          id,
          business_name,
          business_description,
          logo_url,
          primary_color,
          branches!inner(id, name, address)
        `)
        .eq('id', tenantId)
        .eq('is_active', true)
        .single();

      if (tenantError) {
        return { error: tenantError.message };
      }

      const storefront = {
        tenant_id: tenant.id,
        business_name: tenant.business_name,
        description: tenant.business_description,
        logo_url: tenant.logo_url,
        primary_color: tenant.primary_color,
        is_accepting_orders: true, // TODO: Add this field to tenants table
        branches: (tenant.branches as any[]).map(b => ({
          id: b.id,
          name: b.name,
          address: b.address
        }))
      };

      return { storefront };
    } catch (error: any) {
      return { error: error.message || 'Failed to fetch storefront information' };
    }
  }

  /**
   * Search products across all categories
   */
  async searchProducts(
    tenantId: string,
    searchQuery: string,
    limit = 20
  ): Promise<{
    products: MarketplaceProduct[];
    error?: string;
  }> {
    try {
      const { data, error } = await this.supabase
        .from('products')
        .select(`
          id,
          tenant_id,
          branch_id,
          name,
          description,
          sku,
          category,
          price,
          image_url,
          stock_quantity,
          tenants!inner(business_name)
        `)
        .eq('tenant_id', tenantId)
        .eq('is_active', true)
        .or(
          `name.ilike.%${searchQuery}%,description.ilike.%${searchQuery}%,sku.ilike.%${searchQuery}%,category.ilike.%${searchQuery}%`
        )
        .limit(limit);

      if (error) {
        return { products: [], error: error.message };
      }

      const products: MarketplaceProduct[] = (data || []).map((p: any) => ({
        id: p.id,
        tenant_id: p.tenant_id,
        branch_id: p.branch_id,
        name: p.name,
        description: p.description,
        sku: p.sku,
        category: p.category,
        price: p.price,
        image_url: p.image_url,
        stock_quantity: p.stock_quantity,
        is_available: p.stock_quantity > 0,
        business_name: p.tenants?.business_name
      }));

      return { products };
    } catch (error: any) {
      return { products: [], error: error.message || 'Failed to search products' };
    }
  }

  /**
   * Get featured/trending products
   */
  async getFeaturedProducts(
    tenantId: string,
    limit = 12
  ): Promise<{
    products: MarketplaceProduct[];
    error?: string;
  }> {
    try {
      // TODO: Implement proper featured logic based on sales, ratings, etc.
      // For now, just return newest products
      const { data, error } = await this.supabase
        .from('products')
        .select(`
          id,
          tenant_id,
          branch_id,
          name,
          description,
          sku,
          category,
          price,
          image_url,
          stock_quantity,
          tenants!inner(business_name)
        `)
        .eq('tenant_id', tenantId)
        .eq('is_active', true)
        .gt('stock_quantity', 0)
        .order('created_at', { ascending: false })
        .limit(limit);

      if (error) {
        return { products: [], error: error.message };
      }

      const products: MarketplaceProduct[] = (data || []).map((p: any) => ({
        id: p.id,
        tenant_id: p.tenant_id,
        branch_id: p.branch_id,
        name: p.name,
        description: p.description,
        sku: p.sku,
        category: p.category,
        price: p.price,
        image_url: p.image_url,
        stock_quantity: p.stock_quantity,
        is_available: p.stock_quantity > 0,
        business_name: p.tenants?.business_name
      }));

      return { products };
    } catch (error: any) {
      return { products: [], error: error.message || 'Failed to fetch featured products' };
    }
  }

  /**
   * Get related products (same category)
   */
  async getRelatedProducts(
    productId: string,
    tenantId: string,
    limit = 6
  ): Promise<{
    products: MarketplaceProduct[];
    error?: string;
  }> {
    try {
      // First get the product's category
      const { data: product } = await this.supabase
        .from('products')
        .select('category')
        .eq('id', productId)
        .single();

      if (!product || !product.category) {
        return { products: [] };
      }

      // Get related products in same category
      const { data, error } = await this.supabase
        .from('products')
        .select(`
          id,
          tenant_id,
          branch_id,
          name,
          description,
          sku,
          category,
          price,
          image_url,
          stock_quantity,
          tenants!inner(business_name)
        `)
        .eq('tenant_id', tenantId)
        .eq('category', product.category)
        .eq('is_active', true)
        .neq('id', productId)
        .gt('stock_quantity', 0)
        .limit(limit);

      if (error) {
        return { products: [], error: error.message };
      }

      const products: MarketplaceProduct[] = (data || []).map((p: any) => ({
        id: p.id,
        tenant_id: p.tenant_id,
        branch_id: p.branch_id,
        name: p.name,
        description: p.description,
        sku: p.sku,
        category: p.category,
        price: p.price,
        image_url: p.image_url,
        stock_quantity: p.stock_quantity,
        is_available: p.stock_quantity > 0,
        business_name: p.tenants?.business_name
      }));

      return { products };
    } catch (error: any) {
      return { products: [], error: error.message || 'Failed to fetch related products' };
    }
  }
}
