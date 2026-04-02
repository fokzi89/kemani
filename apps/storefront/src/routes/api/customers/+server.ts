// Customer API Endpoints
// GET /api/customers - List customers (merchant)
// POST /api/customers - Register new customer

import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { supabase } from '$lib/supabase';
import { CustomerService } from '$lib/services/customer';



export const GET: RequestHandler = async ({ url }) => {
  try {
    const tenantId = url.searchParams.get('tenant_id');
    const query = url.searchParams.get('query');
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '50');

    if (!tenantId) {
      return json({ error: 'tenant_id is required' }, { status: 400 });
    }

    const customerService = new CustomerService(supabase);

    if (query) {
      // Search customers
      const result = await customerService.searchCustomers(tenantId, query, limit);
      if (result.error) {
        return json({ error: result.error }, { status: 500 });
      }
      return json({ customers: result.customers });
    } else {
      // List all customers
      const result = await customerService.listCustomers(tenantId, page, limit);
      if (result.error) {
        return json({ error: result.error }, { status: 500 });
      }
      return json({
        customers: result.customers,
        pagination: {
          page,
          limit,
          total: result.total,
          pages: Math.ceil(result.total / limit)
        }
      });
    }
  } catch (error: any) {
    return json({ error: error.message || 'Failed to fetch customers' }, { status: 500 });
  }
};

export const POST: RequestHandler = async ({ request }) => {
  try {
    const body = await request.json();
    const { full_name, email, phone, tenant_id } = body;

    if (!tenant_id || !full_name || !phone) {
      return json({ error: 'tenant_id, full_name, and phone are required' }, { status: 400 });
    }

    const customerService = new CustomerService(supabase);
    const result = await customerService.registerCustomer(
      { full_name, email, phone },
      tenant_id
    );

    if (result.error) {
      return json({ error: result.error }, { status: 500 });
    }

    return json({ customer: result.customer }, { status: 201 });
  } catch (error: any) {
    return json({ error: error.message || 'Failed to register customer' }, { status: 500 });
  }
};

