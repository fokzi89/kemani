import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/onboarding_service.dart';
import '../../models/onboarding_models.dart';
import '../../widgets/auth_widgets.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = OnboardingService();
      await service.saveProfile(
        ProfileData(
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        ),
      );

      if (mounted) {
        // Refresh router to trigger redirect check
        // Or manually navigate as router redirect might be async/slow
        // But app_router logic should pick it up.
        // For specialized flow, we might need to invalidate status provider if we had one.
        context.go(
          '/dashboard',
        ); // Router will redirect if next steps (Company/Passcode) needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          // Left side
          Expanded(
            flex: isDesktop ? 5 : 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [ThemeToggleButton()],
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          "Set up your profile",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tell us a bit about yourself.",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 32),

                        AuthTextField(
                          controller: _fullNameController,
                          label: "Full Name",
                          prefixIcon: Icons.person_outline,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _phoneController,
                          label: "Phone Number (Optional)",
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 32),

                        AuthButton(
                          text: "Continue",
                          onPressed: _submit,
                          isLoading: _isLoading,
                        ),

                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            // Sign out if stuck
                            // ref.read(authProvider.notifier).signOut();
                          },
                          child: const Text("Sign Out"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Right side
          if (isDesktop)
            Expanded(
              flex: 7,
              child: Container(
                color: Theme.of(context).primaryColor,
                child: const TestimonialCard(
                  quote: "Great things start with a solid foundation.",
                  authorName: "Kemani Team",
                  authorTitle: "Onboarding",
                  textColor: Colors.white,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
