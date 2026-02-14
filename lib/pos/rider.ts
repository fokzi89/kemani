import { createClient } from '@/lib/supabase/client';
import { Rider, RiderInsert, RiderUpdate, VehicleType } from '@/lib/types/database';

export class RiderService {
    /**
     * Create a new rider profile linked to a user
     */
    static async createRider(riderData: RiderInsert): Promise<Rider | null> {
        const supabase = await createClient();

        const { data, error } = await supabase
            .from('riders')
            .insert(riderData)
            .select()
            .single();

        if (error) {
            console.error('Error creating rider:', error);
            throw error;
        }

        return data;
    }

    /**
     * Update a rider's profile or status
     */
    static async updateRider(riderId: string, updates: RiderUpdate): Promise<Rider | null> {
        const supabase = await createClient();

        const { data, error } = await supabase
            .from('riders')
            .update(updates)
            .eq('id', riderId)
            .select()
            .single();

        if (error) {
            console.error('Error updating rider:', error);
            throw error;
        }

        return data;
    }

    /**
     * Get all riders for a tenant, optionally filtered by availability
     */
    static async getRiders(tenantId: string, availableOnly: boolean = false): Promise<Rider[]> {
        const supabase = await createClient();

        let query = supabase
            .from('riders')
            .select('*, user:users(full_name, phone)')
            .eq('tenant_id', tenantId)
            .is('deleted_at', null);

        if (availableOnly) {
            query = query.eq('is_available', true);
        }

        const { data, error } = await query;

        if (error) {
            console.error('Error fetching riders:', error);
            throw error;
        }

        return data || [];
    }

    /**
     * Get a single rider by ID
     */
    static async getRider(riderId: string): Promise<Rider | null> {
        const supabase = await createClient();

        const { data, error } = await supabase
            .from('riders')
            .select('*, user:users(*)')
            .eq('id', riderId)
            .single();

        if (error) {
            console.error('Error fetching rider:', error);
            throw error;
        }

        return data;
    }
}
