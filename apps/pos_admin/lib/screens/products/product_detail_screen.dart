import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductWithInventory productWithInventory;

  const ProductDetailScreen({
    super.key,
    required this.productWithInventory,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  late ProductWithInventory _productWithInventory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _productWithInventory = widget.productWithInventory;
    _refreshData();
  }

  Future<void> _refreshData() async {
    try {
      final branchId = Supabase.instance.client.auth.currentUser
          ?.userMetadata?['branch_id'] as String?;

      if (branchId != null) {
        final updated = await _productService.getProductWithInventory(
          productId: _productWithInventory.product.id,
          branchId: branchId,
        );

        if (updated != null && mounted) {
          setState(() => _productWithInventory = updated);
        }
      }
    } catch (e) {
      // Silently fail - we already have data
    }
  }

  Future<void> _editProduct() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(
          product: _productWithInventory.product,
        ),
      ),
    );

    if (result == true) {
      _refreshData();
    }
  }

  Future<void> _showAdjustStockDialog() async {
    final adjustmentController = TextEditingController();
    String adjustmentType = 'add'; // 'add' or 'subtract'

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adjust Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'add', label: Text('Add')),
                  ButtonSegment(value: 'subtract', label: Text('Remove')),
                ],
                selected: {adjustmentType},
                onSelectionChanged: (Set<String> selection) {
                  setDialogState(() {
                    adjustmentType = selection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: adjustmentController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: const OutlineInputBorder(),
                  hintText: '0',
                  helperText: adjustmentType == 'add'
                      ? 'Enter quantity to add'
                      : 'Enter quantity to remove',
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final quantity = int.tryParse(adjustmentController.text) ?? 0;
      if (quantity > 0) {
        await _adjustStock(
          adjustmentType == 'add' ? quantity : -quantity,
        );
      }
    }
  }

  Future<void> _adjustStock(int adjustment) async {
    setState(() => _isLoading = true);

    try {
      final branchId = Supabase.instance.client.auth.currentUser
          ?.userMetadata?['branch_id'] as String?;

      if (branchId == null) {
        throw Exception('Branch not found');
      }

      await _productService.adjustStock(
        branchId: branchId,
        productId: _productWithInventory.product.id,
        adjustment: adjustment,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock adjusted successfully')),
        );
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateInventorySettings() async {
    final lowStockController = TextEditingController(
      text: _productWithInventory.inventory?.lowStockThreshold?.toString() ?? '10',
    );
    final expiryAlertController = TextEditingController(
      text: _productWithInventory.inventory?.expiryAlertDays?.toString() ?? '30',
    );
    DateTime? expiryDate = _productWithInventory.inventory?.expiryDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Inventory Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: lowStockController,
                  decoration: const InputDecoration(
                    labelText: 'Low Stock Alert Threshold',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        expiryDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          expiryDate == null
                              ? 'Select date'
                              : '${expiryDate!.year}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}',
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: expiryAlertController,
                  decoration: const InputDecoration(
                    labelText: 'Alert Days Before Expiry',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        final branchId = Supabase.instance.client.auth.currentUser
            ?.userMetadata?['branch_id'] as String?;

        if (branchId == null) {
          throw Exception('Branch not found');
        }

        await _productService.updateInventory(
          branchId: branchId,
          productId: _productWithInventory.product.id,
          lowStockThreshold: int.tryParse(lowStockController.text),
          expiryDate: expiryDate,
          expiryAlertDays: int.tryParse(expiryAlertController.text),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings updated successfully')),
          );
          _refreshData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _productWithInventory.product;
    final inventory = _productWithInventory.inventory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProduct,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              if (product.imageUrl != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Product Name and Category
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (product.category != null) ...[
                const SizedBox(height: 8),
                Chip(
                  label: Text(product.category!),
                  backgroundColor: Colors.blue.shade100,
                ),
              ],
              const SizedBox(height: 24),

              // Product Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      _DetailRow(label: 'SKU', value: product.sku ?? 'N/A'),
                      _DetailRow(label: 'Barcode', value: product.barcode ?? 'N/A'),
                      _DetailRow(
                        label: 'Description',
                        value: product.description ?? 'No description',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selling Price',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'NGN ${product.unitPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (product.costPrice != null)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Cost Price',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'NGN ${product.costPrice!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Inventory Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Inventory',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: _updateInventorySettings,
                          ),
                        ],
                      ),
                      const Divider(),

                      // Stock Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Stock Quantity'),
                          Row(
                            children: [
                              Text(
                                '${inventory?.stockQuantity ?? 0}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (inventory?.isLowStock == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'LOW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (inventory?.isOutOfStock == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'OUT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (inventory != null) ...[
                        _DetailRow(
                          label: 'Available',
                          value: inventory.availableQuantity.toString(),
                        ),
                        _DetailRow(
                          label: 'Reserved',
                          value: inventory.reservedQuantity.toString(),
                        ),
                        _DetailRow(
                          label: 'Low Stock Alert',
                          value: inventory.lowStockThreshold?.toString() ?? 'Not set',
                        ),
                        if (inventory.expiryDate != null) ...[
                          _DetailRow(
                            label: 'Expiry Date',
                            value: '${inventory.expiryDate!.year}-${inventory.expiryDate!.month.toString().padLeft(2, '0')}-${inventory.expiryDate!.day.toString().padLeft(2, '0')}',
                          ),
                          if (inventory.isExpiringSoon)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.red.shade900),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'This product is expiring soon!',
                                      style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _showAdjustStockDialog,
                          icon: const Icon(Icons.inventory),
                          label: const Text('Adjust Stock'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
