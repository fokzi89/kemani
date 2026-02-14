import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/auth_widgets.dart';
import '../../theme.dart';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';
import 'accept_invitation_screen.dart';
import 'verify_passcode_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted && response.session != null) {
        // Check if user has passcode
        final hasPasscode = await _authService.hasPasscode();

        if (mounted) {
          if (hasPasscode) {
             Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const VerifyPasscodeScreen()),
            );
          } else {
             Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Left side - Form
          Expanded(
            flex: isDesktop ? 5 : 1,
            child: Container(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 24.0,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 450),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header with back button and theme toggle
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const BackToHomeButton(),
                                  const ThemeToggleButton(),
                                ],
                              ),
                              const SizedBox(height: 48),

                              // Welcome text with emoji
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Welcome back',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '👋',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displaySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Welcome back! Let\'s make this chapter of your learning adventure a memorable success! Happy learning!',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 48),

                              // Email field
                              AuthTextField(
                                controller: _emailController,
                                label: 'Email',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),

                              // Password field
                              AuthTextField(
                                controller: _passwordController,
                                label: 'Password',
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Login button
                              AuthButton(
                                text: 'Log in',
                                onPressed: _login,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 24),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'or',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Google sign-in button
                              GoogleSignInButton(
                                onPressed: () {
                                  // TODO: Implement Google OAuth
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Google sign-in coming soon!',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 32),

                              // Sign up link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Don\'t have an account? ',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Sign up for free',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.darkPrimary
                                            : AppColors.lightPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                               TextButton(
                                    onPressed: () {
                                      // Use GoRouter if available or push material route
                                       Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const AcceptInvitationScreen(), // Ensure import
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Have an invite code?',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.darkSecondary
                                            : AppColors.lightSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Right side - Testimonial (desktop only)
          if (isDesktop)
            const Expanded(
              flex: 7,
              child: TestimonialCard(
                quote:
                    'The POS system from Fokzify was an absolute game-changer for my business. I now feel confident in my ability to manage inventory, track sales, and I can\'t wait to apply my newfound knowledge in the real world, making the learning process both enjoyable and engaging.',
                authorName: 'Peter Khalifah Sherya',
                authorTitle: 'Senior Data Analyst • Wordpess',
              ),
            ),
        ],
      ),
    );
  }
}
