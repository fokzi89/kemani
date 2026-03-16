// Order Status Update API Endpoint
// PUT /api/orders/[id]/status - Update order status (merchant only)

import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { createClient } from '@supabase/supabase-js';
import { OrderService } from '$lib/services/order';
import type { UpdateOrderStatusRequest } from '$lib/types/ecommerce';

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);

export const PUT: RequestHandler = async ({ params, request }) => {
  try {
    const { id } = params;
    const statusUpdate: UpdateOrderStatusRequest = await request.json();

    if (!statusUpdate.status) {
      return json({ error: 'status is required' }, { status: 400 });
    }

    const orderService = new OrderService(supabase);
    const result = await orderService.updateOrderStatus(id, statusUpdate);

    if (result.error) {
      return json({ error: result.error }, { status: 500 });
    }

    return json({ order: result.order });
  } catch (error: any) {
    return json({ error: error.message || 'Failed to update order status' }, { status: 500 });
  }
};
