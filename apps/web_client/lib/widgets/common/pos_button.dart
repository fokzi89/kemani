import 'package:flutter/material.dart';

class POSButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final IconData? icon;

  const POSButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isSecondary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      if (isSecondary) {
        return OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        );
      }
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    if (isSecondary) {
      return OutlinedButton(onPressed: onPressed, child: Text(label));
    }
    return ElevatedButton(onPressed: onPressed, child: Text(label));
  }
}
