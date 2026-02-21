import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/auth_widgets.dart';

class PasscodeSetupScreen extends ConsumerStatefulWidget {
  const PasscodeSetupScreen({super.key});

  @override
  ConsumerState<PasscodeSetupScreen> createState() =>
      _PasscodeSetupScreenState();
}

class _PasscodeSetupScreenState extends ConsumerState<PasscodeSetupScreen> {
  final _passcodeController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passcodeController.text != _confirmController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passcodes do not match')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = OnboardingService();
      await service.setupPasscode(_passcodeController.text);

      // Also mark as complete if this is the last step
      await service.completeOnboarding();

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to set passcode: $e')));
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
          Expanded(
            flex: isDesktop ? 5 : 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Secure your account",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("Set a 6-digit passcode for quick access."),
                        const SizedBox(height: 32),

                        AuthTextField(
                          controller: _passcodeController,
                          label: "Enter 6-digit Passcode",
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline,
                          validator: (v) =>
                              (v?.length ?? 0) != 6 ? 'Must be 6 digits' : null,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _confirmController,
                          label: "Confirm Passcode",
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline,
                        ),

                        const SizedBox(height: 32),

                        AuthButton(
                          text: "Complete Setup",
                          onPressed: _submit,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isDesktop)
            Expanded(
              flex: 7,
              child: Container(
                color: Theme.of(context).primaryColor,
                child: const TestimonialCard(
                  quote: "Security first.",
                  authorName: "Kemani Team",
                  authorTitle: "Security",
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
