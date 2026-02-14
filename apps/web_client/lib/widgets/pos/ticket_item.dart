import 'package:flutter/material.dart';
import '../../theme.dart';

class TicketItem extends StatelessWidget {
  final String name;
  final int quantity;
  final double price;
  final VoidCallback onTap;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const TicketItem({
    super.key,
    required this.name,
    required this.quantity,
    required this.price,
    required this.onTap,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final total = price * quantity;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? AppColors.darkBorder.withOpacity(0.5)
                  : AppColors.lightBorder.withOpacity(0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            // Quantity Controls
            _QuantityControl(
              quantity: quantity,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
            const SizedBox(width: 12),

            // Name & Price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${price.toStringAsFixed(0)} / unit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.lightMutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            // Total
            Text(
              '₦${total.toStringAsFixed(0)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const _QuantityControl({
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        InkWell(
          onTap: onDecrement,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.dividerColor),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.remove, size: 14),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$quantity',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onIncrement,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, size: 14, color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
