import 'package:flutter/material.dart';
import '../../widgets/onboarding_widgets.dart';
import '../../widgets/auth_widgets.dart';
import '../../theme.dart';
import '../../services/onboarding_service.dart';
import '../dashboard/dashboard_screen.dart';

class PasscodeSetupScreen extends StatefulWidget {
  const PasscodeSetupScreen({super.key});

  @override
  State<PasscodeSetupScreen> createState() => _PasscodeSetupScreenState();
}

class _PasscodeSetupScreenState extends State<PasscodeSetupScreen> {
  String? _passcode;
  String? _confirmPasscode;
  bool _isLoading = false;
  String? _errorMessage;

  final _onboardingService = OnboardingService();

  void _handlePasscodeCompleted(String passcode) {
    setState(() {
      _passcode = passcode;
      _errorMessage = null;
    });
  }

  void _handleConfirmPasscodeCompleted(String passcode) {
    setState(() {
      _confirmPasscode = passcode;
      _errorMessage = null;
    });
  }

  Future<void> _handleComplete() async {
    if (_passcode == null || _passcode!.length != 6) {
      setState(() => _errorMessage = 'Please enter a 6-digit passcode');
      return;
    }

    if (_confirmPasscode == null || _confirmPasscode!.length != 6) {
      setState(() => _errorMessage = 'Please confirm your passcode');
      return;
    }

    if (_passcode != _confirmPasscode) {
      setState(() => _errorMessage = 'Passcodes do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Setup passcode
      await _onboardingService.setupPasscode(_passcode!);

      // Complete onboarding
      await _onboardingService.completeOnboarding();

      if (mounted) {
        // Navigate to dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error setting up passcode: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress indicator
                  const OnboardingProgressBar(currentStep: 3),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Set up security',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create a 6-digit passcode to secure your account',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Passcode input
                  PasscodeInput(
                    label: 'Enter Passcode',
                    onCompleted: _handlePasscodeCompleted,
                  ),
                  const SizedBox(height: 32),

                  // Confirm passcode input
                  PasscodeInput(
                    label: 'Confirm Passcode',
                    onCompleted: _handleConfirmPasscodeCompleted,
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 48),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: AuthButton(
                          text: 'Complete',
                          onPressed: _handleComplete,
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
