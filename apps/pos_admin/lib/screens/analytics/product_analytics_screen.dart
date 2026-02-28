import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/analytics_service.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';

class ProductAnalyticsScreen extends StatefulWidget {
  const ProductAnalyticsScreen({super.key});

  @override
  State<ProductAnalyticsScreen> createState() => _ProductAnalyticsScreenState();
}

class _ProductAnalyticsScreenState extends State<ProductAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final ProductService _productService = ProductService();

  TimePeriod _selectedPeriod = TimePeriod.monthly;
  Product? _selectedProduct;
  List<Product> _products = [];
  List<SalesTrendData> _trendData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productService.listProducts(limit: 100);
      if (mounted) {
        setState(() {
          _products = products;
          if (products.isNotEmpty) {
            _selectedProduct = products.first;
            _loadTrendData();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTrendData() async {
    if (_selectedProduct == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await _analyticsService.getProductSalesTrend(
        productId: _selectedProduct!.id,
        period: _selectedPeriod,
      );

      if (mounted) {
        setState(() => _trendData = data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case TimePeriod.daily:
        return 'Daily';
      case TimePeriod.weekly:
        return 'Weekly';
      case TimePeriod.monthly:
        return 'Monthly';
      case TimePeriod.quarterly:
        return 'Quarterly';
      case TimePeriod.annually:
        return 'Annually';
      case TimePeriod.custom:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Analytics'),
      ),
      body: _isLoading && _products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Product',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Product>(
                            value: _selectedProduct,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: _products.map((product) {
                              return DropdownMenuItem(
                                value: product,
                                child: Text(product.name),
                              );
                            }).toList(),
                            onChanged: (product) {
                              setState(() => _selectedProduct = product);
                              _loadTrendData();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Period Selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Time Period',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _PeriodChip(
                                label: 'Weekly',
                                isSelected: _selectedPeriod == TimePeriod.weekly,
                                onTap: () {
                                  setState(() => _selectedPeriod = TimePeriod.weekly);
                                  _loadTrendData();
                                },
                              ),
                              _PeriodChip(
                                label: 'Monthly',
                                isSelected: _selectedPeriod == TimePeriod.monthly,
                                onTap: () {
                                  setState(() => _selectedPeriod = TimePeriod.monthly);
                                  _loadTrendData();
                                },
                              ),
                              _PeriodChip(
                                label: 'Quarterly',
                                isSelected: _selectedPeriod == TimePeriod.quarterly,
                                onTap: () {
                                  setState(() => _selectedPeriod = TimePeriod.quarterly);
                                  _loadTrendData();
                                },
                              ),
                              _PeriodChip(
                                label: 'Annually',
                                isSelected: _selectedPeriod == TimePeriod.annually,
                                onTap: () {
                                  setState(() => _selectedPeriod = TimePeriod.annually);
                                  _loadTrendData();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_selectedProduct != null) ...[
                    // Summary Stats
                    Text(
                      '${_selectedProduct!.name} - ${_getPeriodLabel()} Sales',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    _SummaryCards(trendData: _trendData),
                    const SizedBox(height: 24),

                    // Revenue Line Chart
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Revenue Trend',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 300,
                              child: _trendData.isEmpty
                                  ? const Center(
                                      child: Text('No sales data available'),
                                    )
                                  : _RevenueLineChart(trendData: _trendData),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Volume Bar Chart
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sales Volume',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 300,
                              child: _trendData.isEmpty
                                  ? const Center(
                                      child: Text('No sales data available'),
                                    )
                                  : _VolumeBarChart(trendData: _trendData),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final List<SalesTrendData> trendData;

  const _SummaryCards({required this.trendData});

  @override
  Widget build(BuildContext context) {
    final totalRevenue = trendData.fold<double>(
      0.0,
      (sum, data) => sum + data.revenue,
    );
    final totalVolume = trendData.fold<int>(
      0,
      (sum, data) => sum + data.volume,
    );
    final avgPrice = totalVolume > 0 ? totalRevenue / totalVolume : 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Total Revenue',
          value: 'NGN ${totalRevenue.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: Colors.green,
        ),
        _StatCard(
          title: 'Units Sold',
          value: totalVolume.toString(),
          icon: Icons.shopping_cart,
          color: Colors.blue,
        ),
        _StatCard(
          title: 'Avg Price',
          value: 'NGN ${avgPrice.toStringAsFixed(2)}',
          icon: Icons.trending_up,
          color: Colors.orange,
        ),
        _StatCard(
          title: 'Periods',
          value: trendData.length.toString(),
          icon: Icons.calendar_today,
          color: Colors.purple,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueLineChart extends StatelessWidget {
  final List<SalesTrendData> trendData;

  const _RevenueLineChart({required this.trendData});

  @override
  Widget build(BuildContext context) {
    final spots = trendData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.revenue);
    }).toList();

    final maxRevenue = trendData.fold<double>(
      0.0,
      (max, data) => data.revenue > max ? data.revenue : max,
    );

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  'NGN ${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < trendData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      trendData[index].periodLabel,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        minY: 0,
        maxY: maxRevenue * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeBarChart extends StatelessWidget {
  final List<SalesTrendData> trendData;

  const _VolumeBarChart({required this.trendData});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < trendData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      trendData[index].periodLabel,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        barGroups: trendData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.volume.toDouble(),
                color: Colors.blue,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
