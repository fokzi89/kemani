import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/transaction_service.dart';
import '../../models/sale.dart';
import '../../providers/tenant_provider.dart';

// Provider for TransactionService (Sales)
final salesServiceProvider = Provider((ref) => TransactionService());

// Provider for fetching recent sales for analytics
final recentSalesProvider = FutureProvider.autoDispose<List<Sale>>((ref) async {
  final tenantAsync = ref.watch(tenantProvider);
  if (!tenantAsync.hasValue || tenantAsync.value?.tenant == null) {
    return [];
  }

  final tenantId = tenantAsync.value!.tenant!.id;
  // Fetch last 30 days or so. Since getSales isn't filtered by date, we might fetch all and filter in memory for MVP
  // Ideally we should have date range query support
  return ref.read(salesServiceProvider).getSales(tenantId);
});

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(recentSalesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            salesAsync.when(
              data: (sales) {
                if (sales.isEmpty) {
                  return const Center(child: Text('No sales data available'));
                }

                // Calculate Total Revenue
                final totalRevenue = sales.fold<double>(
                  0,
                  (sum, sale) => sum + sale.totalAmount,
                );
                final totalOrders = sales.length;
                final avgOrderValue = totalOrders > 0
                    ? totalRevenue / totalOrders
                    : 0.0;

                return Column(
                  children: [
                    // KPI Cards
                    Row(
                      children: [
                        _buildKpiCard(
                          'Total Revenue',
                          '\$${totalRevenue.toStringAsFixed(2)}',
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildKpiCard(
                          'Total Orders',
                          '$totalOrders',
                          Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildKpiCard(
                          'Avg Order Value',
                          '\$${avgOrderValue.toStringAsFixed(2)}',
                          Colors.orange,
                        ),
                        // Placeholder
                        const SizedBox(width: 8),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sales Chart
                    const Text(
                      'Sales Trend (Recent)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                              ), // Hide dates for simplicity now
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _generateSpots(sales),
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots(List<Sale> sales) {
    // Sort sales by date
    sales.sort(
      (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
        b.createdAt ?? DateTime.now(),
      ),
    );

    // Create spots based on cumulative sequence or time
    // For simplicity, x-axis is index, y-axis is daily total or individual sale amount
    // Let's do individual sale amount for now to show trend
    // Grouping by day would be better but requires more logic

    return List.generate(sales.length, (index) {
      final amount = sales[index].totalAmount;
      return FlSpot(index.toDouble(), amount);
    });
  }
}
