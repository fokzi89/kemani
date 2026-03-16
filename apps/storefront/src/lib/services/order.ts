// Order Management Service
// Feature: 001-multi-tenant-pos (User Story 3)
// Handles order creation, status updates, fulfillment, and tracking

import type { SupabaseClient } from '@supabase/supabase-js';
import type {
  Order,
  OrderInsert,
  OrderUpdate,
  OrderDetail,
  OrderItem,
  OrderItemInsert,
  CreateOrderRequest,
  CreateOrderResponse,
  OrderTrackingResponse,
  UpdateOrderStatusRequest,
  OrderStatus,
  InventoryCheckResult,
  OrderFulfillmentResult
} from '../types/ecommerce';
import { LoyaltyService } from './loyalty';

export class OrderService {
  private loyaltyService: LoyaltyService;

  constructor(private supabase: SupabaseClient) {
    this.loyaltyService = new LoyaltyService(supabase);
  }

  /**
   * Create a new order
   */
  async createOrder(request: CreateOrderRequest): Promise<{
    order?: CreateOrderResponse;
    error?: string;
  }> {
    try {
      // 1. Validate inventory availability
      const inventoryCheck = await this.checkInventory(request.items);
      const unavailableItems = inventoryCheck.filter(item => !item.is_available);

      if (unavailable Items.length > 0) {
        return {
          error: `Items out of stock: ${unavailableItems.map(i => i.product_id).join(', ')}`
        };
      }

      // 2. Calculate totals
      const subtotal = request.items.reduce(
        (sum, item) => sum + item.unit_price * item.quantity,
        0
      );

      // Calculate tax (assume 7.5% VAT for Nigeria)
      const taxRate = 0.075;
      const tax = subtotal * taxRate;

      // Calculate delivery fee (if delivery order)
      let deliveryFee = 0;
      if (request.order_type === 'delivery') {
        // TODO: Calculate based on distance
        deliveryFee = 1000; // Flat rate for now
      }

      // Apply loyalty points discount
      let loyaltyDiscount = 0;
      if (request.loyalty_points_to_redeem && request.loyalty_points_to_redeem > 0) {
        const validation = await this.loyaltyService.validateRedemption(
          request.customer_id,
          request.loyalty_points_to_redeem,
          subtotal + tax + deliveryFee
        );

        if (!validation.valid) {
          return { error: validation.error };
        }

        loyaltyDiscount = validation.discount_amount || 0;
      }

      const totalAmount = subtotal + tax + deliveryFee - loyaltyDiscount;

      // 3. Generate order number
      const orderNumber = await this.generateOrderNumber(request.tenant_id);

      // 4. Create order
      const orderData: OrderInsert = {
        tenant_id: request.tenant_id,
        branch_id: request.branch_id,
        customer_id: request.customer_id,
        order_number: orderNumber,
        order_type: request.order_type,
        delivery_address_id: request.delivery_address_id,
        subtotal,
        tax,
        delivery_fee: deliveryFee,
        loyalty_points_discount: loyaltyDiscount,
        total_amount: totalAmount,
        payment_method: request.payment_method,
        payment_status: 'pending',
        status: 'pending',
        notes: request.notes
      };

      const { data: order, error: orderError } = await this.supabase
        .from('orders')
        .insert(orderData)
        .select()
        .single();

      if (orderError) {
        return { error: orderError.message };
      }

      // 5. Create order items
      const orderItems: OrderItemInsert[] = request.items.map(item => ({
        order_id: order.id,
        product_id: item.product_id,
        quantity: item.quantity,
        unit_price: item.unit_price,
        subtotal: item.unit_price * item.quantity
      }));

      const { error: itemsError } = await this.supabase
        .from('order_items')
        .insert(orderItems);

      if (itemsError) {
        // Rollback order
        await this.supabase.from('orders').delete().eq('id', order.id);
        return { error: itemsError.message };
      }

      // 6. Redeem loyalty points if applicable
      if (request.loyalty_points_to_redeem && request.loyalty_points_to_redeem > 0) {
        await this.loyaltyService.redeemPoints(
          request.customer_id,
          request.loyalty_points_to_redeem,
          order.id
        );
      }

      // 7. Calculate loyalty points earned
      const pointsCalculation = this.loyaltyService.calculatePointsEarned(subtotal);

      // 8. Generate tracking URL
      const trackingUrl = `/track/${order.id}`;

      // 9. Generate payment URL if needed (for card/online payments)
      let paymentUrl: string | undefined;
      if (request.payment_method !== 'cash') {
        // TODO: Integrate with Paystack/Flutterwave
        paymentUrl = `/payment/${order.id}`;
      }

      const response: CreateOrderResponse = {
        order_id: order.id,
        order_number: orderNumber,
        total_amount: totalAmount,
        payment_url: paymentUrl,
        tracking_url: trackingUrl,
        loyalty_points_earned: pointsCalculation.points_earned
      };

      return { order: response };
    } catch (error: any) {
      return { error: error.message || 'Failed to create order' };
    }
  }

