import { createClient } from '@/lib/supabase/client';
import {
    Customer,
    CustomerInsert,
    CustomerUpdate,
    CustomerAddress,
    CustomerAddressInsert,
    CustomerAddressUpdate,
    CustomerWithAddresses
} from '@/lib/types/database';

export class CustomerService {
    /**
     * Create a new customer
     */
    static async createCustomer(customer: CustomerInsert) {
        const supabase = createClient();

        // Check if customer with phone/email already exists for this tenant
        // (Assuming tenant_id is part of RLS, but explicit check is good for UX)
        // Actually, RLS handles tenant isolation, but we might want to prevent duplicates.

        const { data, error } = await supabase
            .from('customers')
            .insert(customer)
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    /**
     * Get customer by ID
     */
    static async getCustomer(customerId: string): Promise<CustomerWithAddresses> {
        const supabase = createClient();

        const { data, error } = await supabase
            .from('customers')
            .select(`
        *,
        addresses:customer_addresses(*)
      `)
            .eq('id', customerId)
            .single();

        if (error) throw error;
        return data;
    }

    /**
     * Search customers by name, email, or phone
     */
    static async searchCustomers(query: string, tenantId: string): Promise<Customer[]> {
        const supabase = createClient();

        // Note: RLS should filter by tenant_id automatically if set up correctly.
        // However, explicitly filtering is safe.
        // Using 'ilike' for case-insensitive search.

        const { data, error } = await supabase
            .from('customers')
            .select('*')
            .eq('tenant_id', tenantId)
            .or(`full_name.ilike.%${query}%,email.ilike.%${query}%,phone.ilike.%${query}%`)
            .limit(20);

        if (error) throw error;
        return data;
    }

    /**
     * Update customer
     */
    static async updateCustomer(customerId: string, updates: CustomerUpdate) {
        const supabase = createClient();

        const { data, error } = await supabase
            .from('customers')
            .update(updates)
            .eq('id', customerId)
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    /**
     * Add address to customer
     */
    static async addAddress(address: CustomerAddressInsert) {
        const supabase = createClient();

        // If setting as default, unset others first? 
        // Or handle in UI/trigger? 
        // Let's keep it simple for now. 

        const { data, error } = await supabase
            .from('customer_addresses')
            .insert(address)
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    /**
     * Update customer address
     */
    static async updateAddress(addressId: string, updates: CustomerAddressUpdate) {
        const supabase = createClient();

        const { data, error } = await supabase
            .from('customer_addresses')
            .update(updates)
            .eq('id', addressId)
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    /**
     * Delete customer address
     */
    static async deleteAddress(addressId: string) {
        const supabase = createClient();

        const { error } = await supabase
            .from('customer_addresses')
            .delete()
            .eq('id', addressId);

        if (error) throw error;
        return { success: true };
    }

    /**
     * Update loyalty points balance
     * (Usually called by LoyaltyService)
     */
    static async updateLoyaltyPoints(customerId: string, pointsDelta: number) {
        const supabase = createClient();

        // We can use an RPC call if we want atomicity or simply read-modify-write if optimistic
        // For now, let's use a direct update assuming we have the current value or use RPC if it exists.
        // Simpler approach: fetch current, add delta, update.

        const { data: customer, error: fetchError } = await supabase
            .from('customers')
            .select('loyalty_points')
            .eq('id', customerId)
            .single();

        if (fetchError) throw fetchError;

        const newBalance = (customer.loyalty_points || 0) + pointsDelta;

        const { data, error } = await supabase
            .from('customers')
            .update({ loyalty_points: newBalance })
            .eq('id', customerId)
            .select()
            .single();

        if (error) throw error;
        return data;
    }
}
