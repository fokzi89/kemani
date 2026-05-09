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
          stock_quantity: data.stock_quantity || 0,
          isPOM: data.isPOM,
          is_on_sale: data.is_on_sale,
          is_featured: data.is_featured,
          is_new_arrival: data.is_new_arrival,
          is_new_arrival: data.is_new_arrival
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

      // Build query on ecommerce_products view for aggregated batch data
      let query = this.supabase
        .from('ecommerce_products')
        .select('*', { count: 'exact' })
        .eq('tenant_id', resolvedTenantId)
        .eq('is_pom', false);

      // Apply branch filter (The view provides a branches JSON array)
      // Note: If filtering by branch, we still use the view but check availability in the branch list
      // For simplicity in this list view, we filter where the product is available in the tenant
      
      // Apply product-level filters
      if (filters?.category) {
        query = query.eq('category', filters.category);
      }

      if (filters?.search) {
        query = query.ilike('name', `%${filters.search}%`);
      }

      if (filters?.min_price !== undefined) {
        query = query.gte('selling_price', filters.min_price);
      }

      if (filters?.max_price !== undefined) {
        query = query.lte('selling_price', filters.max_price);
      }

      if (filters?.in_stock_only) {
        query = query.gt('total_stock', 0);
      }

      if (filters?.is_on_sale) {
        query = query.eq('is_on_sale', true);
      }

      if (filters?.is_featured) {
        query = query.eq('is_featured', true);
      }

      if (filters?.is_new_arrival) {
        query = query.eq('is_new_arrival', true);
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
          query = query.order('name', { ascending: true });
          break;
        default:
          query = query.order('created_at', { ascending: false });
      }

      // Execute query with pagination
      const { data, error, count } = await query.range(offset, offset + limit - 1);

      if (error) {
        return { error: error.message };
      }

      // Transform record mapping from branch-aggregated view
      const products: MarketplaceProduct[] = (data || []).map((item: any) => {
        const finalPrice = (item.sale_price && item.sale_price > 0) ? item.sale_price : item.selling_price;
        return {
          id: item.product_id, // The actual product ID
          view_id: item.id,    // Unique composite ID (product-branch)
          tenant_id: item.tenant_id,
          branch_id: item.branch_id,
          branch_name: item.branch_name,
          name: item.name || 'Unnamed Product',
          description: item.description || 'Verified product',
          sku: item.product_id.split('-')[0],
          category: item.category || 'General',
          price: finalPrice,
          selling_price: item.selling_price,
          sale_price: item.sale_price,
          image_url: item.image_url,
          stock_quantity: item.total_stock,
          is_available: item.total_stock > 0 || item.allow_preorder === true,
          allow_preorder: item.allow_preorder,
          preorder_quantity: item.preorder_quantity,
          preorder_limit: item.preorder_limit,
          is_on_sale: item.is_on_sale,
          is_featured: item.is_featured,
          is_new_arrival: item.is_new_arrival,
          isPOM: item.is_pom,
          generic_name: item.generic_name,
          business_name: item.branch_name // Use branch name as business name
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
   * Get single marketplace product details from the branch-aggregated view
   */
  async getMarketplaceProduct(
    productId: string,
    tenantId: string,
    branchId?: string // Optional branch filter
  ): Promise<{
    product?: MarketplaceProduct;
    error?: string;
  }> {
    try {
      const resolvedTenantId = await this.resolveTenantSlug(tenantId);
      if (!resolvedTenantId) return { error: 'Invalid tenant identifier or slug.' };

      let query = this.supabase
        .from('ecommerce_products')
        .select('*')
        .eq('product_id', productId)
        .eq('tenant_id', resolvedTenantId)
        .eq('is_pom', false);

      if (branchId) {
        query = query.eq('branch_id', branchId);
      }

      const { data, error } = await query
        .order('total_stock', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (error || !data) {
        return { error: 'Product not found in this location.' };
      }

      const finalPrice = (data.sale_price && data.sale_price > 0) ? data.sale_price : data.selling_price;

      return {
        product: {
          id: data.product_id,
          tenant_id: data.tenant_id,
          branch_id: data.branch_id,
          branch_name: data.branch_name,
          name: data.name || 'Unnamed Product',
          description: data.description || 'Verified professional product',
          sku: data.product_id.split('-')[0],
          category: data.category || 'General',
          price: finalPrice,
          selling_price: data.selling_price,
          sale_price: data.sale_price,
          image_url: data.image_url,
          stock_quantity: data.total_stock,
          is_available: data.total_stock > 0 || data.allow_preorder === true,
          allow_preorder: data.allow_preorder,
          preorder_quantity: data.preorder_quantity,
          preorder_limit: data.preorder_limit,
          business_name: data.branch_name,
          generic_name: data.generic_name,
          strength: data.strength,
          dosage_form: data.dosage_form,
          product_details: data.description,
          is_on_sale: data.is_on_sale,
          is_featured: data.is_featured,
          is_new_arrival: data.is_new_arrival
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

      // Query unique categories from aggregated view
      const { data, error } = await this.supabase
        .from('ecommerce_products')
        .select('category')
        .eq('tenant_id', resolvedTenantId)
        .eq('is_pom', false);

      if (error) return { error: error.message };

      // Group and count unique categories
      const counts: Record<string, number> = {};
      (data || []).forEach((item: any) => {
        const cat = item.category || 'General';
        counts[cat] = (counts[cat] || 0) + 1;
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


  // Note: Promotional Table Management (Featured/Sale) has been consolidated 
  // directly into the branch_inventory table via boolean flags and the sale_price column.
  // Use branch_inventory.update() to manage these statuses.
}
