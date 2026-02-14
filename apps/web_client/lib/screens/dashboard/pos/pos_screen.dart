import 'package:flutter/material.dart';
import '../../../widgets/pos/product_grid.dart';
import '../../../widgets/pos/pos_search_bar.dart';
import '../../../widgets/pos/category_selector.dart';
import '../../../widgets/pos/ticket_item.dart';
import '../../../widgets/pos/product_data.dart';
import '../../../theme.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  // Mock categories with counts
  final List<Map<String, dynamic>> _categoryData = [
    {'name': 'All', 'count': 43},
    {'name': 'Pain Relief', 'count': 16},
    {'name': 'Antibiotics', 'count': 11},
    {'name': 'Vitamins', 'count': 8},
    {'name': 'First Aid', 'count': 6},
    {'name': 'Skincare', 'count': 2},
  ];

  final List<ProductData> _products = [
    ProductData(id: '1', name: 'Paracetamol 500mg', price: 500, stock: 120),
    ProductData(id: '2', name: 'Amoxicillin 500mg', price: 1500, stock: 45),
    ProductData(id: '3', name: 'Vitamin C 1000mg', price: 2000, stock: 8),
    ProductData(id: '4', name: 'Bandage Roll', price: 300, stock: 50),
    ProductData(id: '5', name: 'Ibuprofen 400mg', price: 800, stock: 200),
    ProductData(id: '6', name: 'Antiseptic Liquid', price: 1200, stock: 15),
    ProductData(id: '7', name: 'Cough Syrup', price: 1800, stock: 25),
    ProductData(id: '8', name: 'Face Mask (Pack)', price: 2500, stock: 0),
    ProductData(id: '9', name: 'Hand Sanitizer', price: 1000, stock: 60),
    ProductData(id: '10', name: 'Thermometer', price: 5000, stock: 12),
    ProductData(id: '11', name: 'Diclofenac Gel', price: 900, stock: 30),
    ProductData(id: '12', name: 'Multivitamins', price: 3500, stock: 0),
  ];

  // Cart State
  final Map<String, int> _cart = {};

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

    // Filter products
    final filteredProducts = _products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );
      final matchesCategory = _selectedCategory == 'All';
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
                      onPressed: () {},
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
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
                          hintText: 'Search Menu',
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

              // Product Grid
              Expanded(
                child: ProductGrid(
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
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFF1E293B),
        border: Border(
          left: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
        ),
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
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_cart.isNotEmpty)
                  Text(
                    '#B${DateTime.now().millisecondsSinceEpoch % 100000}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

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
                          color: Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No items yet',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                          ),
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
                      );
                    },
                  ),
          ),

          // Totals
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              border: const Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                _totalRow('Subtotal', '₦${_subtotal.toStringAsFixed(0)}'),
                const SizedBox(height: 6),
                _totalRow('Taxes (7.5%)', '₦${_tax.toStringAsFixed(0)}'),
                const SizedBox(height: 6),
                _totalRow('Discount', '-₦0', color: AppColors.lightAccent),
                const Divider(color: Colors.white24, height: 20),
                _totalRow(
                  'Total Payment',
                  '₦${_totalAmount.toStringAsFixed(0)}',
                  isBold: true,
                  fontSize: 18,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _cart.isEmpty ? null : () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightPrimary,
                      foregroundColor: Colors.white,
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
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
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
}

// Order item for the dark sidebar
class _OrderItem extends StatelessWidget {
  final String name;
  final int quantity;
  final double price;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₦${price.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Total
          Text(
            '₦${(price * quantity).toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
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
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onIncrement,
            child: const Icon(
              Icons.add_circle_outline,
              size: 18,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
