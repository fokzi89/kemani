import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tenant_provider.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import '../../widgets/pos/cart_drawer.dart';
import '../../providers/cart_provider.dart';

// Reusing the stream logic, or import if shared. Defining here for isolation.
final salesProductsProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  final tenantAsync = ref.watch(tenantProvider);
  if (!tenantAsync.hasValue || tenantAsync.value?.tenant == null) {
    return const Stream.empty();
  }
  final tenantId = tenantAsync.value!.tenant!.id;
  return ProductService().watchProducts(tenantId);
});

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(salesProductsProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Sales'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  // Open End Drawer
                  Scaffold.of(context).openEndDrawer();
                },
              ),
              if (cart.items.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${cart.items.length}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      endDrawer: const CartDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search products by name, SKU, or barcode...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = products.where((p) {
                  final matchName = p.name.toLowerCase().contains(_searchQuery);
                  final matchSku =
                      p.sku?.toLowerCase().contains(_searchQuery) ?? false;
                  final matchBarcode =
                      p.barcode?.contains(_searchQuery) ?? false;
                  return matchName || matchSku || matchBarcode;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return GestureDetector(
                      onTap: () {
                        ref.read(cartProvider.notifier).addItem(product);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added ${product.name} to cart'),
                            duration: const Duration(milliseconds: 500),
                          ),
                        );
                      },
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child:
                                  product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) =>
                                          const ColoredBox(
                                            color: Colors.grey,
                                            child: Icon(Icons.broken_image),
                                          ),
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.inventory_2,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${product.sellingPrice.toStringAsFixed(2)}',
                                  ),
                                  if (product.trackInventory)
                                    Text(
                                      'Stock: ${product.currentStock}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: product.currentStock > 0
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
