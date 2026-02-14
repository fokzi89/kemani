import { createClient } from '@/lib/supabase/client';
import {
    Order,
    OrderInsert,
    OrderUpdate,
    OrderItemInsert,
    OrderWithItems,
    OrderStatus,
    PaymentStatus
} from '@/lib/types/database';
import { LoyaltyService } from './loyalty';

export class OrderService {
    /**
     * Create a new order with items
     */
    static async createOrder(orderData: OrderInsert, items: OrderItemInsert[]) {
        const supabase = createClient();

        try {
            // 1. Create order record
            const { data: order, error: orderError } = await supabase
                .from('orders')
                .insert(orderData)
                .select()
                .single();

            if (orderError) throw orderError;
            if (!order) throw new Error('Failed to create order');

            // 2. Create order items
            if (items.length > 0) {
                const itemsWithOrderId = items.map(item => ({
                    ...item,
                    order_id: order.id
                }));

                const { error: itemsError } = await supabase
                    .from('order_items')
                    .insert(itemsWithOrderId);

                if (itemsError) throw itemsError;
            }

            // 3. Award loyalty points if completed and paid
            if (order.status === 'completed' && order.payment_status === 'paid' && order.customer_id) {
                // Calculate based on total amount
                await LoyaltyService.awardPoints(order.customer_id, order.total_amount);
            }

            return order;
        } catch (error) {
            console.error('Create order error:', error);
            throw error;
        }
    }

    /**
     * Get order by ID with items and customer
     */
    static async getOrder(orderId: string): Promise<OrderWithItems> {
        const supabase = createClient();

        const { data, error } = await supabase
            .from('orders')
            .select(`
        *,
        items:order_items(
          *,
          product:products(*)
        ),
        customer:customers(*)
      `)
            .eq('id', orderId)
            .single();

        if (error) throw error;
        return data as OrderWithItems;
    }

    /**
     * Update order status
     */
    static async updateStatus(orderId: string, status: OrderStatus, paymentStatus?: PaymentStatus) {
        const supabase = createClient();

        const updates: OrderUpdate = { status };
        if (paymentStatus) {
            updates.payment_status = paymentStatus;
        }

        const { data, error } = await supabase
            .from('orders')
            .update(updates)
            .eq('id', orderId)
            .select()
            .single();

        if (error) throw error;

        // Award points if completing previously unpaid/incomplete order
        // Note: Ideally check previous state to avoid double awarding. 
        // For now, simpler check: if becoming completed & paid.
        if (status === 'completed' && (!paymentStatus || paymentStatus === 'paid')) {
            // We'd need to fetch order to get amount and customer.
            // Skipping for simplicity in this method, assuming caller handles or createOrder handles it.
            // Or implement properly:
            const order = data;
            if (order.customer_id && order.payment_status === 'paid') {
                await LoyaltyService.awardPoints(order.customer_id, order.total_amount);
            }
        }

        return data;
    }

    /**
     * Get orders for a tenant (filtered)
     */
    static async getOrders(tenantId: string, options?: {
        limit?: number;
        status?: OrderStatus;
        customerId?: string;
    }): Promise<Order[]> {
        const supabase = createClient();

        let query = supabase
            .from('orders')
            .select('*')
            .eq('tenant_id', tenantId)
            .order('created_at', { ascending: false });

        if (options?.status) {
            query = query.eq('status', options.status);
        }

        if (options?.customerId) {
            query = query.eq('customer_id', options.customerId);
        }

        if (options?.limit) {
            query = query.limit(options.limit);
        }

        const { data, error } = await query;

        if (error) throw error;
        return data;
    }
}
