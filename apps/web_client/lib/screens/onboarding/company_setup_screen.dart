import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/onboarding_service.dart';
import '../../models/onboarding_models.dart';
import '../../widgets/auth_widgets.dart';

class CompanySetupScreen extends ConsumerStatefulWidget {
  const CompanySetupScreen({super.key});

  @override
  ConsumerState<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends ConsumerState<CompanySetupScreen> {
  final _businessNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = OnboardingService();
      await service.saveCompany(
        CompanyData(
          businessName: _businessNameController.text.trim(),
          businessType: _businessTypeController.text.trim().isEmpty
              ? 'retail'
              : _businessTypeController.text.trim(),
          address: _addressController.text.trim(),
          country: _countryController.text.trim(),
          city: _cityController.text.trim(),
        ),
      );

      if (mounted) {
        context.go('/dashboard'); // Router will redirect to Passcode if needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save company: $e')));
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Set up your business",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Tell us about your company to get started.",
                        ),
                        const SizedBox(height: 32),

                        AuthTextField(
                          controller: _businessNameController,
                          label: "Business Name",
                          prefixIcon: Icons.store_mall_directory_outlined,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _businessTypeController,
                          label: "Business Type",
                          prefixIcon: Icons.category_outlined,
                          // Could be dropdown later
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _addressController,
                          label: "Address",
                          prefixIcon: Icons.location_on_outlined,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AuthTextField(
                                controller: _cityController,
                                label: "City",
                                prefixIcon: Icons.location_city_outlined,
                                validator: (v) =>
                                    v?.isEmpty ?? true ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AuthTextField(
                                controller: _countryController,
                                label: "Country",
                                prefixIcon: Icons.public_outlined,
                                validator: (v) =>
                                    v?.isEmpty ?? true ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                        AuthButton(
                          text: "Continue",
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
                  quote: "Manage your business like a pro.",
                  authorName: "Kemani Team",
                  authorTitle: "Setup",
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
