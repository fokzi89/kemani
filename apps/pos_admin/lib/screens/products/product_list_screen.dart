import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import 'product_form_screen.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  bool _isLoading = false;
  List<ProductWithInventory> _products = [];
  List<String> _categories = [];
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showLowStockOnly = false;
  bool _showExpiringSoon = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _productService.getCategories();
      if (mounted) {
        setState(() => _categories = categories);
      }
    } catch (e) {
      // Silently fail - categories are not critical
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      // Get current branch ID from user metadata
      final branchId = Supabase.instance.client.auth.currentUser
          ?.userMetadata?['branch_id'] as String?;

      if (branchId == null) {
        throw Exception('Branch not found for user');
      }

      _products = await _productService.listProductsWithInventory(
        branchId: branchId,
        category: _selectedCategory,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        lowStockOnly: _showLowStockOnly,
        expiringSoonOnly: _showExpiringSoon,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching products: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Products',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Category filter
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Categories')),
                ..._categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                )),
              ],
              onChanged: (value) {
                setState(() => _selectedCategory = value);
                Navigator.pop(context);
                _fetchProducts();
              },
            ),
            const SizedBox(height: 16),

            // Stock filters
            SwitchListTile(
              title: const Text('Low Stock Only'),
              value: _showLowStockOnly,
              onChanged: (value) {
                setState(() => _showLowStockOnly = value);
                Navigator.pop(context);
                _fetchProducts();
              },
            ),
            SwitchListTile(
              title: const Text('Expiring Soon'),
              value: _showExpiringSoon,
              onChanged: (value) {
                setState(() => _showExpiringSoon = value);
                Navigator.pop(context);
                _fetchProducts();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          if (_selectedCategory != null || _showLowStockOnly || _showExpiringSoon)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Clear filters',
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _showLowStockOnly = false;
                  _showExpiringSoon = false;
                });
                _fetchProducts();
              },
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Products',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _fetchProducts();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                // Debounce could be added here
                _fetchProducts();
              },
            ),
          ),

          // Filter chips
          if (_selectedCategory != null || _showLowStockOnly || _showExpiringSoon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_selectedCategory != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('Category: $_selectedCategory'),
                        onDeleted: () {
                          setState(() => _selectedCategory = null);
                          _fetchProducts();
                        },
                      ),
                    ),
                  if (_showLowStockOnly)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: const Text('Low Stock'),
                        backgroundColor: Colors.orange.shade100,
                        onDeleted: () {
                          setState(() => _showLowStockOnly = false);
                          _fetchProducts();
                        },
                      ),
                    ),
                  if (_showExpiringSoon)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: const Text('Expiring Soon'),
                        backgroundColor: Colors.red.shade100,
                        onDeleted: () {
                          setState(() => _showExpiringSoon = false);
                          _fetchProducts();
                        },
                      ),
                    ),
                ],
              ),
            ),

          // Products List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('No products found.'))
                    : RefreshIndicator(
                        onRefresh: _fetchProducts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final productWithInventory = _products[index];
                            return _ProductCard(
                              productWithInventory: productWithInventory,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                      productWithInventory: productWithInventory,
                                    ),
                                  ),
                                ).then((_) => _fetchProducts());
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductFormScreen(),
            ),
          ).then((_) => _fetchProducts());
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductWithInventory productWithInventory;
  final VoidCallback onTap;

  const _ProductCard({
    required this.productWithInventory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final product = productWithInventory.product;
    final inventory = productWithInventory.inventory;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: product.imageUrl != null
              ? ClipOval(child: Image.network(product.imageUrl!, fit: BoxFit.cover))
              : const Icon(Icons.inventory_2, color: Colors.blue),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.category != null) ...[
              const SizedBox(height: 4),
              Text(product.category!),
            ],
            if (product.sku != null) ...[
              const SizedBox(height: 4),
              Text('SKU: ${product.sku}', style: TextStyle(color: Colors.grey[600])),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Stock: ${inventory?.stockQuantity ?? 0}'),
                if (inventory?.isLowStock == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Low Stock',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (inventory?.isExpiringSoon == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Expiring Soon',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'NGN ${product.unitPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (product.costPrice != null)
              Text(
                'Cost: NGN ${product.costPrice!.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
