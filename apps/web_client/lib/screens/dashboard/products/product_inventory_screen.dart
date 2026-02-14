import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/product.dart';
import '../../../services/product_service.dart';
import '../../../theme.dart';

class ProductInventoryScreen extends StatefulWidget {
  const ProductInventoryScreen({super.key});

  @override
  State<ProductInventoryScreen> createState() => _ProductInventoryScreenState();
}

class _ProductInventoryScreenState extends State<ProductInventoryScreen> {
  final ProductService _productService = ProductService();
  final _supabase = Supabase.instance.client;

  List<Product> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _tenantId;
  String? _branchId;

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final profile = await _supabase
        .from('users')
        .select('tenant_id')
        .eq('id', user.id)
        .maybeSingle();

    _tenantId = profile?['tenant_id'];
    if (_tenantId == null) return;

    // Get first branch for this tenant
    final branch = await _supabase
        .from('branches')
        .select('id')
        .eq('tenant_id', _tenantId!)
        .limit(1)
        .maybeSingle();

    _branchId = branch?['id'];

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getProductsForCurrentUser();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (p.sku?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false) ||
              (p.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false),
        )
        .toList();
  }

  void _showAddEditDialog({Product? product}) {
    final isEditing = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    final skuCtrl = TextEditingController(text: product?.sku ?? '');
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    final categoryCtrl = TextEditingController(text: product?.category ?? '');
    final priceCtrl = TextEditingController(
      text: product?.unitPrice.toStringAsFixed(2) ?? '',
    );
    final costCtrl = TextEditingController(
      text: product?.costPrice?.toStringAsFixed(2) ?? '',
    );
    final stockCtrl = TextEditingController(
      text: product?.stockQuantity.toString() ?? '0',
    );
    final thresholdCtrl = TextEditingController(
      text: (product?.lowStockThreshold ?? 10).toString(),
    );
    final imageCtrl = TextEditingController(text: product?.imageUrl ?? '');
    bool isActive = product?.isActive ?? true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Product' : 'Add Product'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(nameCtrl, 'Product Name *', Icons.label_outline),
                  const SizedBox(height: 12),
                  _dialogField(
                    descCtrl,
                    'Description',
                    Icons.description_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _dialogField(skuCtrl, 'SKU', Icons.qr_code),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dialogField(
                          barcodeCtrl,
                          'Barcode',
                          Icons.qr_code_scanner,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    categoryCtrl,
                    'Category',
                    Icons.category_outlined,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _dialogField(
                          priceCtrl,
                          'Selling Price *',
                          Icons.attach_money,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dialogField(
                          costCtrl,
                          'Cost Price',
                          Icons.money_off,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _dialogField(
                          stockCtrl,
                          'Stock Qty *',
                          Icons.inventory,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dialogField(
                          thresholdCtrl,
                          'Low Stock Alert',
                          Icons.warning_amber,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _dialogField(imageCtrl, 'Image URL', Icons.image_outlined),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: const Text('Product is visible in POS'),
                    value: isActive,
                    onChanged: (val) => setDialogState(() => isActive = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final priceText = priceCtrl.text.trim();
                      if (name.isEmpty || priceText.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Name and Price are required'),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      final data = {
                        'name': name,
                        'description': descCtrl.text.trim().isNotEmpty
                            ? descCtrl.text.trim()
                            : null,
                        'sku': skuCtrl.text.trim().isNotEmpty
                            ? skuCtrl.text.trim()
                            : null,
                        'barcode': barcodeCtrl.text.trim().isNotEmpty
                            ? barcodeCtrl.text.trim()
                            : null,
                        'category': categoryCtrl.text.trim().isNotEmpty
                            ? categoryCtrl.text.trim()
                            : null,
                        'unit_price': double.tryParse(priceText) ?? 0,
                        'cost_price': costCtrl.text.trim().isNotEmpty
                            ? double.tryParse(costCtrl.text.trim())
                            : null,
                        'stock_quantity':
                            int.tryParse(stockCtrl.text.trim()) ?? 0,
                        'low_stock_threshold':
                            int.tryParse(thresholdCtrl.text.trim()) ?? 10,
                        'image_url': imageCtrl.text.trim().isNotEmpty
                            ? imageCtrl.text.trim()
                            : null,
                        'is_active': isActive,
                      };

                      try {
                        if (isEditing) {
                          await _productService.updateProduct(
                            product!.id,
                            data,
                          );
                        } else {
                          data['tenant_id'] = _tenantId;
                          data['branch_id'] = _branchId;
                          await _productService.createProduct(data);
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadProducts();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing ? 'Product updated' : 'Product added',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(
                            ctx,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
              icon: Icon(isEditing ? Icons.save : Icons.add),
              label: Text(
                isSaving
                    ? 'Saving...'
                    : isEditing
                    ? 'Save Changes'
                    : 'Add Product',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to deactivate "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _productService.deleteProduct(product.id);
        _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deactivated'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _filteredProducts;

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
                    'Product Inventory',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_products.length} products · ${_products.where((p) => p.stockQuantity <= (p.lowStockThreshold ?? 10)).length} low stock',
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
                  // Search
                  SizedBox(
                    width: 220,
                    height: 40,
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search products...',
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
                    onPressed: _loadProducts,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: (_tenantId != null && _branchId != null)
                        ? () => _showAddEditDialog()
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
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
                              ? 'Click "Add Product" to create your first product'
                              : 'Try a different search term',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: _buildProductTable(filtered, theme, isDark),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTable(
    List<Product> products,
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
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('SKU')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Price'), numeric: true),
          DataColumn(label: Text('Stock'), numeric: true),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: products.map((product) {
          final isLowStock =
              product.stockQuantity <= (product.lowStockThreshold ?? 10);

          return DataRow(
            cells: [
              // Product name + image
              DataCell(
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: isDark ? Colors.white10 : Colors.grey[100],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: product.imageUrl != null
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.medication_outlined,
                                size: 18,
                              ),
                            )
                          : const Icon(Icons.medication_outlined, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(product.sku ?? '-')),
              DataCell(Text(product.category ?? '-')),
              DataCell(Text('₦${product.unitPrice.toStringAsFixed(0)}')),
              DataCell(
                Text(
                  '${product.stockQuantity}',
                  style: TextStyle(
                    color: isLowStock ? Colors.red : null,
                    fontWeight: isLowStock ? FontWeight.bold : null,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: product.isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    product.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: product.isActive ? Colors.green : Colors.grey,
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
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit',
                      onPressed: () => _showAddEditDialog(product: product),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: 'Deactivate',
                      onPressed: () => _confirmDelete(product),
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
}
