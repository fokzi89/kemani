import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Theme toggle button for switching between light and dark modes
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Connect to explicit ThemeProvider when verified
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () {
        // themeProvider.toggleTheme();
      },
      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
    );
  }
}

/// Back to home button for navigation to landing page
class BackToHomeButton extends StatelessWidget {
  final String landingPageUrl;

  const BackToHomeButton({
    super.key,
    this.landingPageUrl = 'http://localhost:5173',
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: Icon(
        Icons.arrow_back,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: Text(
        'Back to Home',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}

/// Styled text field for auth forms
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// Primary action button with loading state
class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;

  const AuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(text),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : Text(text),
    );
  }
}

/// Google sign-in button
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({super.key, this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Image.network(
              'https://www.google.com/favicon.ico',
              height: 20,
              width: 20,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.g_mobiledata),
            ),
      label: const Text('Continue with Google'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        side: BorderSide(color: Theme.of(context).dividerColor),
        backgroundColor: Colors.transparent, // Transparent for outlined
      ),
    );
  }
}

/// Testimonial card for the right side of auth screens
class TestimonialCard extends StatelessWidget {
  final String quote;
  final String authorName;
  final String authorTitle;
  final String? imageUrl;
  final Color? backgroundColor;
  final Color? textColor;

  const TestimonialCard({
    super.key,
    required this.quote,
    required this.authorName,
    required this.authorTitle,
    this.imageUrl,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Default to primary color if not specified
    final bg = backgroundColor ?? AppTheme.primaryColor;
    final txt = textColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.all(48),
      color: bg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo text
          Text(
            'Fokzify',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: txt,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),

          // Quote icon
          Icon(
            Icons.format_quote_rounded,
            size: 48,
            color: txt.withOpacity(0.3),
          ),
          const SizedBox(height: 24),

          // Quote
          Text(
            quote,
            style: TextStyle(
              fontSize: 24,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: txt,
            ),
          ),
          const SizedBox(height: 32),

          // Author
          Text(
            authorName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: txt,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            authorTitle,
            style: TextStyle(fontSize: 14, color: txt.withOpacity(0.8)),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
