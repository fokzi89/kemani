// Customer Addresses API Endpoints
// GET /api/customers/[id]/addresses - Get customer addresses
// POST /api/customers/[id]/addresses - Add new address

import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { createClient } from '@supabase/supabase-js';
import { CustomerService } from '$lib/services/customer';

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);

export const GET: RequestHandler = async ({ params }) => {
  try {
    const { id } = params;

    const customerService = new CustomerService(supabase);
    const result = await customerService.getAddresses(id);

    if (result.error) {
      return json({ error: result.error }, { status: 500 });
    }

    return json({ addresses: result.addresses });
  } catch (error: any) {
    return json({ error: error.message || 'Failed to fetch addresses' }, { status: 500 });
  }
};

export const POST: RequestHandler = async ({ params, request }) => {
  try {
    const { id } = params;
    const addressData = await request.json();

    const customerService = new CustomerService(supabase);
    const result = await customerService.addAddress(id, addressData);

    if (result.error) {
      return json({ error: result.error }, { status: 500 });
    }

    return json({ address: result.address }, { status: 201 });
  } catch (error: any) {
    return json({ error: error.message || 'Failed to add address' }, { status: 500 });
  }
};
