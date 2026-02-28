import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_admin/models/order.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  // Singleton pattern
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  Future<Order> createOrder(Order order) async {
    // Basic implementation: Insert order and return it
    final response =
        await _client.from('orders').insert(order.toJson()).select().single();

    // Insert order items if present
    if (order.items != null && order.items!.isNotEmpty) {
      final itemsData = order.items!.map((item) {
        var map = item.toJson();
        map['order_id'] = response['id'];
        return map;
      }).toList();
      await _client.from('order_items').insert(itemsData);
    }

    return Order.fromJson(response);
  }

  Future<Order> updateOrderStatus(String orderId, String status) async {
    final updates = {
      'order_status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    final response = await _client
        .from('orders')
        .update(updates)
        .eq('id', orderId)
        .select()
        .single();
    return Order.fromJson(response);
  }

  Future<Order?> getOrder(String orderId) async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .maybeSingle();
    if (response == null) return null;

    // Convert related order_items
    var orderMap = Map<String, dynamic>.from(response);
    if (orderMap.containsKey('order_items')) {
      orderMap['items'] = orderMap['order_items'];
      orderMap.remove('order_items');
    }

    return Order.fromJson(orderMap);
  }

  Future<List<Order>> listOrders({
    int limit = 50,
    int offset = 0,
    String? tenantId,
    String? status,
    String? orderType,
  }) async {
    var query = _client.from('orders').select();

    if (tenantId != null && tenantId.isNotEmpty) {
      query = query.eq('tenant_id', tenantId);
    }
    if (status != null && status.isNotEmpty) {
      query = query.eq('order_status', status);
    }
    if (orderType != null && orderType.isNotEmpty) {
      query = query.eq('order_type', orderType);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Order>.from(response.map((x) => Order.fromJson(x)));
  }

  Future<Order> cancelOrder(String orderId, String? reason) async {
    final updates = {
      'order_status': 'cancelled',
      if (reason != null && reason.isNotEmpty) 'special_instructions': reason,
      'updated_at': DateTime.now().toIso8601String(),
    };
    final response = await _client
        .from('orders')
        .update(updates)
        .eq('id', orderId)
        .select()
        .single();
    return Order.fromJson(response);
  }

  Future<List<Order>> getCustomerOrders(String customerId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return List<Order>.from(response.map((x) => Order.fromJson(x)));
  }
}
