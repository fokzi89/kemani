// Customer Detail API Endpoints
// GET /api/customers/[id] - Get customer details
// PUT /api/customers/[id] - Update customer

import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { createClient } from '@supabase/supabase-js';
import { CustomerService } from '$lib/services/customer';

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);

export const GET: RequestHandler = async ({ params, url }) => {
  try {
    const { id } = params;
    const withStats = url.searchParams.get('with_stats') === 'true';

    const customerService = new CustomerService(supabase);

    if (withStats) {
      const result = await customerService.getCustomerWithStats(id);
      if (result.error) {
        return json({ error: result.error }, { status: 500 });
      }
      return json({ customer: result.customer });
    } else {
      const result = await customerService.getCustomer(id);
      if (result.error) {
        return json({ error: result.error }, { status: 404 });
      }
      return json({ customer: result.customer });
    }
  } catch (error: any) {
    return json({ error: error.message || 'Failed to fetch customer' }, { status: 500 });
  }
};

export const PUT: RequestHandler = async ({ params, request }) => {
  try {
    const { id } = params;
    const updates = await request.json();

    const customerService = new CustomerService(supabase);
    const result = await customerService.updateCustomer(id, updates);

    if (result.error) {
      return json({ error: result.error }, { status: 500 });
    }

    return json({ customer: result.customer });
  } catch (error: any) {
    return json({ error: error.message || 'Failed to update customer' }, { status: 500 });
  }
};
