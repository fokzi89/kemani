import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../providers/tenant_provider.dart';

// Provider to fetch single product for editing
final productDetailsProvider = FutureProvider.autoDispose.family<Product?, String>((
  ref,
  id,
) async {
  // We should ideally use the productServiceProvider, but direct instantiation works for now as services are stateless mostly
  // ref.watch(productServiceProvider) would be better if we had it exported globally or in a shared file
  return await ProductService().getProductById(id);
});

class ProductEditScreen extends ConsumerStatefulWidget {
  final String? productId; // Null for new product

  const ProductEditScreen({super.key, this.productId});

  @override
  ConsumerState<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends ConsumerState<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();

  bool _trackInventory = true;
  bool _isLoading = false;
  bool _isDataLoaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tenantState = ref.read(tenantProvider);
      if (!tenantState.hasValue || tenantState.value?.tenant == null) {
        throw Exception('No active tenant found');
      }
      final tenantId = tenantState.value!.tenant!.id;

      final service = ProductService();

      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final sku = _skuController.text.trim();
      final barcode = _barcodeController.text.trim();
      final costPrice = double.tryParse(_costPriceController.text) ?? 0.0;
      final sellingPrice = double.parse(_sellingPriceController.text);
      final currentStock = int.tryParse(_stockController.text) ?? 0;

      if (widget.productId == null) {
        // Create New
        final newProduct = Product(
          id: '', // Service handles generation if empty
          tenantId: tenantId,
          name: name,
          description: description.isEmpty ? null : description,
          sku: sku.isEmpty ? null : sku,
          barcode: barcode.isEmpty ? null : barcode,
          costPrice: costPrice,
          sellingPrice: sellingPrice,
          currentStock: currentStock,
          trackInventory: _trackInventory,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await service.createProduct(newProduct);
      } else {
        // Update Existing
        final existing = await service.getProductById(widget.productId!);
        if (existing != null) {
          final updated = existing.copyWith(
            name: name,
            description: description.isEmpty ? null : description,
            sku: sku.isEmpty ? null : sku,
            barcode: barcode.isEmpty ? null : barcode,
            costPrice: costPrice,
            sellingPrice: sellingPrice,
            currentStock: currentStock,
            trackInventory: _trackInventory,
            updatedAt: DateTime.now(),
          );
          await service.updateProduct(updated);
        }
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.productId == null ? 'Product Created' : 'Product Updated',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.productId != null && !_isDataLoaded) {
      final productAsync = ref.watch(productDetailsProvider(widget.productId!));

      productAsync.when(
        data: (product) {
          if (product != null && !_isDataLoaded) {
            // Defer state update using addPostFrameCallback to avoid build-phase setState
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _nameController.text = product.name;
                  _descriptionController.text = product.description ?? '';
                  _skuController.text = product.sku ?? '';
                  _barcodeController.text = product.barcode ?? '';
                  _costPriceController.text = product.costPrice.toString();
                  _sellingPriceController.text = product.sellingPrice
                      .toString();
                  _stockController.text = product.currentStock.toString();
                  _trackInventory = product.trackInventory;
                  _isDataLoaded = true;
                });
              }
            });
          }
        },
        loading: () {},
        error: (e, s) {},
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Add Product' : 'Edit Product'),
      ),
      body: _isLoading || (widget.productId != null && !_isDataLoaded)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _skuController,
                            decoration: const InputDecoration(
                              labelText: 'SKU',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _barcodeController,
                            decoration: const InputDecoration(
                              labelText: 'Barcode',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.qr_code),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _costPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Cost Price',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _sellingPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Selling Price',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Track Inventory'),
                      value: _trackInventory,
                      onChanged: (val) => setState(() => _trackInventory = val),
                    ),
                    if (_trackInventory)
                      TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Current Stock',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        child: Text(
                          widget.productId == null
                              ? 'Create Product'
                              : 'Save Changes',
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
