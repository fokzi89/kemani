// Order Detail API Endpoints
// GET /api/orders/[id] - Get order details
// DELETE /api/orders/[id] - Cancel order

import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { createClient } from '@supabase/supabase-js';
import { OrderService } from '$lib/services/order';

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);

export const GET: RequestHandler = async ({ params }) => {
  try {
    const { id } = params;

    const orderService = new OrderService(supabase);
    const result = await orderService.getOrder(id);

    if (result.error) {
      return json({ error: result.error }, { status: 404 });
    }

    return json({ order: result.order });
  } catch (error: any) {
    return json({ error: error.message || 'Failed to fetch order' }, { status: 500 });
  }
};

export const DELETE: RequestHandler = async ({ params, url }) => {
  try {
    const { id } = params;
    const reason = url.searchParams.get('reason');

    const orderService = new OrderService(supabase);
    const result = await orderService.cancelOrder(id, reason || undefined);

    if (result.error) {
      return json({ error: result.error }, { status: 500 });
    }

    return json({ success: true, message: 'Order cancelled successfully' });
  } catch (error: any) {
    return json({ error: error.message || 'Failed to cancel order' }, { status: 500 });
  }
};
