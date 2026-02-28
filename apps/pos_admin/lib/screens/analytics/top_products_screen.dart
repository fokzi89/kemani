import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/analytics_service.dart';

class TopProductsScreen extends StatefulWidget {
  const TopProductsScreen({super.key});

  @override
  State<TopProductsScreen> createState() => _TopProductsScreenState();
}

class _TopProductsScreenState extends State<TopProductsScreen>
    with SingleTickerProviderStateMixin {
  final AnalyticsService _analyticsService = AnalyticsService();

  late TabController _tabController;
  TimePeriod _selectedPeriod = TimePeriod.monthly;
  List<TopProduct> _topByVolume = [];
  List<TopProduct> _topByValue = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTopProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTopProducts() async {
    setState(() => _isLoading = true);
    try {
      final volumeData = await _analyticsService.getTopProductsByVolume(
        period: _selectedPeriod,
        limit: 10,
      );

      final valueData = await _analyticsService.getTopProductsByValue(
        period: _selectedPeriod,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _topByVolume = volumeData;
          _topByValue = valueData;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading top products: $e')),
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
        return 'This Week';
      case TimePeriod.weekly:
        return 'Last 12 Weeks';
      case TimePeriod.monthly:
        return 'Last 12 Months';
      case TimePeriod.quarterly:
        return 'Last 8 Quarters';
      case TimePeriod.annually:
        return 'Last 5 Years';
      case TimePeriod.custom:
        return 'Custom Period';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Selling Products'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'By Volume', icon: Icon(Icons.shopping_cart)),
            Tab(text: 'By Revenue', icon: Icon(Icons.attach_money)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period Selector
          Container(
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
                      label: 'This Week',
                      isSelected: _selectedPeriod == TimePeriod.daily,
                      onTap: () {
                        setState(() => _selectedPeriod = TimePeriod.daily);
                        _loadTopProducts();
                      },
                    ),
                    _PeriodChip(
                      label: 'This Month',
                      isSelected: _selectedPeriod == TimePeriod.weekly,
                      onTap: () {
                        setState(() => _selectedPeriod = TimePeriod.weekly);
                        _loadTopProducts();
                      },
                    ),
                    _PeriodChip(
                      label: 'This Year',
                      isSelected: _selectedPeriod == TimePeriod.monthly,
                      onTap: () {
                        setState(() => _selectedPeriod = TimePeriod.monthly);
                        _loadTopProducts();
                      },
                    ),
                    _PeriodChip(
                      label: 'All Time',
                      isSelected: _selectedPeriod == TimePeriod.annually,
                      onTap: () {
                        setState(() => _selectedPeriod = TimePeriod.annually);
                        _loadTopProducts();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // Tab Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // By Volume Tab
                      _TopProductsList(
                        products: _topByVolume,
                        showVolume: true,
                        periodLabel: _getPeriodLabel(),
                      ),

                      // By Value Tab
                      _TopProductsList(
                        products: _topByValue,
                        showVolume: false,
                        periodLabel: _getPeriodLabel(),
                      ),
                    ],
                  ),
          ),
        ],
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

class _TopProductsList extends StatelessWidget {
  final List<TopProduct> products;
  final bool showVolume;
  final String periodLabel;

  const _TopProductsList({
    required this.products,
    required this.showVolume,
    required this.periodLabel,
  });

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return Icons.trending_up;
      case 'down':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'up':
        return Colors.green;
      case 'down':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No sales data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sales data will appear here once transactions are processed',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Title
          Text(
            showVolume
                ? 'Top 10 Products by Volume Sold ($periodLabel)'
                : 'Top 10 Products by Revenue ($periodLabel)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal Bar Chart
          SizedBox(
            height: 400,
            child: _TopProductsChart(
              products: products,
              showVolume: showVolume,
            ),
          ),
          const SizedBox(height: 24),

          // Detailed List
          ...products.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getRankColor(index).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getRankColor(index),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  product.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    if (showVolume) ...[
                      Text('${product.totalQuantity} units sold'),
                      Text(
                        'Revenue: NGN ${product.totalRevenue.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ] else ...[
                      Text('NGN ${product.totalRevenue.toStringAsFixed(2)}'),
                      Text(
                        '${product.totalQuantity} units sold',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getTrendIcon(product.trendIndicator),
                          size: 16,
                          color: _getTrendColor(product.trendIndicator),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.marketSharePercent.toStringAsFixed(1)}% market share',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${product.marketSharePercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    if (index == 0) return Colors.amber; // Gold
    if (index == 1) return Colors.grey; // Silver
    if (index == 2) return Colors.brown; // Bronze
    return Colors.blue;
  }
}

class _TopProductsChart extends StatelessWidget {
  final List<TopProduct> products;
  final bool showVolume;

  const _TopProductsChart({
    required this.products,
    required this.showVolume,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = products.fold<double>(
      0.0,
      (max, product) {
        final value = showVolume
            ? product.totalQuantity.toDouble()
            : product.totalRevenue;
        return value > max ? value : max;
      },
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  showVolume
                      ? value.toInt().toString()
                      : 'NGN ${(value / 1000).toStringAsFixed(0)}k',
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
                if (index >= 0 && index < products.length) {
                  final name = products[index].productName;
                  final truncated = name.length > 10
                      ? '${name.substring(0, 10)}...'
                      : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      truncated,
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
        barGroups: products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          final value = showVolume
              ? product.totalQuantity.toDouble()
              : product.totalRevenue;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: _getBarColor(index),
                width: 20,
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

  Color _getBarColor(int index) {
    if (index == 0) return Colors.amber; // Gold
    if (index == 1) return Colors.grey; // Silver
    if (index == 2) return Colors.brown; // Bronze
    return Colors.blue;
  }
}
