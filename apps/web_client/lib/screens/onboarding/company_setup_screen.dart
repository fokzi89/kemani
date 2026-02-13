import 'package:flutter/material.dart';
import 'dart:io';
import '../../widgets/onboarding_widgets.dart';
import '../../widgets/auth_widgets.dart';
import '../../theme.dart';
import '../../models/onboarding_models.dart';
import '../../services/onboarding_service.dart';
import '../../services/storage_service.dart';
import '../../services/geocoding_service.dart';
import 'passcode_setup_screen.dart';

class CompanySetupScreen extends StatefulWidget {
  const CompanySetupScreen({super.key});

  @override
  State<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends State<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _officeAddressController = TextEditingController();

  BusinessType? _selectedBusinessType;
  String? _selectedCountry;
  File? _logoImage;
  bool _isLoading = false;

  final _onboardingService = OnboardingService();
  final _storageService = StorageService();
  final _geocodingService = GeocodingService();

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _officeAddressController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload logo if selected
      String? logoUrl;
      if (_logoImage != null) {
        logoUrl = await _storageService.uploadLogo(_logoImage!);
      }

      // Get coordinates from address
      Map<String, double>? coordinates;
      try {
        coordinates = await _geocodingService.getMockCoordinates(
          city: _cityController.text.trim(),
          country: _selectedCountry!,
        );
      } catch (e) {
        print('Geocoding failed: $e');
      }

      // Save company data
      final companyData = CompanyData(
        businessName: _businessNameController.text.trim(),
        businessType: _selectedBusinessType!.value,
        address: _addressController.text.trim(),
        country: _selectedCountry!,
        city: _cityController.text.trim(),
        officeAddress: _officeAddressController.text.trim().isNotEmpty
            ? _officeAddressController.text.trim()
            : null,
        logoUrl: logoUrl,
        latitude: coordinates?['latitude'],
        longitude: coordinates?['longitude'],
      );

      await _onboardingService.saveCompany(companyData);

      if (mounted) {
        // Navigate to passcode setup
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PasscodeSetupScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving company: $e'),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress indicator
                    const OnboardingProgressBar(currentStep: 2),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Set up your business',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tell us about your business',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Business name
                    AuthTextField(
                      controller: _businessNameController,
                      label: 'Business Name',
                      prefixIcon: Icons.store_outlined,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Business name is required'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Business type
                    BusinessTypeDropdown(
                      selectedType: _selectedBusinessType,
                      onChanged: (value) {
                        setState(() => _selectedBusinessType = value);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Address
                    AuthTextField(
                      controller: _addressController,
                      label: 'Address',
                      prefixIcon: Icons.location_on_outlined,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Address is required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Country
                    CountryDropdown(
                      selectedCountry: _selectedCountry,
                      onChanged: (value) {
                        setState(() => _selectedCountry = value);
                      },
                    ),
                    const SizedBox(height: 20),

                    // City
                    AuthTextField(
                      controller: _cityController,
                      label: 'City',
                      prefixIcon: Icons.location_city_outlined,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'City is required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Office address (optional)
                    AuthTextField(
                      controller: _officeAddressController,
                      label: 'Office Address (Optional)',
                      prefixIcon: Icons.business_outlined,
                    ),
                    const SizedBox(height: 32),

                    // Logo upload
                    LogoUpload(
                      onImageSelected: (file) {
                        setState(() => _logoImage = file);
                      },
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
                            text: 'Next',
                            onPressed: _handleNext,
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
      ),
    );
  }
}
