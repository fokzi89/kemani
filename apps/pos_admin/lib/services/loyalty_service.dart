import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_admin/models/order.dart';

class LoyaltyService {
  final SupabaseClient _client = Supabase.instance.client;

  // Singleton pattern
  static final LoyaltyService _instance = LoyaltyService._internal();
  factory LoyaltyService() => _instance;
  LoyaltyService._internal();

  /// Calculate points based on a rule: e.g. 1 point per 100 units
  int calculateLoyaltyPoints(double purchaseAmount,
      {double pointsPerUnit = 1.0}) {
    return (purchaseAmount / 100 * pointsPerUnit).floor();
  }

  /// Award points and recalculate loyalty tier
  Future<void> awardPoints(String customerId, int points,
      {String? saleId}) async {
    if (points <= 0) return;

    // Fetch current customer to update points and tier
    final customerResp =
        await _client.from('customers').select().eq('id', customerId).single();
    final currentPoints = customerResp['loyalty_points'] as int? ?? 0;
    final newPoints = currentPoints + points;

    // Evaluate tier
    String newTier = 'bronze';
    if (newPoints >= 5000) {
      newTier = 'platinum';
    } else if (newPoints >= 2000) {
      newTier = 'gold';
    } else if (newPoints >= 500) {
      newTier = 'silver';
    }

    final updates = {
      'loyalty_points': newPoints,
      'loyalty_tier': newTier,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client.from('customers').update(updates).eq('id', customerId);

    // If saleId is provided, we can log this somewhere if we had a loyalty_ledger,
    // but schema hasn't specified one yet.
  }

  Future<int> getCustomerLoyaltyBalance(String customerId) async {
    final response = await _client
        .from('customers')
        .select('loyalty_points')
        .eq('id', customerId)
        .single();
    return response['loyalty_points'] as int? ?? 0;
  }

  Future<List<Order>> getPurchaseHistory(String customerId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('customer_id', customerId)
        .eq('order_status', 'completed')
        .order('created_at', ascending: false);
    return List<Order>.from(response.map((x) => Order.fromJson(x)));
  }

  Future<Map<String, dynamic>> getCustomerAnalytics(String customerId) async {
    final response = await _client
        .from('customers')
        .select(
            'total_purchases, purchase_count, last_purchase_at, loyalty_points, loyalty_tier')
        .eq('id', customerId)
        .single();

    // Additional analytics: average order value
    final totalPurchases =
        (response['total_purchases'] as num?)?.toDouble() ?? 0.0;
    final purchaseCount = response['purchase_count'] as int? ?? 0;
    final aov = purchaseCount > 0 ? (totalPurchases / purchaseCount) : 0.0;

    return {
      'totalPurchases': totalPurchases,
      'purchaseCount': purchaseCount,
      'lastPurchaseAt': response['last_purchase_at'],
      'loyaltyPoints': response['loyalty_points'],
      'loyaltyTier': response['loyalty_tier'],
      'averageOrderValue': aov,
    };
  }
}