  /**
   * Get order by ID with full details
   */
  async getOrder(orderId: string): Promise<{ order?: OrderDetail; error?: string }> {
    try {
      const { data: order, error: orderError } = await this.supabase
        .from('orders')
        .select(`
          *,
          customer:customers(id, full_name, email, phone),
          delivery_address:customer_addresses(*),
          items:order_items(
            *,
            product:products(id, name, sku, image_url, category)
          )
        `)
        .eq('id', orderId)
        .single();

      if (orderError) {
        return { error: orderError.message };
      }

      return { order };
    } catch (error: any) {
      return { error: error.message || 'Failed to fetch order' };
    }
  }

  /**
   * Update order status
   */
  async updateOrderStatus(
    orderId: string,
    request: UpdateOrderStatusRequest
  ): Promise<{ order?: Order; error?: string }> {
    try {
      const updates: OrderUpdate = {
        status: request.status
      };

      const { data: order, error } = await this.supabase
        .from('orders')
        .update(updates)
        .eq('id', orderId)
        .select()
        .single();

      if (error) {
        return { error: error.message };
      }

      // Create status history entry (if table exists)
      await this.supabase.from('order_status_history').insert({
        order_id: orderId,
        status: request.status,
        note: request.note
      });

      // If order is delivered, award loyalty points
      if (request.status === 'delivered') {
        await this.awardLoyaltyPointsForOrder(orderId);
      }

      return { order };
    } catch (error: any) {
      return { error: error.message || 'Failed to update order status' };
    }
  }

  /**
   * Get order tracking information
   */
  async getOrderTracking(orderId: string): Promise<{
    tracking?: OrderTrackingResponse;
    error?: string;
  }> {
    try {
      // Get order details
      const { order, error: orderError } = await this.getOrder(orderId);

      if (orderError || !order) {
        return { error: orderError || 'Order not found' };
      }

      // Get status history
      const { data: statusHistory } = await this.supabase
        .from('order_status_history')
        .select('status, created_at as timestamp, note')
        .eq('order_id', orderId)
        .order('created_at', { ascending: true });

      const tracking: OrderTrackingResponse = {
        order,
        status_history: statusHistory || [],
        estimated_delivery: this.calculateEstimatedDelivery(order),
        tracking_number: order.order_number
      };

      return { tracking };
    } catch (error: any) {
      return { error: error.message || 'Failed to fetch tracking information' };
    }
  }

