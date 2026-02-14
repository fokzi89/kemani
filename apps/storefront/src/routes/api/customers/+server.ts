import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { createClient } from '$lib/services/supabase';

// POST - Create or update customer
export const POST: RequestHandler = async ({ request }) => {
    try {
        const customerData = await request.json();
        const { name, phone, email, delivery_address, delivery_coordinates } = customerData;

        if (!name || !phone) {
            return json({ error: 'Name and phone are required' }, { status: 400 });
        }

        const supabase = createClient();

        // Check if customer exists by phone
        const { data: existingCustomer } = await supabase
            .from('customers')
            .select('*')
            .eq('phone', phone)
            .maybeSingle();

        if (existingCustomer) {
            // Update existing customer
            const { data, error } = await supabase
                .from('customers')
                .update({
                    name,
                    email,
                    delivery_address,
                    delivery_coordinates,
                    updated_at: new Date().toISOString()
                })
                .eq('id', existingCustomer.id)
                .select()
                .single();

            if (error) {
                console.error('Customer update error:', error);
                return json({ error: error.message }, { status: 500 });
            }

            return json({ customer: data, isNew: false });
        } else {
            // Create new customer
            const { data, error } = await supabase
                .from('customers')
                .insert({
                    name,
                    phone,
                    email,
                    delivery_address,
                    delivery_coordinates
                })
                .select()
                .single();

            if (error) {
                console.error('Customer creation error:', error);
                return json({ error: error.message }, { status: 500 });
            }

            return json({ customer: data, isNew: true }, { status: 201 });
        }
    } catch (error: any) {
        console.error('Customers API Error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};
