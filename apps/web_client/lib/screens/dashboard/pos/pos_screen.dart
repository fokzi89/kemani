import 'package:flutter/material.dart';
import '../../../widgets/pos/product_grid.dart';
import '../../../widgets/pos/product_data.dart';
import '../../../services/product_service.dart';
import '../../../services/sale_service.dart';
import '../../../theme.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProductService _productService = ProductService();
  final SaleService _saleService = SaleService();
  bool _processingPayment = false;

  String _selectedCategory = 'All';
  List<ProductData> _products = [];
  List<Map<String, dynamic>> _categoryData = [
    {'name': 'All', 'count': 0},
  ];
  bool _isLoading = true;
  String? _error;

  // Cart State
  final Map<String, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _productService.getProductsForCurrentUser();

      if (mounted) {
        setState(() {
          _products = products.map((p) => ProductData.fromProduct(p)).toList();
          _categoryData = ProductService.getCategoryData(products);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _addToCart(ProductData product) {
    setState(() {
      _cart[product.id] = (_cart[product.id] ?? 0) + 1;
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      if (_cart.containsKey(productId)) {
        if (_cart[productId]! > 1) {
          _cart[productId] = _cart[productId]! - 1;
        } else {
          _cart.remove(productId);
        }
      }
    });
  }

  double get _subtotal {
    double total = 0;
    _cart.forEach((key, quantity) {
      final product = _products.firstWhere((p) => p.id == key);
      total += product.price * quantity;
    });
    return total;
  }

  double get _tax => _subtotal * 0.075; // 7.5% VAT
  double get _totalAmount => _subtotal + _tax;

  int get _cartItemCount {
    int count = 0;
    _cart.forEach((_, qty) => count += qty);
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter products by search and category
    final filteredProducts = _products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );
      final matchesCategory =
          _selectedCategory == 'All' ||
          (p.category ?? 'Uncategorized') == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Row(
      children: [
        // Main Content (Products)
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // Top bar: Category tabs + Search + Refresh
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    // Category chips with counts
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categoryData.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = _categoryData[index];
                            final isSelected = cat['name'] == _selectedCategory;
                            return ChoiceChip(
                              label: Text('${cat['name']}  ${cat['count']}'),
                              selected: isSelected,
                              onSelected: (_) => setState(
                                () => _selectedCategory = cat['name'],
                              ),
                              selectedColor: theme.colorScheme.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : null,
                                fontWeight: isSelected ? FontWeight.bold : null,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              showCheckmark: false,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Refresh button
                    IconButton(
                      onPressed: _loadProducts,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Products',
                    ),
                    // Search
                    SizedBox(
                      width: 200,
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search Products',
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
                    if (!isDesktop) ...[
                      const SizedBox(width: 8),
                      Badge(
                        label: Text('$_cartItemCount'),
                        isLabelVisible: _cartItemCount > 0,
                        child: IconButton(
                          icon: const Icon(Icons.shopping_cart),
                          onPressed: () => _showMobileCart(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Product Grid / Loading / Error / Empty
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load products',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadProducts,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: isDark
                                  ? AppColors.darkMutedForeground
                                  : AppColors.lightMutedForeground,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _products.isEmpty
                                  ? 'No products yet'
                                  : 'No products match your search',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _products.isEmpty
                                  ? 'Add products to your inventory to start selling'
                                  : 'Try a different search term or category',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.darkMutedForeground
                                    : AppColors.lightMutedForeground,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ProductGrid(
                        products: filteredProducts,
                        onProductSelected: _addToCart,
                      ),
              ),
            ],
          ),
        ),

        // Desktop Order Summary sidebar
        if (isDesktop) _buildOrderSummary(theme, isDark),
      ],
    );
  }

  Widget _buildOrderSummary(ThemeData theme, bool isDark) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark
        ? AppColors.darkForeground
        : AppColors.lightForeground;
    final mutedColor = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(left: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Summary',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_cart.isNotEmpty)
                  Text(
                    '#B${DateTime.now().millisecondsSinceEpoch % 100000}',
                    style: TextStyle(color: mutedColor, fontSize: 12),
                  ),
              ],
            ),
          ),
          Divider(color: borderColor, height: 1),

          // Cart Items
          Expanded(
            child: _cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: mutedColor.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No items yet',
                          style: TextStyle(color: mutedColor),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final productId = _cart.keys.elementAt(index);
                      final quantity = _cart[productId]!;
                      final product = _products.firstWhere(
                        (p) => p.id == productId,
                      );

                      return _OrderItem(
                        name: product.name,
                        quantity: quantity,
                        price: product.price,
                        onIncrement: () => _addToCart(product),
                        onDecrement: () => _removeFromCart(productId),
                        textColor: textColor,
                        mutedColor: mutedColor,
                        borderColor: borderColor,
                      );
                    },
                  ),
          ),

          // Totals
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.05),
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Column(
              children: [
                _totalRow(
                  'Subtotal',
                  '₦${_subtotal.toStringAsFixed(0)}',
                  labelColor: mutedColor,
                  valueColor: textColor,
                ),
                const SizedBox(height: 6),
                _totalRow(
                  'Taxes (7.5%)',
                  '₦${_tax.toStringAsFixed(0)}',
                  labelColor: mutedColor,
                  valueColor: textColor,
                ),
                const SizedBox(height: 6),
                _totalRow(
                  'Discount',
                  '-₦0',
                  labelColor: mutedColor,
                  valueColor: AppColors.lightAccent,
                ),
                Divider(color: borderColor, height: 20),
                _totalRow(
                  'Total Payment',
                  '₦${_totalAmount.toStringAsFixed(0)}',
                  isBold: true,
                  fontSize: 18,
                  labelColor: textColor,
                  valueColor: textColor,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _cart.isEmpty || _processingPayment
                        ? null
                        : () => _showPaymentDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Confirm Payment',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 13,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showMobileCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: _buildOrderSummary(theme, isDark),
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context) {
    String selectedMethod = 'cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Complete Payment'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: ₦${_totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_cartItemCount} item${_cartItemCount == 1 ? '' : 's'} · '
                  'Tax: ₦${_tax.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Payment Method',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...['cash', 'card', 'bank_transfer', 'mobile_money'].map((
                  method,
                ) {
                  final labels = {
                    'cash': 'Cash',
                    'card': 'Card',
                    'bank_transfer': 'Bank Transfer',
                    'mobile_money': 'Mobile Money',
                  };
                  final icons = {
                    'cash': Icons.money,
                    'card': Icons.credit_card,
                    'bank_transfer': Icons.account_balance,
                    'mobile_money': Icons.phone_android,
                  };
                  return RadioListTile<String>(
                    value: method,
                    groupValue: selectedMethod,
                    title: Text(labels[method]!),
                    secondary: Icon(icons[method]),
                    dense: true,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedMethod = val);
                      }
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _processPayment(selectedMethod);
              },
              icon: const Icon(Icons.check),
              label: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(String paymentMethod) async {
    setState(() => _processingPayment = true);

    try {
      // Build line items from cart
      final items = _cart.entries.map((entry) {
        final product = _products.firstWhere((p) => p.id == entry.key);
        return {
          'product_id': product.id,
          'product_name': product.name,
          'quantity': entry.value,
          'unit_price': product.price,
        };
      }).toList();

      final result = await _saleService.createSale(
        items: items,
        paymentMethod: paymentMethod,
      );

      if (mounted) {
        setState(() {
          _cart.clear();
          _processingPayment = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Sale ${result['sale_number']} completed successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Order item for the sidebar
class _OrderItem extends StatelessWidget {
  final String name;
  final int quantity;
  final double price;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Color textColor;
  final Color mutedColor;
  final Color borderColor;

  const _OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.onIncrement,
    required this.onDecrement,
    required this.textColor,
    required this.mutedColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.4))),
      ),
      child: Row(
        children: [
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name ($quantity)',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₦${price.toStringAsFixed(0)}',
                  style: TextStyle(color: mutedColor, fontSize: 12),
                ),
              ],
            ),
          ),
          // Total
          Text(
            '₦${(price * quantity).toStringAsFixed(0)}',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          // Edit controls
          InkWell(
            onTap: onDecrement,
            child: Icon(
              Icons.remove_circle_outline,
              size: 18,
              color: mutedColor,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onIncrement,
            child: Icon(
              Icons.add_circle_outline,
              size: 18,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
