import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tenant_provider.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';

// Provider for ProductService
final productServiceProvider = Provider((ref) => ProductService());

// Provider for watching products
final productsStreamProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  final tenantAsync = ref.watch(tenantProvider);
  // Ensure we have data
  if (!tenantAsync.hasValue || tenantAsync.value?.tenant == null) {
    return const Stream.empty();
  }

  final tenantId = tenantAsync.value!.tenant!.id;
  return ref.watch(productServiceProvider).watchProducts(tenantId);
});

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/inventory/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filteredProducts = products.where((product) {
                  return product.name.toLowerCase().contains(_searchQuery) ||
                      (product.sku?.toLowerCase().contains(_searchQuery) ??
                          false) ||
                      (product.barcode?.contains(_searchQuery) ?? false);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return ListTile(
                      leading: product.imageUrl != null
                          ? Image.network(
                              product.imageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.inventory_2, size: 40),
                      title: Text(product.name),
                      subtitle: Text(
                        'Stock: ${product.currentStock} | Price: \$${product.sellingPrice.toStringAsFixed(2)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push('/inventory/edit/${product.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
