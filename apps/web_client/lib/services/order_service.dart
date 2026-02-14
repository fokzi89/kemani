import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Order>> getOrders(String branchId) async {
    final response = await _supabase
        .from('orders')
        .select('*, order_items(*)') // Fetch orders with items
        .eq('branch_id', branchId)
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data.map((json) => Order.fromJson(json)).toList();
  }

  Future<Order> createOrder({
    required Map<String, dynamic> orderData,
    required List<Map<String, dynamic>> itemsData,
  }) async {
    // 1. Insert Order
    final orderResponse = await _supabase
        .from('orders')
        .insert(orderData)
        .select()
        .single();

    final orderId = orderResponse['id'];

    // 2. Prepare Items with order_id
    final itemsToInsert = itemsData.map((item) {
      return {
        ...item,
        'order_id': orderId,
      };
    }).toList();

    // 3. Insert Items
    await _supabase.from('order_items').insert(itemsToInsert);

    // 4. Return complete order
    return Order.fromJson({
      ...orderResponse,
      'order_items': itemsToInsert,
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _supabase
        .from('orders')
        .update({'order_status': status.name})
        .eq('id', orderId);
  }
}
