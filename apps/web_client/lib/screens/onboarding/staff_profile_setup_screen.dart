import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/onboarding_service.dart';
import '../../models/onboarding_models.dart';
import '../../widgets/auth_widgets.dart';

class StaffProfileSetupScreen extends ConsumerStatefulWidget {
  const StaffProfileSetupScreen({super.key});

  @override
  ConsumerState<StaffProfileSetupScreen> createState() =>
      _StaffProfileSetupScreenState();
}

class _StaffProfileSetupScreenState
    extends ConsumerState<StaffProfileSetupScreen> {
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
        // Staff don't setup company, go to passcode
        context.go('/onboarding/passcode');
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
    return Scaffold(
      body: Center(
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
                    "Staff Profile Setup",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  AuthTextField(
                    controller: _fullNameController,
                    label: "Full Name",
                    prefixIcon: Icons.person_outline,
                    validator: (v) =>
                        v?.isNotEmpty ?? false ? null : 'Required',
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
                    text: "Next",
                    onPressed: _submit,
                    isLoading: _isLoading,
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
