import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/analytics_service.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';

class ProductComparisonScreen extends StatefulWidget {
  const ProductComparisonScreen({super.key});

  @override
  State<ProductComparisonScreen> createState() =>
      _ProductComparisonScreenState();
}

class _ProductComparisonScreenState extends State<ProductComparisonScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final ProductService _productService = ProductService();

  List<Product> _allProducts = [];
  List<String> _categories = [];
  String? _selectedCategory;
  List<Product> _selectedProducts = [];
  List<ProductSalesData> _comparisonData = [];
  TimePeriod _selectedPeriod = TimePeriod.monthly;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCategories();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.listProducts(limit: 200);
      if (mounted) {
        setState(() => _allProducts = products);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _productService.getCategories();
      if (mounted) {
        setState(() => _categories = categories);
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _compareProducts() async {
    if (_selectedProducts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 products to compare'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final productIds = _selectedProducts.map((p) => p.id).toList();
      final data = await _analyticsService.compareProducts(
        productIds: productIds,
        period: _selectedPeriod,
      );

      if (mounted) {
        setState(() => _comparisonData = data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error comparing products: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Product> _getFilteredProducts() {
    if (_selectedCategory == null) return _allProducts;
    return _allProducts
        .where((p) => p.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Comparison'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter by Category
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter by Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'All Categories',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ..._categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                          _selectedProducts.clear();
                          _comparisonData.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Product Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Products to Compare',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_selectedProducts.length}/10 selected',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: _getFilteredProducts().length,
                        itemBuilder: (context, index) {
                          final product = _getFilteredProducts()[index];
                          final isSelected =
                              _selectedProducts.any((p) => p.id == product.id);

                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(product.name),
                            subtitle: Text(
                              product.category ?? 'No category',
                              style: const TextStyle(fontSize: 12),
                            ),
                            secondary: Text(
                              'NGN ${product.unitPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  if (_selectedProducts.length < 10) {
                                    _selectedProducts.add(product);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Maximum 10 products can be compared',
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  _selectedProducts.removeWhere(
                                    (p) => p.id == product.id,
                                  );
                                }
                                _comparisonData.clear();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time Period Selector
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
                          },
                        ),
                        _PeriodChip(
                          label: 'Monthly',
                          isSelected: _selectedPeriod == TimePeriod.monthly,
                          onTap: () {
                            setState(() => _selectedPeriod = TimePeriod.monthly);
                          },
                        ),
                        _PeriodChip(
                          label: 'Quarterly',
                          isSelected: _selectedPeriod == TimePeriod.quarterly,
                          onTap: () {
                            setState(() => _selectedPeriod = TimePeriod.quarterly);
                          },
                        ),
                        _PeriodChip(
                          label: 'Annually',
                          isSelected: _selectedPeriod == TimePeriod.annually,
                          onTap: () {
                            setState(() => _selectedPeriod = TimePeriod.annually);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Compare Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _compareProducts,
                icon: const Icon(Icons.compare_arrows),
                label: _isLoading
                    ? const Text('Comparing...')
                    : const Text('Compare Products'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Comparison Results
            if (_comparisonData.isNotEmpty) ...[
              const Text(
                'Comparison Results',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Volume Comparison Chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sales Volume Comparison',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: _VolumeComparisonChart(data: _comparisonData),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Revenue Comparison Chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revenue Comparison',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: _RevenueComparisonChart(data: _comparisonData),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Detailed Comparison Table
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detailed Metrics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _ComparisonTable(data: _comparisonData),
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

class _VolumeComparisonChart extends StatelessWidget {
  final List<ProductSalesData> data;

  const _VolumeComparisonChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
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
                if (index >= 0 && index < data.length) {
                  final name = data[index].productName;
                  final truncated =
                      name.length > 10 ? '${name.substring(0, 10)}...' : name;
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
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.totalQuantity.toDouble(),
                color: Colors.blue,
                width: 30,
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

class _RevenueComparisonChart extends StatelessWidget {
  final List<ProductSalesData> data;

  const _RevenueComparisonChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  'NGN ${(value / 1000).toStringAsFixed(0)}k',
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
                if (index >= 0 && index < data.length) {
                  final name = data[index].productName;
                  final truncated =
                      name.length > 10 ? '${name.substring(0, 10)}...' : name;
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
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.totalRevenue,
                color: Colors.green,
                width: 30,
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

class _ComparisonTable extends StatelessWidget {
  final List<ProductSalesData> data;

  const _ComparisonTable({required this.data});

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Product')),
        DataColumn(label: Text('Units Sold')),
        DataColumn(label: Text('Revenue')),
        DataColumn(label: Text('Avg Price')),
        DataColumn(label: Text('Profit Margin')),
      ],
      rows: data.map((item) {
        return DataRow(cells: [
          DataCell(Text(item.productName)),
          DataCell(Text(item.totalQuantity.toString())),
          DataCell(Text('NGN ${item.totalRevenue.toStringAsFixed(2)}')),
          DataCell(Text('NGN ${item.averagePrice.toStringAsFixed(2)}')),
          DataCell(
            Text('${item.profitMargin.toStringAsFixed(1)}%'),
          ),
        ]);
      }).toList(),
    );
  }
}
