import { createClient } from '@/lib/supabase/client';
import { Delivery, DeliveryInsert, DeliveryUpdate, DeliveryWithDetails } from '@/lib/types/database';

export class DeliveryService {
    /**
     * Create a new delivery record for an order
     */
    static async createDelivery(deliveryData: DeliveryInsert): Promise<Delivery | null> {
        const supabase = await createClient();

        const { data, error } = await supabase
            .from('deliveries')
            .insert(deliveryData)
            .select()
            .single();

        if (error) {
            console.error('Error creating delivery:', error);
            throw error;
        }

        return data;
    }

    /**
     * Assign a rider to a delivery
     */
    static async assignRider(deliveryId: string, riderId: string): Promise<Delivery | null> {
        const supabase = await createClient();

        const { data, error } = await supabase
            .from('deliveries')
            .update({
                rider_id: riderId,
                delivery_status: 'assigned',
                updated_at: new Date().toISOString()
            })
            .eq('id', deliveryId)
            .select()
            .single();

        if (error) {
            console.error('Error assigning rider:', error);
            throw error;
        }

        return data;
    }

    /**
     * Update delivery status (e.g. picked_up, delivered)
     */
    static async updateStatus(
        deliveryId: string,
        updates: DeliveryUpdate
    ): Promise<Delivery | null> {
        const supabase = await createClient();

        const { data, error } = await supabase
            .from('deliveries')
            .update({
                ...updates,
                updated_at: new Date().toISOString()
            })
            .eq('id', deliveryId)
            .select()
            .single();

        if (error) {
            console.error('Error updating delivery status:', error);
            throw error;
        }

        return data;
    }

    /**
     * Get deliveries for a tenant/branch
     */
    static async getDeliveries(
        tenantId: string,
        branchId?: string,
        status?: string
    ): Promise<DeliveryWithDetails[]> {
        const supabase = await createClient();

        let query = supabase
            .from('deliveries')
            .select(`
        *,
        order:orders(*),
        rider:riders(
            *,
            user:users(*)
        )
      `)
            .eq('tenant_id', tenantId)
            .order('created_at', { ascending: false });

        if (branchId) {
            query = query.eq('branch_id', branchId);
        }

        if (status) {
            query = query.eq('delivery_status', status);
        }

        const { data, error } = await query;

        if (error) {
            console.error('Error fetching deliveries:', error);
            throw error;
        }

        return (data || []) as DeliveryWithDetails[];
    }

    /**
     * Get delivery by tracking number (public)
     */
    static async getDeliveryByTracking(trackingNumber: string): Promise<DeliveryWithDetails | null> {
        const supabase = await createClient();

        // RLS usually restricts public access, so this might need a secure RPC or 
        // a service role client if we want truly public access without login.
        // For now, assuming authenticated or relaxed RLS for specific query if implemented.
        // Actually, createClient uses user session. We might need a separate endpoint logic for public.

        const { data, error } = await supabase
            .from('deliveries')
            .select(`
        *,
        order:orders(order_number), 
        rider:riders(user:users(full_name))
      `)
            .eq('tracking_number', trackingNumber)
            .single();

        if (error) {
            // console.error('Error fetching delivery by tracking:', error); 
            // Silent fail for not found
            return null;
        }

        return data as DeliveryWithDetails;
    }
}
