import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';

/// Theme toggle button for switching between light and dark modes
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      ),
      onPressed: () => themeProvider.toggleTheme(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextButton.icon(
      icon: Icon(
        Icons.arrow_back,
        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      ),
      label: Text(
        'Back to Home',
        style: TextStyle(
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: () {
        // For web, we can use url_launcher or just window.location
        // For now, we'll use Navigator.pop or show a message
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        // TODO: Implement web navigation to landing page
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
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
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
  final bool isOutlined;

  const AuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          : Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      label: const Text(
        'Continue with Google',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        foregroundColor: isDark
            ? AppColors.darkForeground
            : AppColors.lightForeground,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 2,
        ),
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

  const TestimonialCard({
    super.key,
    required this.quote,
    required this.authorName,
    required this.authorTitle,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSecondary, AppColors.darkBackground]
              : [AppColors.lightPrimary, AppColors.lightAccent],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Text(
            'Fokzify',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkPrimary : Colors.white,
            ),
          ),
          const SizedBox(height: 48),

          // Quote icon
          Icon(
            Icons.format_quote,
            size: 48,
            color: isDark
                ? AppColors.darkPrimary.withOpacity(0.5)
                : Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 24),

          // Quote text
          Text(
            quote,
            style: TextStyle(
              fontSize: 18,
              height: 1.6,
              color: isDark ? AppColors.darkForeground : Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          // Author info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authorName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkPrimary : Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                authorTitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkMutedForeground
                      : Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
