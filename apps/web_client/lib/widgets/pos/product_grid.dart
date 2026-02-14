import 'package:flutter/material.dart';
import 'product_card.dart';
import 'product_data.dart';

class ProductGrid extends StatelessWidget {
  final List<ProductData> products;
  final ValueChanged<ProductData> onProductSelected;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductSelected,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final int crossAxisCount;

    if (width > 1400) {
      crossAxisCount = 5;
    } else if (width > 1100) {
      crossAxisCount = 4;
    } else if (width > 800) {
      crossAxisCount = 3;
    } else if (width > 500) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 2;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onAddToCart: () => onProductSelected(product),
        );
      },
    );
  }
}
