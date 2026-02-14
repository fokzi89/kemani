import { createClient } from '@/lib/supabase/client';
import { Order } from '@/lib/types/database';

export class OrderService {
    /**
     * Get orders that are marked for delivery but haven't been assigned a delivery record yet.
     * Assuming 'ready' status implies the order is packed and waiting.
     */
    static async getOrdersReadyForDelivery(tenantId: string, branchId?: string): Promise<Order[]> {
        const supabase = await createClient();

        // 1. Get IDs of orders that already have a delivery record
        const { data: existingDeliveries } = await supabase
            .from('deliveries')
            .select('order_id')
            .eq('tenant_id', tenantId);

        const existingOrderIds = existingDeliveries?.map(d => d.order_id) || [];

        // 2. Fetch Orders: Fulfillment = delivery, Status = ready/confirmed (adjust based on flow), Not in existing list
        let query = supabase
            .from('orders')
            .select('*, customer:customers(*)')
            .eq('tenant_id', tenantId)
            .eq('fulfillment_type', 'delivery')
            .in('order_status', ['confirmed', 'preparing', 'ready']) // broader range for demo, ideally just 'ready'
            .order('created_at', { ascending: false });

        if (branchId) {
            query = query.eq('branch_id', branchId);
        }

        const { data, error } = await query;

        if (error) {
            console.error('Error fetching ready orders:', error);
            throw error;
        }

        // Client-side filter for exclusion (Supabase postgrest doesn't have "NOT IN (select...)" easily without raw RPC or joined filter)
        // For small batch, filtering in JS is fine. For scale, use a view or RPC.
        const readyOrders = (data || []).filter(o => !existingOrderIds.includes(o.id));

        return readyOrders;
    }
}
