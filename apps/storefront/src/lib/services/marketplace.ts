// Marketplace Service
// Feature: 001-multi-tenant-pos (User Story 3)
// Handles public product listings, search, filtering, and storefront generation
// Optimized for direct branch_inventory querying (standalone storefront API)

import type { SupabaseClient } from '@supabase/supabase-js';
import type {
  MarketplaceProduct,
  MarketplaceFilters,
  MarketplaceProductListResponse
} from '../types/ecommerce';

export class MarketplaceService {
  constructor(private supabase: SupabaseClient) {}

  /**
   * Resolves a tenant slug (or UUID) to the valid tenant UUID
   */
  async resolveTenantSlug(identifier: string): Promise<string | null> {
    try {
      // Check if it's already a valid UUID
      const isUUID = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(identifier);
      if (isUUID) return identifier;

      const { data, error } = await this.supabase
        .from('tenants')
        .select('id')
        .eq('slug', identifier)
        .is('deleted_at', null)
        .single();
        
      if (error || !data) return null;
      return data.id;
    } catch (e) {
      return null;
    }
  }

  /**
   * Get marketplace product by ID (unfiltered/clinical context)
   */
  async getMarketplaceProductById(
    productId: string,
    tenantId: string
  ): Promise<{ product?: MarketplaceProduct; error?: string }> {
    try {
      const resolvedTenantId = await this.resolveTenantSlug(tenantId);
      if (!resolvedTenantId) return { error: 'Invalid tenant.' };

      const { data, error } = await this.supabase
        .from('branch_inventory')
        .select(`
          *,
          products (
            generic_name, strength, dosage_form, product_details
          )
        `)
        .eq('product_id', productId)
        .eq('tenant_id', resolvedTenantId)
        .order('stock_quantity', { ascending: false })
        .limit(1)
        .single();

      if (error || !data) return { error: 'Product not found' };

      const finalPrice = (data.sale_price && data.sale_price > 0) ? data.sale_price : data.selling_price;
      
      return {
        product: {
          id: data.product_id,
          inventory_id: data.id,
          tenant_id: data.tenant_id,
          branch_id: data.branch_id,
          name: data.product_name || 'Unnamed Product',
          description: data.product_description || 'Clinically recommended product',
          sku: data.sku || '',
          category: data.product_type || 'General',
          price: finalPrice,
          image_url: data.image_url,
          stock_quantity: (data.stock_quantity || 0) - (data.reserved_quantity || 0),
          isPOM: data.isPOM
        }
      };
    } catch (error: any) {
      return { error: error.message || 'Failed to fetch product context' };
    }
  }

  /**
   * Get tenant's marketplace products (public-facing)
   * Fetches directly from branch_inventory to ensure total independence from other tables
   */
  async getMarketplaceProducts(
    tenantId: string,
    filters?: MarketplaceFilters
  ): Promise<{
    products?: MarketplaceProductListResponse;
    error?: string;
  }> {
    try {
      const resolvedTenantId = await this.resolveTenantSlug(tenantId);
      if (!resolvedTenantId) return { error: 'Invalid tenant identifier or slug.' };

      const page = filters?.page || 1;
      const limit = filters?.limit || 24;
      const offset = (page - 1) * limit;

      // Build pure query on branch_inventory
      let query = this.supabase
        .from('branch_inventory')
        .select('*', { count: 'exact' })
        .eq('tenant_id', resolvedTenantId)
        .eq('isPOM', false)
        .not('is_active', 'is', false)
        .eq('_sync_is_deleted', false);

      // Apply branch filter
      if (filters?.branch_id) {
        query = query.eq('branch_id', filters.branch_id);
      }

      // Apply product-level filters (Using product_type as category)
      if (filters?.category) {
        query = query.eq('product_type', filters.category);
      }

      if (filters?.search) {
        query = query.ilike('product_name', `%${filters.search}%`);
      }

      if (filters?.min_price !== undefined) {
        query = query.gte('selling_price', filters.min_price);
      }

      if (filters?.max_price !== undefined) {
        query = query.lte('selling_price', filters.max_price);
      }

      if (filters?.in_stock_only) {
        query = query.gt('stock_quantity', 0);
      }

      // Apply sorting
      switch (filters?.sort_by) {
        case 'price_asc':
          query = query.order('selling_price', { ascending: true });
          break;
        case 'price_desc':
          query = query.order('selling_price', { ascending: false });
          break;
        case 'name':
          query = query.order('product_name', { ascending: true });
          break;
        default:
          query = query.order('created_at', { ascending: false });
      }

      // Execute query with pagination
      const { data, error, count } = await query.range(offset, offset + limit - 1);

      if (error) {
        return { error: error.message };
      }

      // Transform record mapping directly from branch_inventory
      const products: MarketplaceProduct[] = (data || []).map((item: any) => {
        const availableStock = (item.stock_quantity || 0) - (item.reserved_quantity || 0);
        
        // Effective price is sale_price if set, otherwise selling_price
        const finalPrice = (item.sale_price && item.sale_price > 0) ? item.sale_price : item.selling_price;

        return {
          id: item.product_id, // Link back to master product UUID for other APIs
          inventory_id: item.id, // Primary key of this inventory entry
          tenant_id: item.tenant_id,
          branch_id: item.branch_id,
          name: item.product_name || 'Unnamed Product',
          description: item.product_type || 'General item',
          sku: item.sku || item.batch_no || '', 
          category: item.product_type || 'General',
          price: finalPrice, 
          selling_price: item.selling_price,
          sale_price: item.sale_price,
          percentage_discount: item.percentage_discount,
          image_url: item.image_url,
          stock_quantity: availableStock,
          is_available: availableStock > 0,
          business_name: '' 
        };
      });

      return {
        products: {
          products,
          pagination: {
            page,
            limit,
            total: count || 0,
            pages: Math.ceil((count || 0) / limit)
          }
        }
      };
    } catch (error: any) {
      return { error: error.message || 'Failed to fetch marketplace products' };
    }
  }

