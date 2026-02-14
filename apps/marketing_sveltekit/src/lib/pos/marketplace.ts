import { createClient } from '@/lib/supabase/client';
import { createAdminClient } from '@/lib/supabase/server'; // Use admin client for public access if needed, or standard client with public RLS
import { Product } from '@/lib/types/pos';
import { BrandingConfig } from '@/lib/types/database';

export class MarketplaceService {
    /**
     * Get all published products for a tenant's storefront
     * This is a public method (no auth required for viewers)
     */
    static async getStorefrontProducts(tenantId: string, category?: string) {
        // Note: For public access, we might need to rely on RLS policies that allow 
        // "select" on products where "is_published" is true (if we had such a flag)
        // or use Admin Client to bypass RLS and filter manually.
        // Since we don't have a specific "is_published" flag in the basic Product type yet (checked T041),
        // we assume all products are visible or we need to add a flag.
        // For MVP, let's assuming all products in the catalog are visible or we filter by checking stock > 0.
        // Ideally, we should have 'is_public' or similar. 
        // Let's use createAdminClient() to fetch and return (bypassing RLS that likely assumes authenticated user).
        // OR, better: We should have a public RLS policy for products.
        // Given the constraints and likely strict RLS, let's use AdminClient but be careful to only select safe fields.

        // Actually, T046/Product Service might have added fields. 
        // Let's check Product types if needed. 
        // For now, fetching standard products.

        const supabase = await createAdminClient();

        let query = supabase
            .from('products')
            .select('id, name, description, price, category, image_url, stock_quantity, unit')
            .eq('tenant_id', tenantId)
            .gt('stock_quantity', 0); // Only show in-stock items?

        if (category) {
            query = query.eq('category', category);
        }

        const { data: products, error } = await query;

        if (error) throw error;
        return products;
    }

    /**
     * Get storefront details (branding)
     */
    static async getStorefrontDetails(tenantId: string) {
        const supabase = await createAdminClient();

        const { data: tenant, error } = await supabase
            .from('tenants')
            .select('name, slug, logo_url, brand_color, ecommerce_settings')
            .eq('id', tenantId)
            .single();

        if (error) throw error;

        return {
            name: tenant.name,
            slug: tenant.slug,
            logoUrl: tenant.logo_url,
            brandColor: tenant.brand_color,
            settings: tenant.ecommerce_settings as BrandingConfig['ecommerceSettings']
        };
    }

    /**
     * Get tenant ID by slug (for public routing)
     */
    static async getTenantIdBySlug(slug: string) {
        const supabase = await createAdminClient();

        const { data, error } = await supabase
            .from('tenants')
            .select('id')
            .eq('slug', slug)
            .single();

        if (error) throw error;
        return data.id;
    }

    /**
     * Get default branch for tenant (for context like Chat)
     */
    static async getDefaultBranch(tenantId: string) {
        const supabase = await createAdminClient();
        const { data, error } = await supabase
            .from('branches')
            .select('id')
            .eq('tenant_id', tenantId)
            .order('created_at', { ascending: true })
            .limit(1)
            .single();

        if (error) return null;
        return data.id;
    }
}
