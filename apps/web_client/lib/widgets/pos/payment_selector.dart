import 'package:flutter/material.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodSelected;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: [
            _buildOption(context, 'cash', 'Cash', Icons.money),
            _buildOption(context, 'card', 'Card', Icons.credit_card),
            _buildOption(
              context,
              'transfer',
              'Transfer',
              Icons.account_balance,
            ),
            _buildOption(
              context,
              'mobile_money',
              'Mobile Money',
              Icons.phone_android,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = selectedMethod == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : Colors.black87,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onMethodSelected(value);
      },
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
    );
  }
}
