import { createClient } from '@/lib/supabase/client';
import { CatalogProduct, Product } from '@/lib/types/database'; // Using our extended types
import { ProductInput } from '@/lib/types/pos';

export const catalogService = {
    /**
     * Fetch all catalog products available to the current user (Global + Tenant-specific)
     */
    async getCatalogProducts(tenantId: string): Promise<CatalogProduct[]> {
        const supabase = createClient();

        // RLS policy handles the filtering (tenant_id is null OR tenant_id matches)
        // But we might want to explicitly query to be sure or debug
        const { data, error } = await supabase
            .from('catalog_products')
            .select('*')
            .eq('is_active', true)
            .order('name');

        if (error) throw error;
        return data as CatalogProduct[] || [];
    },

    /**
     * Import a catalog product into a branch's inventory
     */
    async importProductToBranch(
        catalogProduct: CatalogProduct,
        tenantId: string,
        branchId: string,
        overrides?: Partial<ProductInput>
    ): Promise<Product | null> {
        const supabase = createClient();

        const newProduct: any = {
            tenant_id: tenantId,
            branch_id: branchId,
            catalog_product_id: catalogProduct.id,
            name: overrides?.name || catalogProduct.name,
            description: overrides?.description || catalogProduct.description,
            sku: overrides?.sku || catalogProduct.sku,
            barcode: overrides?.barcode || catalogProduct.barcode,
            category: overrides?.category || catalogProduct.category,
            image_url: overrides?.image_url || catalogProduct.image_url,
            // Default values for local inventory
            unit_price: overrides?.unit_price || 0,
            cost_price: overrides?.cost_price || 0,
            stock_quantity: overrides?.stock_quantity || 0,
            is_active: true,
        };

        const { data, error } = await supabase
            .from('products')
            .insert(newProduct)
            .select()
            .single();

        if (error) throw error;
        return data as Product;
    }
};
