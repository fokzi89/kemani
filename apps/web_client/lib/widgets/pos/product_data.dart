import '../../models/product.dart';

class ProductData {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String? imageUrl;
  final String? category;

  const ProductData({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.category,
  });

  /// Create a ProductData from a Supabase Product model
  factory ProductData.fromProduct(Product product) {
    return ProductData(
      id: product.id,
      name: product.name,
      price: product.unitPrice,
      stock: product.stockQuantity,
      imageUrl: product.imageUrl,
      category: product.category,
    );
  }
}
