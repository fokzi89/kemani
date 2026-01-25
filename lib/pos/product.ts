import { createClient } from '@/lib/supabase/client';
import { Product, ProductInput } from '@/lib/types/pos';
import { v4 as uuidv4 } from 'uuid';

export const productService = {
    async getProducts(tenantId: string, branchId: string): Promise<Product[]> {
        const supabase = createClient();
        const { data, error } = await supabase
            .from('products')
            .select('*')
            .eq('tenant_id', tenantId)
            .eq('branch_id', branchId)
            .eq('is_active', true);

        if (error) throw error;
        return data || [];
    },

    async createProduct(product: ProductInput, tenantId: string, branchId: string): Promise<Product | null> {
        const supabase = createClient();
        const newProduct = {
            ...product,
            tenant_id: tenantId,
            branch_id: branchId,
        };

        const { data, error } = await supabase
            .from('products')
            .insert(newProduct)
            .select()
            .single();

        if (error) throw error;
        return data;
    },

    async updateProduct(id: string, updates: Partial<ProductInput>): Promise<Product | null> {
        const supabase = createClient();
        const { data, error } = await supabase
            .from('products')
            .update(updates)
            .eq('id', id)
            .select()
            .single();

        if (error) throw error;
        return data;
    },

    async deleteProduct(id: string): Promise<void> {
        const supabase = createClient();
        const { error } = await supabase
            .from('products')
            .update({ is_active: false }) // Soft delete
            .eq('id', id);

        if (error) throw error;
    }
};
