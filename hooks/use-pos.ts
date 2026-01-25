import { useQuery, usePowerSync } from '@powersync/react';
import { Product, SaleInput } from '@/lib/types/pos';
import { v4 as uuidv4 } from 'uuid';

export const useProducts = (branchId: string, searchQuery: string = '') => {
    // Basic query
    // In real app, might want to use full text search features of SQLite or just simple LIKE
    const query = `
        SELECT * FROM products 
        WHERE branch_id = ? 
        AND (name LIKE ? OR sku LIKE ? OR barcode LIKE ?)
        ORDER BY name ASC
    `;

    const searchParam = `%${searchQuery}%`;
    const { data, isLoading, error } = useQuery<Product>(query, [branchId, searchParam, searchParam, searchParam]);

    return { products: data, isLoading, error };
};

export const useProcessSale = () => {
    const powerSync = usePowerSync();

    const processSale = async (saleData: SaleInput, branchId: string, userId: string, tenantId: string) => {
        // Wrap in transaction
        await powerSync.writeTransaction(async (tx) => {
            const saleId = uuidv4();
            const saleNumber = `SALE-${Date.now()}`; // Simple generation, backend or trigger can improve

            // 1. Insert Sale
            await tx.execute(`
                INSERT INTO sales (
                    id, sale_number, subtotal, total_amount, payment_method, 
                    status, tenant_id, branch_id, cashier_id, customer_id, 
                    is_synced, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `, [
                saleId, saleNumber, saleData.subtotal, saleData.total_amount, saleData.payment_method,
                'completed', tenantId, branchId, userId, saleData.customer_id || null,
                0, new Date().toISOString(), new Date().toISOString()
            ]);

            // 2. Insert Items & Update Inventory
            for (const item of saleData.items) {
                const itemId = uuidv4();
                await tx.execute(`
                    INSERT INTO sale_items (
                        id, sale_id, product_id, quantity, unit_price, subtotal, product_name
                    ) VALUES (?, ?, ?, ?, ?, ?, ?)
                `, [
                    itemId, saleId, item.product_id, item.quantity, item.unit_price, item.subtotal, item.product_name
                ]);

                // Update Local Inventory (Optimistic Link)
                // Note: We read current first or just decrement? 
                // Simple decrement for MVP
                await tx.execute(`
                    UPDATE products 
                    SET stock_quantity = stock_quantity - ? 
                    WHERE id = ?
                `, [item.quantity, item.product_id]);

                // Track Transaction
                // We need previous quantity for record - typically read first
                // skipping precise previous_req tracking in this simplified snippets for speed
                await tx.execute(`
                    INSERT INTO inventory_transactions (
                        id, product_id, quantity_delta, transaction_type, 
                        tenant_id, branch_id, staff_id, created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                `, [
                    uuidv4(), item.product_id, -item.quantity, 'sale',
                    tenantId, branchId, userId, new Date().toISOString()
                ]);
            }
        });

        return true;
    };

    const voidSale = async (saleId: string, userId: string, branchId: string, tenantId: string) => {
        await powerSync.writeTransaction(async (tx) => {
            // 1. Get items (simplified query, ensure table scan or index)
            const result = await tx.execute('SELECT * FROM sale_items WHERE sale_id = ?', [saleId]);
            // @ts-ignore
            const items: any[] = result.rows._array || [];

            // 2. Update Sale Status
            await tx.execute('UPDATE sales SET status = ? WHERE id = ?', ['cancelled', saleId]);

            // 3. Return Stock
            for (const item of items) {
                await tx.execute('UPDATE products SET stock_quantity = stock_quantity + ? WHERE id = ?', [item.quantity, item.product_id]);

                await tx.execute(`
                    INSERT INTO inventory_transactions (
                        id, product_id, quantity_delta, transaction_type, 
                        tenant_id, branch_id, staff_id, created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                `, [
                    uuidv4(), item.product_id, item.quantity, 'return',
                    tenantId, branchId, userId, new Date().toISOString()
                ]);
            }
        });
        return true;
    };

    return { processSale, voidSale };
};
