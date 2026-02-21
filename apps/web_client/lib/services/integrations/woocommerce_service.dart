import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../models/product.dart';
import '../../models/order.dart';

class WooCommerceService {
  final String? _baseUrl;
  final String? _consumerKey;
  final String? _consumerSecret;

  WooCommerceService({
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
  }) : _baseUrl = baseUrl ?? dotenv.env['WC_URL'],
       _consumerKey = consumerKey ?? dotenv.env['WC_KEY'],
       _consumerSecret = consumerSecret ?? dotenv.env['WC_SECRET'];

  // Helper to construct auth params
  String get _authQuery =>
      'consumer_key=$_consumerKey&consumer_secret=$_consumerSecret';

  /// Fetch products from WooCommerce
  Future<List<Product>> fetchProducts(String tenantId) async {
    if (_baseUrl == null || _consumerKey == null || _consumerSecret == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wp-json/wc/v3/products?$_authQuery'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        return data.map<Product>((item) {
          return Product(
            id: item['id'].toString(), // Use WC ID temporarily or map
            tenantId: tenantId,
            name: item['name'] ?? 'Unknown',
            description: item['description']?.replaceAll(
              RegExp(r'<[^>]*>'),
              '',
            ), // Strip HTML
            sku: item['sku'] ?? '',
            sellingPrice:
                double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
            costPrice: 0.0, // WC doesn't expose cost price by default
            currentStock:
                int.tryParse(item['stock_quantity']?.toString() ?? '0') ?? 0,
            trackInventory: item['manage_stock'] ?? false,
            imageUrl: (item['images'] as List?)?.isNotEmpty == true
                ? item['images'][0]['src']
                : null,
            categoryId: (item['categories'] as List?)?.isNotEmpty == true
                ? item['categories'][0]['id'].toString()
                : null,
            createdAt: DateTime.tryParse(item['date_created'] ?? ''),
            updatedAt: DateTime.tryParse(item['date_modified'] ?? ''),
          );
        }).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('WooCommerce Error: $e');
      return [];
    }
  }

  /// Sync orders from WooCommerce
  Future<List<dynamic>> fetchOrders() async {
    if (_baseUrl == null) return [];

    final response = await http.get(
      Uri.parse('$_baseUrl/wp-json/wc/v3/orders?$_authQuery'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }
}
