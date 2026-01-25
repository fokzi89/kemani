import { createClient } from '@/lib/supabase/client';
import { SaleInput, Sale, SaleItem } from '@/lib/types/pos';
import { inventoryService } from './inventory';

export const transactionService = {
    async processSale(saleData: SaleInput, userId: string, tenantId: string, branchId: string): Promise<Sale | null> {
        const supabase = createClient();

        // 1. Calculate Totals (Double check backend calculation/validation)
        // Client should already provide calculated totals, but verifying is good practice.
        // For MVP transparency, we accept client values assuming validation happened.

        // 2. Create Sale Record
        const { data: sale, error: saleError } = await supabase
            .from('sales')
            .insert({
                tenant_id: tenantId,
                branch_id: branchId,
                cashier_id: userId,
                customer_id: saleData.customer_id,
                subtotal: saleData.subtotal,
                tax_amount: saleData.tax_amount,
                discount_amount: saleData.discount_amount,
                total_amount: saleData.total_amount,
                payment_method: saleData.payment_method,
                payment_reference: saleData.payment_reference,
                status: 'completed',
                is_synced: true, // Online first logic for now
            })
            .select()
            .single();

        if (saleError) throw saleError;
        if (!sale) throw new Error('Failed to create sale');

        // 3. Create Sale Items
        const itemsToInsert = saleData.items.map(item => ({
            sale_id: sale.id,
            product_id: item.product_id,
            product_name: item.product_name,
            quantity: item.quantity,
            unit_price: item.unit_price,
            discount_percent: item.discount_percent,
            discount_amount: item.discount_amount,
            subtotal: item.subtotal,
        }));

        const { error: itemsError } = await supabase
            .from('sale_items')
            .insert(itemsToInsert);

        if (itemsError) throw itemsError;

        // 4. Update Inventory for each item
        for (const item of saleData.items) {
            await inventoryService.adjustStock(
                item.product_id,
                -item.quantity,
                'sale',
                userId,
                tenantId,
                branchId,
                `Sale #${sale.sale_number}`
            );
        }

        return sale;
    },

    async voidSale(saleId: string, userId: string): Promise<boolean> {
        const supabase = createClient();

        // 1. Get Sale & Items
        const { data: sale, error: saleError } = await supabase
            .from('sales')
            .select('*, sale_items(*)')
            .eq('id', saleId)
            .single();

        if (saleError || !sale) throw new Error('Sale not found');
        if (sale.status === 'cancelled') throw new Error('Sale already cancelled');

        // 2. Update Status
        const { error: updateError } = await supabase
            .from('sales')
            .update({ status: 'cancelled' })
            .eq('id', saleId);

        if (updateError) throw updateError;

        // 3. Return Inventory
        for (const item of sale.sale_items) {
            await inventoryService.adjustStock(
                item.product_id,
                item.quantity, // Positive quantity adds back
                'return',
                userId,
                sale.tenant_id,
                sale.branch_id,
                `Void Sale #${sale.sale_number}`
            );
        }

        return true;
    }
};
