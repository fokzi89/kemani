// Orders API Endpoints
// GET /api/orders - List orders
// POST /api/orders - Create new order

import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { supabase } from '$lib/supabase';
import { OrderService } from '$lib/services/order';
import type { CreateOrderRequest } from '$lib/types/ecommerce';



export const GET: RequestHandler = async ({ url }) => {
  try {
    const tenantId = url.searchParams.get('tenant_id');
    const customerId = url.searchParams.get('customer_id');
    const status = url.searchParams.get('status');
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '20');

    const orderService = new OrderService(supabase);

    if (customerId) {
      // List customer orders
      const result = await orderService.listCustomerOrders(customerId, page, limit);
      if (result.error) {
        return json({ error: result.error }, { status: 500 });
      }
      return json({
        orders: result.orders,
        pagination: {
          page,
          limit,
          total: result.total,
          pages: Math.ceil(result.total / limit)
        }
      });
    } else if (tenantId) {
      // List tenant orders (merchant view)
      const result = await orderService.listTenantOrders(
        tenantId,
        status as any,
        page,
        limit
      );
      if (result.error) {
        return json({ error: result.error }, { status: 500 });
      }
      return json({
        orders: result.orders,
        pagination: {
          page,
          limit,
          total: result.total,
          pages: Math.ceil(result.total / limit)
        }
      });
    } else {
      return json({ error: 'tenant_id or customer_id is required' }, { status: 400 });
    }
  } catch (error: any) {
    return json({ error: error.message || 'Failed to fetch orders' }, { status: 500 });
  }
};

export const POST: RequestHandler = async ({ request }) => {
  try {
    const orderRequest: CreateOrderRequest = await request.json();

    // Validate required fields
    if (!orderRequest.customer_id || !orderRequest.tenant_id || !orderRequest.branch_id) {
      return json(
        { error: 'customer_id, tenant_id, and branch_id are required' },
        { status: 400 }
      );
    }

    if (!orderRequest.items || orderRequest.items.length === 0) {
      return json({ error: 'Order must contain at least one item' }, { status: 400 });
    }

    if (orderRequest.order_type === 'delivery' && !orderRequest.delivery_address_id) {
      return json(
        { error: 'delivery_address_id is required for delivery orders' },
        { status: 400 }
      );
    }

    const orderService = new OrderService(supabase);
    const result = await orderService.createOrder(orderRequest);

    if (result.error) {
      return json({ error: result.error }, { status: 500 });
    }

    return json(result.order, { status: 201 });
  } catch (error: any) {
    return json({ error: error.message || 'Failed to create order' }, { status: 500 });
  }
};

