import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return ActionChip(
            label: Text(category),
            backgroundColor: isSelected ? theme.colorScheme.primary : null,
            labelStyle: TextStyle(
              color: isSelected ? theme.colorScheme.onPrimary : null,
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
            side: isSelected ? BorderSide.none : null,
            onPressed: () => onCategorySelected(category),
          );
        },
      ),
    );
  }
}
