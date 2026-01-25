import { createClient } from '@/lib/supabase/client';
import { InventoryTransaction } from '@/lib/types/pos';

export const inventoryService = {
    async adjustStock(
        productId: string,
        quantityDelta: number,
        type: 'restock' | 'adjustment' | 'sale' | 'transfer_out' | 'transfer_in' | 'expiry' | 'return' | 'void',
        userId: string,
        tenantId: string,
        branchId: string,
        notes?: string
    ): Promise<void> {
        const supabase = createClient();

        // 1. Get current stock
        const { data: product, error: fetchError } = await supabase
            .from('products')
            .select('stock_quantity')
            .eq('id', productId)
            .single();

        if (fetchError || !product) throw new Error('Product not found');

        const previousQuantity = product.stock_quantity;
        const newQuantity = previousQuantity + quantityDelta;

        if (newQuantity < 0) throw new Error('Insufficient stock');

        // 2. Create inventory transaction record
        const transaction = {
            tenant_id: tenantId,
            branch_id: branchId,
            product_id: productId,
            transaction_type: type,
            quantity_delta: quantityDelta,
            previous_quantity: previousQuantity,
            new_quantity: newQuantity,
            staff_id: userId,
            notes,
        };

        const { error: txnError } = await supabase
            .from('inventory_transactions')
            .insert(transaction);

        if (txnError) throw txnError;

        // 3. Update product stock
        const { error: updateError } = await supabase
            .from('products')
            .update({ stock_quantity: newQuantity })
            .eq('id', productId);

        if (updateError) throw updateError;
    },

    async getLowStockAlerts(branchId: string) {
        const supabase = createClient();
        const { data, error } = await supabase
            .from('products')
            .select('*')
            .eq('branch_id', branchId)
            .eq('is_active', true)
        // This query checks if stock <= threshold. 
        // Note: Supabase JS filter syntax for comparing two columns is complex or requires rpc.
        // For simple usage, we might filter client side or use a view.
        // Or simpler: .lte('stock_quantity', 10) if threshold is constant.
        // Since threshold varies, we might rely on the DB index or a view.
        // For MVP, fetch all and filter or use a specific RPC.
        // Let's assume we use an RPC 'get_low_stock_products' or client filtering for now.

        if (error) throw error;
        return data?.filter(p => p.stock_quantity <= (p.low_stock_threshold || 10)) || [];
    }
};