  /**
   * List orders for a customer
   */
  async listCustomerOrders(
    customerId: string,
    page = 1,
    limit = 20
  ): Promise<{ orders: Order[]; total: number; error?: string }> {
    try {
      const offset = (page - 1) * limit;

      const { data: orders, error, count } = await this.supabase
        .from('orders')
        .select('*', { count: 'exact' })
        .eq('customer_id', customerId)
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1);

      if (error) {
        return { orders: [], total: 0, error: error.message };
      }

      return { orders: orders || [], total: count || 0 };
    } catch (error: any) {
      return { orders: [], total: 0, error: error.message || 'Failed to list orders' };
    }
  }

  /**
   * List orders for a tenant (merchant view)
   */
  async listTenantOrders(
    tenantId: string,
    status?: OrderStatus,
    page = 1,
    limit = 50
  ): Promise<{ orders: Order[]; total: number; error?: string }> {
    try {
      const offset = (page - 1) * limit;

      let query = this.supabase
        .from('orders')
        .select('*', { count: 'exact' })
        .eq('tenant_id', tenantId);

      if (status) {
        query = query.eq('status', status);
      }

      const { data: orders, error, count } = await query
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1);

      if (error) {
        return { orders: [], total: 0, error: error.message };
      }

      return { orders: orders || [], total: count || 0 };
    } catch (error: any) {
      return { orders: [], total: 0, error: error.message || 'Failed to list orders' };
    }
  }

  /**
   * Cancel order
   */
  async cancelOrder(
    orderId: string,
    reason?: string
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const { order, error: fetchError } = await this.getOrder(orderId);

      if (fetchError || !order) {
        return { success: false, error: fetchError || 'Order not found' };
      }

      // Only allow cancellation of pending/confirmed orders
      if (!['pending', 'confirmed'].includes(order.status)) {
        return { success: false, error: 'Order cannot be cancelled at this stage' };
      }

      // Update order status
      await this.updateOrderStatus(orderId, {
        status: 'cancelled',
        note: reason
      });

      // Restore inventory if already deducted
      await this.restoreInventory(orderId);

      // Refund loyalty points if redeemed
      if (order.loyalty_points_discount && order.loyalty_points_discount > 0) {
        const pointsRedeemed = Math.floor(order.loyalty_points_discount / 100); // Reverse calculation
        await this.loyaltyService.awardPoints(order.customer_id, pointsRedeemed, orderId);
      }

      return { success: true };
    } catch (error: any) {
      return { success: false, error: error.message || 'Failed to cancel order' };
    }
  }

  // ============================================================================
  // Private Helper Methods
  // ============================================================================

  /**
   * Check inventory availability for order items
   */
  private async checkInventory(
    items: Array<{ product_id: string; quantity: number }>
  ): Promise<InventoryCheckResult[]> {
    const results: InventoryCheckResult[] = [];

    for (const item of items) {
      const { data: product } = await this.supabase
        .from('products')
        .select('stock_quantity')
        .eq('id', item.product_id)
        .single();

      results.push({
        product_id: item.product_id,
        requested_quantity: item.quantity,
        available_quantity: product?.stock_quantity || 0,
        is_available: (product?.stock_quantity || 0) >= item.quantity
      });
    }

    return results;
  }

  /**
   * Generate unique order number
   */
  private async generateOrderNumber(tenantId: string): Promise<string> {
    const date = new Date();
    const dateStr = date.toISOString().slice(0, 10).replace(/-/g, '');
    const randomStr = Math.random().toString(36).substring(2, 8).toUpperCase();
    return `ORD-${dateStr}-${randomStr}`;
  }

  /**
   * Calculate estimated delivery time
   */
  private calculateEstimatedDelivery(order: OrderDetail): string | undefined {
    if (order.order_type !== 'delivery') {
      return undefined;
    }

    // Simple estimation: 1-2 hours from order creation
    const estimatedDate = new Date(order.created_at);
    estimatedDate.setHours(estimatedDate.getHours() + 2);
    return estimatedDate.toISOString();
  }

  /**
   * Award loyalty points for completed order
   */
  private async awardLoyaltyPointsForOrder(orderId: string): Promise<void> {
    try {
      const { order } = await this.getOrder(orderId);
      if (!order) return;

      const pointsCalculation = this.loyaltyService.calculatePointsEarned(order.subtotal);

      await this.loyaltyService.awardPoints(
        order.customer_id,
        pointsCalculation.points_earned,
        orderId
      );

      // Update customer total_spent
      await this.supabase.rpc('increment_customer_total_spent', {
        p_customer_id: order.customer_id,
        p_amount: order.total_amount
      });
    } catch (error) {
      console.error('Failed to award loyalty points:', error);
    }
  }

  /**
   * Restore inventory for cancelled order
   */
  private async restoreInventory(orderId: string): Promise<void> {
    try {
      const { data: orderItems } = await this.supabase
        .from('order_items')
        .select('product_id, quantity')
        .eq('order_id', orderId);

      if (!orderItems) return;

      for (const item of orderItems) {
        await this.supabase.rpc('increment_product_stock', {
          p_product_id: item.product_id,
          p_quantity: item.quantity
        });
      }
    } catch (error) {
      console.error('Failed to restore inventory:', error);
    }
  }
}
