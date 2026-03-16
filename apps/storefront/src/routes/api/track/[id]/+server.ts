// Order Tracking API Endpoint (Public)
// GET /api/track/[id] - Get order tracking information (no auth required)

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
    const result = await orderService.getOrderTracking(id);

    if (result.error) {
      return json({ error: result.error }, { status: 404 });
    }

    return json(result.tracking);
  } catch (error: any) {
    return json({ error: error.message || 'Failed to fetch tracking information' }, { status: 500 });
  }
};
