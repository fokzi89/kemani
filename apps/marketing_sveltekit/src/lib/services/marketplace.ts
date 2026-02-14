import { supabase } from './supabase';
import type { Product, StoreDetails } from '$lib/types';

export class MarketplaceService {
  /**
   * Get tenant ID by slug (for user-friendly URLs)
   */
  static async getTenantIdBySlug(slug: string): Promise<string> {
    const { data, error } = await supabase
      .from('tenants')
      .select('id')
      .eq('slug', slug)
      .single();

    if (error) throw new Error('Store not found');
    return data.id;
  }

  /**
   * Get storefront details (tenant info with marketplace settings)
   */
  static async getStorefrontDetails(tenantId: string): Promise<StoreDetails> {
    const { data, error } = await supabase
      .from('tenants')
      .select('id, name, slug, settings')
      .eq('id', tenantId)
      .single();

    if (error) throw new Error('Store not found');
    return data;
  }

  /**
   * Get all published products for a storefront
   */
  static async getStorefrontProducts(
    tenantId: string,
    category?: string | null
  ): Promise<Product[]> {
    let query = supabase
      .from('products')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('published', true)
      .order('created_at', { ascending: false });

    if (category) {
      query = query.eq('category', category);
    }

    const { data, error } = await query;

    if (error) {
      console.error('Error fetching products:', error);
      return [];
    }

    return data || [];
  }

  /**
   * Get product by ID
   */
  static async getProduct(productId: string): Promise<Product | null> {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('id', productId)
      .eq('published', true)
      .single();

    if (error) {
      console.error('Error fetching product:', error);
      return null;
    }

    return data;
  }

  /**
   * Get unique categories for a tenant
   */
  static async getCategories(tenantId: string): Promise<string[]> {
    const { data, error } = await supabase
      .from('products')
      .select('category')
      .eq('tenant_id', tenantId)
      .eq('published', true)
      .not('category', 'is', null);

    if (error) {
      console.error('Error fetching categories:', error);
      return [];
    }

    // Extract unique categories
    const categories = [...new Set(data.map(p => p.category).filter(Boolean))];
    return categories as string[];
  }
}
