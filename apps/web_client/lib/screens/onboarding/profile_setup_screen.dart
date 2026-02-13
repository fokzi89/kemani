import 'package:flutter/material.dart';
import 'dart:io';
import '../../widgets/onboarding_widgets.dart';
import '../../widgets/auth_widgets.dart';
import '../../theme.dart';
import '../../models/onboarding_models.dart';
import '../../services/onboarding_service.dart';
import '../../services/storage_service.dart';
import 'company_setup_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedGender;
  File? _profileImage;
  bool _isLoading = false;

  final _onboardingService = OnboardingService();
  final _storageService = StorageService();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload profile picture if selected
      String? profilePictureUrl;
      if (_profileImage != null) {
        profilePictureUrl = await _storageService.uploadProfilePicture(
          _profileImage!,
        );
      }

      // Save profile data
      final profileData = ProfileData(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        gender: _selectedGender,
        profilePictureUrl: profilePictureUrl,
      );

      await _onboardingService.saveProfile(profileData);

      if (mounted) {
        // Navigate to company setup
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CompanySetupScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
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
                    const OnboardingProgressBar(currentStep: 1),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Set up your profile',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tell us a bit about yourself',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Profile picture upload
                    ProfilePictureUpload(
                      onImageSelected: (file) {
                        setState(() => _profileImage = file);
                      },
                    ),
                    const SizedBox(height: 32),

                    // Full name
                    AuthTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Full name is required'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Phone number (optional)
                    AuthTextField(
                      controller: _phoneController,
                      label: 'Phone Number (Optional)',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    // Gender selector
                    GenderSelector(
                      selectedGender: _selectedGender,
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                    ),
                    const SizedBox(height: 48),

                    // Next button
                    AuthButton(
                      text: 'Next',
                      onPressed: _handleNext,
                      isLoading: _isLoading,
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
