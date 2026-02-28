import 'package:supabase_flutter/supabase_flutter.dart';

enum TimePeriod { daily, weekly, monthly, quarterly, annually, custom }

class ProductSalesData {
  final String productId;
  final String productName;
  final int totalQuantity;
  final double totalRevenue;
  final double averagePrice;
  final double profitMargin;
  final String? category;
  final DateTime periodStart;
  final DateTime periodEnd;

  ProductSalesData({
    required this.productId,
    required this.productName,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.averagePrice,
    required this.profitMargin,
    this.category,
    required this.periodStart,
    required this.periodEnd,
  });

  factory ProductSalesData.fromJson(Map<String, dynamic> json) {
    return ProductSalesData(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      totalQuantity: json['total_quantity'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      averagePrice: (json['average_price'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (json['profit_margin'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String?,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
    );
  }
}

class SalesTrendData {
  final DateTime date;
  final double revenue;
  final int volume;
  final String periodLabel;

  SalesTrendData({
    required this.date,
    required this.revenue,
    required this.volume,
    required this.periodLabel,
  });
}

class TopProduct {
  final String productId;
  final String productName;
  final int totalQuantity;
  final double totalRevenue;
  final double profitContribution;
  final double marketSharePercent;
  final String trendIndicator; // 'up', 'down', 'stable'

  TopProduct({
    required this.productId,
    required this.productName,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.profitContribution,
    required this.marketSharePercent,
    required this.trendIndicator,
  });
}

class AnalyticsService {
  final SupabaseClient _client = Supabase.instance.client;

  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Get product sales over time with specified period grouping
  Future<List<SalesTrendData>> getProductSalesTrend({
    required String productId,
    required TimePeriod period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final dates = _getDateRange(period, startDate, endDate);
    final start = dates['start']!;
    final end = dates['end']!;

    // Query sale items joined with sales
    final response = await _client
        .from('sale_items')
        .select('''
          quantity,
          unit_price,
          sales!inner(
            created_at,
            tenant_id
          )
        ''')
        .eq('product_id', productId)
        .gte('sales.created_at', start.toIso8601String())
        .lte('sales.created_at', end.toIso8601String());

    // Group by period
    final Map<String, SalesTrendData> grouped = {};

    for (final item in response) {
      final createdAt = DateTime.parse(item['sales']['created_at'] as String);
      final periodKey = _getPeriodKey(createdAt, period);

      final quantity = item['quantity'] as int? ?? 0;
      final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0.0;
      final revenue = quantity * unitPrice;

      if (grouped.containsKey(periodKey)) {
        final existing = grouped[periodKey]!;
        grouped[periodKey] = SalesTrendData(
          date: existing.date,
          revenue: existing.revenue + revenue,
          volume: existing.volume + quantity,
          periodLabel: existing.periodLabel,
        );
      } else {
        grouped[periodKey] = SalesTrendData(
          date: createdAt,
          revenue: revenue,
          volume: quantity,
          periodLabel: _getPeriodLabel(createdAt, period),
        );
      }
    }

    final result = grouped.values.toList();
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  /// Get top selling products by volume
  Future<List<TopProduct>> getTopProductsByVolume({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
    TimePeriod period = TimePeriod.monthly,
  }) async {
    final dates = _getDateRange(period, startDate, endDate);
    final start = dates['start']!;
    final end = dates['end']!;

    final response = await _client.rpc('get_top_products_by_volume', params: {
      'start_date': start.toIso8601String(),
      'end_date': end.toIso8601String(),
      'product_limit': limit,
    });

    // Calculate total volume for market share
    final totalVolume = response.fold<int>(
      0,
      (sum, item) => sum + (item['total_quantity'] as int? ?? 0),
    );

    return response.map<TopProduct>((item) {
      final quantity = item['total_quantity'] as int? ?? 0;
      final revenue = (item['total_revenue'] as num?)?.toDouble() ?? 0.0;
      final profit = (item['profit'] as num?)?.toDouble() ?? 0.0;

      return TopProduct(
        productId: item['product_id'] as String,
        productName: item['product_name'] as String,
        totalQuantity: quantity,
        totalRevenue: revenue,
        profitContribution: profit,
        marketSharePercent: totalVolume > 0 ? (quantity / totalVolume) * 100 : 0,
        trendIndicator: item['trend'] as String? ?? 'stable',
      );
    }).toList();
  }

  /// Get top selling products by value (revenue)
  Future<List<TopProduct>> getTopProductsByValue({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
    TimePeriod period = TimePeriod.monthly,
  }) async {
    final dates = _getDateRange(period, startDate, endDate);
    final start = dates['start']!;
    final end = dates['end']!;

    final response = await _client.rpc('get_top_products_by_value', params: {
      'start_date': start.toIso8601String(),
      'end_date': end.toIso8601String(),
      'product_limit': limit,
    });

    // Calculate total revenue for market share
    final totalRevenue = response.fold<double>(
      0.0,
      (sum, item) => sum + ((item['total_revenue'] as num?)?.toDouble() ?? 0.0),
    );

    return response.map<TopProduct>((item) {
      final quantity = item['total_quantity'] as int? ?? 0;
      final revenue = (item['total_revenue'] as num?)?.toDouble() ?? 0.0;
      final profit = (item['profit'] as num?)?.toDouble() ?? 0.0;

      return TopProduct(
        productId: item['product_id'] as String,
        productName: item['product_name'] as String,
        totalQuantity: quantity,
        totalRevenue: revenue,
        profitContribution: profit,
        marketSharePercent: totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0,
        trendIndicator: item['trend'] as String? ?? 'stable',
      );
    }).toList();
  }

  /// Compare products in the same category or different brands
  Future<List<ProductSalesData>> compareProducts({
    required List<String> productIds,
    DateTime? startDate,
    DateTime? endDate,
    TimePeriod period = TimePeriod.monthly,
  }) async {
    final dates = _getDateRange(period, startDate, endDate);
    final start = dates['start']!;
    final end = dates['end']!;

    final results = <ProductSalesData>[];

    for (final productId in productIds) {
      final response = await _client
          .from('sale_items')
          .select('''
            quantity,
            unit_price,
            products!inner(
              id,
              name,
              category,
              cost_price
            ),
            sales!inner(
              created_at
            )
          ''')
          .eq('product_id', productId)
          .gte('sales.created_at', start.toIso8601String())
          .lte('sales.created_at', end.toIso8601String());

      if (response.isEmpty) continue;

      int totalQuantity = 0;
      double totalRevenue = 0.0;
      double totalCost = 0.0;

      for (final item in response) {
        final quantity = item['quantity'] as int? ?? 0;
        final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0.0;
        final costPrice = (item['products']['cost_price'] as num?)?.toDouble() ?? 0.0;

        totalQuantity += quantity;
        totalRevenue += quantity * unitPrice;
        totalCost += quantity * costPrice;
      }

      final profitMargin = totalRevenue > 0
          ? ((totalRevenue - totalCost) / totalRevenue) * 100
          : 0.0;

      results.add(ProductSalesData(
        productId: productId,
        productName: response.first['products']['name'] as String,
        totalQuantity: totalQuantity,
        totalRevenue: totalRevenue,
        averagePrice: totalQuantity > 0 ? totalRevenue / totalQuantity : 0.0,
        profitMargin: profitMargin,
        category: response.first['products']['category'] as String?,
        periodStart: start,
        periodEnd: end,
      ));
    }

    return results;
  }

  /// Get products by category for comparison
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    final response = await _client
        .from('products')
        .select('id, name, category')
        .eq('category', category)
        .eq('is_active', true)
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Helper: Get date range based on period
  Map<String, DateTime> _getDateRange(
    TimePeriod period,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = endDate ?? now;

    switch (period) {
      case TimePeriod.daily:
        start = startDate ?? now.subtract(const Duration(days: 30));
        break;
      case TimePeriod.weekly:
        start = startDate ?? now.subtract(const Duration(days: 12 * 7)); // 12 weeks
        break;
      case TimePeriod.monthly:
        start = startDate ?? DateTime(now.year, now.month - 12, 1); // 12 months
        break;
      case TimePeriod.quarterly:
        start = startDate ?? DateTime(now.year - 2, 1, 1); // 2 years of quarters
        break;
      case TimePeriod.annually:
        start = startDate ?? DateTime(now.year - 5, 1, 1); // 5 years
        break;
      case TimePeriod.custom:
        start = startDate ?? now.subtract(const Duration(days: 30));
        break;
    }

    return {'start': start, 'end': end};
  }

  /// Helper: Get period key for grouping
  String _getPeriodKey(DateTime date, TimePeriod period) {
    switch (period) {
      case TimePeriod.daily:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case TimePeriod.weekly:
        final weekNumber = _getWeekNumber(date);
        return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
      case TimePeriod.monthly:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case TimePeriod.quarterly:
        final quarter = ((date.month - 1) ~/ 3) + 1;
        return '${date.year}-Q$quarter';
      case TimePeriod.annually:
        return '${date.year}';
      case TimePeriod.custom:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// Helper: Get period label for display
  String _getPeriodLabel(DateTime date, TimePeriod period) {
    switch (period) {
      case TimePeriod.daily:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case TimePeriod.weekly:
        final weekNumber = _getWeekNumber(date);
        return 'Week $weekNumber, ${date.year}';
      case TimePeriod.monthly:
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[date.month - 1]} ${date.year}';
      case TimePeriod.quarterly:
        final quarter = ((date.month - 1) ~/ 3) + 1;
        return 'Q$quarter ${date.year}';
      case TimePeriod.annually:
        return '${date.year}';
      case TimePeriod.custom:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// Helper: Get week number of year
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil() + 1;
  }
}
