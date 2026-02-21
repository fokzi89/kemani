import 'package:flutter/material.dart';
import '../../../services/sale_service.dart';
import '../../../theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final SaleService _saleService = SaleService();
  List<Map<String, dynamic>> _sales = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final sales = await _saleService.getSales(limit: 100);
      if (mounted) {
        setState(() {
          _sales = sales;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading sales: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredSales {
    return _sales.where((sale) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          (sale['sale_number'] ?? '').toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesStatus =
          _statusFilter == 'all' || (sale['status'] ?? '') == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month]} ${dt.day}, ${dt.year} · ${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $amPm';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatPaymentMethod(String? method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'mobile_money':
        return 'Mobile Money';
      default:
        return method ?? '-';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'voided':
        return Colors.red;
      case 'refunded':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'voided':
        return 'Voided';
      case 'refunded':
        return 'Refunded';
      default:
        return status ?? 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final filtered = _filteredSales;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales & Orders',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_sales.length} total sales · ${_sales.where((s) => s['status'] == 'completed').length} completed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.lightMutedForeground,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Status filter
                  SizedBox(
                    width: 140,
                    height: 40,
                    child: DropdownButtonFormField<String>(
                      value: _statusFilter,
                      isDense: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'voided',
                          child: Text('Voided'),
                        ),
                        DropdownMenuItem(
                          value: 'refunded',
                          child: Text('Refunded'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _statusFilter = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Search
                  SizedBox(
                    width: 220,
                    height: 40,
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search by sale #...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _loadSales,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Summary Cards
          _buildSummaryCards(theme, isDark),

          const SizedBox(height: 20),

          // Sales Table / List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? _buildEmptyState(theme, isDark)
                : isDesktop
                ? SingleChildScrollView(
                    child: _buildSalesTable(filtered, theme, isDark),
                  )
                : _buildSalesList(filtered, theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme, bool isDark) {
    final completedSales = _sales
        .where((s) => s['status'] == 'completed')
        .toList();
    final totalRevenue = completedSales.fold<double>(
      0,
      (sum, s) => sum + ((s['total_amount'] as num?)?.toDouble() ?? 0),
    );
    final todaySales = completedSales.where((s) {
      try {
        final dt = DateTime.parse(s['created_at']).toLocal();
        final today = DateTime.now();
        return dt.year == today.year &&
            dt.month == today.month &&
            dt.day == today.day;
      } catch (_) {
        return false;
      }
    }).toList();
    final todayRevenue = todaySales.fold<double>(
      0,
      (sum, s) => sum + ((s['total_amount'] as num?)?.toDouble() ?? 0),
    );

    return Row(
      children: [
        _SummaryCard(
          icon: Icons.receipt_long,
          label: 'Total Sales',
          value: '${completedSales.length}',
          iconColor: theme.colorScheme.primary,
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          icon: Icons.attach_money,
          label: 'Total Revenue',
          value: '₦${totalRevenue.toStringAsFixed(0)}',
          iconColor: Colors.green,
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          icon: Icons.today,
          label: 'Today\'s Sales',
          value: '${todaySales.length}',
          iconColor: Colors.blue,
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          icon: Icons.trending_up,
          label: 'Today\'s Revenue',
          value: '₦${todayRevenue.toStringAsFixed(0)}',
          iconColor: Colors.amber[700]!,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: isDark
                ? AppColors.darkMutedForeground
                : AppColors.lightMutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            _sales.isEmpty ? 'No sales yet' : 'No sales match your filters',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _sales.isEmpty
                ? 'Complete a sale in the POS to see it here'
                : 'Try a different search or filter',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.lightMutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTable(
    List<Map<String, dynamic>> sales,
    ThemeData theme,
    bool isDark,
  ) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: DataTable(
        headingRowColor: WidgetStateProperty.resolveWith(
          (_) => isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.grey.withOpacity(0.06),
        ),
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Sale #')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Items')),
          DataColumn(label: Text('Payment')),
          DataColumn(label: Text('Subtotal'), numeric: true),
          DataColumn(label: Text('Tax'), numeric: true),
          DataColumn(label: Text('Total'), numeric: true),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: sales.map((sale) {
          final items = sale['sale_items'] as List<dynamic>? ?? [];
          final status = sale['status'] as String?;
          final sColor = _statusColor(status);

          return DataRow(
            cells: [
              DataCell(
                Text(
                  sale['sale_number'] ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              DataCell(
                Text(
                  _formatDate(sale['created_at']),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              DataCell(
                Text('${items.length} item${items.length == 1 ? '' : 's'}'),
              ),
              DataCell(Text(_formatPaymentMethod(sale['payment_method']))),
              DataCell(
                Text(
                  '₦${((sale['subtotal'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                ),
              ),
              DataCell(
                Text(
                  '₦${((sale['tax_amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                ),
              ),
              DataCell(
                Text(
                  '₦${((sale['total_amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: sColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: sColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: 'View Details',
                      onPressed: () => _showSaleDetails(sale, theme, isDark),
                    ),
                    if (status == 'completed')
                      IconButton(
                        icon: Icon(
                          Icons.cancel_outlined,
                          size: 18,
                          color: theme.colorScheme.error,
                        ),
                        tooltip: 'Void Sale',
                        onPressed: () => _confirmVoid(sale),
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSalesList(
    List<Map<String, dynamic>> sales,
    ThemeData theme,
    bool isDark,
  ) {
    return ListView.builder(
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        final items = sale['sale_items'] as List<dynamic>? ?? [];
        final status = sale['status'] as String?;
        final sColor = _statusColor(status);

        return Card(
          elevation: 0,
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.5,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sale['sale_number'] ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: sColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: sColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${items.length} items · ${_formatPaymentMethod(sale['payment_method'])}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.lightMutedForeground,
                    ),
                  ),
                  Text(
                    '₦${((sale['total_amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Text(
              _formatDate(sale['created_at']).split(' · ').first,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.lightMutedForeground,
                fontSize: 11,
              ),
            ),
            onTap: () => _showSaleDetails(sale, theme, isDark),
          ),
        );
      },
    );
  }

  void _showSaleDetails(
    Map<String, dynamic> sale,
    ThemeData theme,
    bool isDark,
  ) {
    final items = sale['sale_items'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sale ${sale['sale_number']}'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(sale['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _statusLabel(sale['status']),
                style: TextStyle(
                  color: _statusColor(sale['status']),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Meta info
                _detailRow('Date', _formatDate(sale['created_at'])),
                _detailRow(
                  'Payment',
                  _formatPaymentMethod(sale['payment_method']),
                ),
                if (sale['payment_reference'] != null)
                  _detailRow('Reference', sale['payment_reference']),
                const Divider(height: 24),

                // Items
                Text(
                  'Items',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...items.map((item) {
                  final qty = item['quantity'] ?? 0;
                  final price = (item['unit_price'] as num?)?.toDouble() ?? 0;
                  final sub = (item['subtotal'] as num?)?.toDouble() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['product_name']} × $qty',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '₦${sub.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24),

                // Totals
                _detailRow(
                  'Subtotal',
                  '₦${((sale['subtotal'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                ),
                _detailRow(
                  'Tax',
                  '₦${((sale['tax_amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                ),
                _detailRow(
                  'Discount',
                  '-₦${((sale['discount_amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₦${((sale['total_amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _confirmVoid(Map<String, dynamic> sale) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Sale'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to void sale ${sale['sale_number']}?',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for voiding',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              try {
                await _saleService.voidSale(sale['id'], reason);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadSales();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sale voided successfully'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Void Sale'),
          ),
        ],
      ),
    );
  }
}

/// Summary card widget
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isDark;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.lightMutedForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
