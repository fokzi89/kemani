import 'package:flutter/material.dart';
import '../../theme.dart';

class NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyPress;
  final bool showDecimal;

  const NumericKeypad({
    super.key,
    required this.onKeyPress,
    this.showDecimal = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        _buildRow(['4', '5', '6']),
        _buildRow(['7', '8', '9']),
        _buildRow([showDecimal ? '.' : '', '0', 'BACKSPACE']),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: keys
            .map(
              (key) => Expanded(
                child: _KeyButton(label: key, onTap: () => onKeyPress(key)),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (label.isEmpty) return const SizedBox();

    final isBackspace = label == 'BACKSPACE';

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Center(
            child: isBackspace
                ? const Icon(Icons.backspace_outlined)
                : Text(label, style: theme.textTheme.headlineSmall),
          ),
        ),
      ),
    );
  }
}
