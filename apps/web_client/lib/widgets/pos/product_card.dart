import 'package:flutter/material.dart';
import '../../theme.dart';
import 'product_data.dart';

class ProductCard extends StatelessWidget {
  final ProductData product;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withOpacity(0.3)
              : AppColors.lightBorder.withOpacity(0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image with availability badge
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: isDark ? Colors.black26 : Colors.grey[100],
                  child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.medication_outlined,
                              size: 40,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.medication_outlined,
                            size: 40,
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                        ),
                ),
                // Availability badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: product.stock > 0
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          product.stock > 0 ? Icons.check_circle : Icons.cancel,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.stock > 0 ? 'Available' : 'Not Available',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Name + Price + Add button
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product name
                Text(
                  product.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Price
                Text(
                  '₦${product.price.toStringAsFixed(0)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.lightMutedForeground,
                  ),
                ),
                const SizedBox(height: 6),
                // Add to Cart button
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: product.stock > 0 ? onAddToCart : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: product.stock > 0
                          ? theme.colorScheme.primary
                          : Colors.grey,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(
                      product.stock > 0 ? '+ Add to Cart' : 'Not Available',
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
}