  /**
   * Get single marketplace product details directly from inventory
   */
  async getMarketplaceProduct(
    productId: string,
    tenantId: string
  ): Promise<{
    product?: MarketplaceProduct;
    error?: string;
  }> {
    try {
      const resolvedTenantId = await this.resolveTenantSlug(tenantId);
      if (!resolvedTenantId) return { error: 'Invalid tenant identifier or slug.' };

      const { data, error } = await this.supabase
        .from('branch_inventory')
        .select(`
          *,
          products (
            generic_name,
            strength,
            dosage_form,
            "product side effect",
            interactions,
            product_details
          )
        `)
        .eq('product_id', productId)
        .eq('tenant_id', resolvedTenantId)
        .eq('isPOM', false)
        .not('is_active', 'is', false)
        .order('stock_quantity', { ascending: false })
        .limit(1)
        .single();

      if (error || !data) {
        return { error: 'Product not found or out of stock.' };
      }

      const availableStock = (data.stock_quantity || 0) - (data.reserved_quantity || 0);
      const finalPrice = (data.sale_price && data.sale_price > 0) ? data.sale_price : data.selling_price;

      return {
        product: {
          id: data.product_id,
          inventory_id: data.id,
          tenant_id: data.tenant_id,
          branch_id: data.branch_id,
          name: data.product_name || 'Unnamed Product',
          description: data.product_type || 'Verified professional product',
          sku: data.sku || data.batch_no || '',
          category: data.product_type || 'General',
          price: finalPrice,
          selling_price: data.selling_price,
          sale_price: data.sale_price,
          percentage_discount: data.percentage_discount,
          image_url: data.image_url,
          stock_quantity: availableStock,
          is_available: availableStock > 0,
          business_name: '',
          generic_name: data.products?.generic_name,
          strength: data.products?.strength,
          dosage_form: data.products?.dosage_form,
          product_side_effect: data.products?.['product side effect'] || data.products?.product_side_effect,
          interactions: data.products?.interactions,
          product_details: data.products?.product_details
        }
      };
    } catch (error: any) {
      return { error: error.message || 'Failed to fetch product details' };
    }
  }
  /**
   * Get unique categories (product_types) for the storefront sidebar
   */
  async getMarketplaceCategories(tenantId: string): Promise<{
    categories?: Array<{ name: string; count: number }>;
    error?: string;
  }> {
    try {
      const resolvedTenantId = await this.resolveTenantSlug(tenantId);
      if (!resolvedTenantId) return { error: 'Invalid tenant identifier or slug.' };

      // Query unique types from branch_inventory
      const { data, error } = await this.supabase
        .from('branch_inventory')
        .select('product_type')
        .eq('tenant_id', resolvedTenantId)
        .eq('isPOM', false)
        .not('is_active', 'is', false)
        .eq('_sync_is_deleted', false);

      if (error) return { error: error.message };

      // Group and count unique types
      const counts: Record<string, number> = {};
      (data || []).forEach((item: any) => {
        const type = item.product_type || 'General';
        counts[type] = (counts[type] || 0) + 1;
      });

      const categories = Object.keys(counts).map(name => ({
        name,
        count: counts[name]
      }));

      return { categories };
    } catch (error: any) {
      return { error: error.message || 'Failed to fetch categories' };
    }
  }
}
