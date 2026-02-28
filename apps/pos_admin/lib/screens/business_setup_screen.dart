import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedBusinessType;
  String? _selectedLocationType;
  XFile? _businessLogo;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Country settings passed from previous screen
  Map<String, dynamic>? _selectedCountry;

  // Brand color selection
  Color _selectedBrandColor = const Color(0xFF10B981); // Default emerald-500

  final List<String> _businessTypes = [
    'Retail',
    'Restaurant',
    'Grocery Store',
    'Pharmacy',
    'Fashion & Apparel',
    'Electronics',
    'Beauty & Salon',
    'Healthcare',
    'Automotive',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Retrieve country settings from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('selectedCountry')) {
        setState(() {
          _selectedCountry = args['selectedCountry'] as Map<String, dynamic>;
        });
      }
    });
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _businessLogo = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Brand Color'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Predefined color palette
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildColorOption(const Color(0xFF10B981)), // Emerald
                    _buildColorOption(const Color(0xFF3B82F6)), // Blue
                    _buildColorOption(const Color(0xFF8B5CF6)), // Purple
                    _buildColorOption(const Color(0xFFEC4899)), // Pink
                    _buildColorOption(const Color(0xFFEF4444)), // Red
                    _buildColorOption(const Color(0xFFF59E0B)), // Amber
                    _buildColorOption(const Color(0xFF14B8A6)), // Teal
                    _buildColorOption(const Color(0xFF6366F1)), // Indigo
                    _buildColorOption(const Color(0xFFF97316)), // Orange
                    _buildColorOption(const Color(0xFF06B6D4)), // Cyan
                    _buildColorOption(const Color(0xFF84CC16)), // Lime
                    _buildColorOption(const Color(0xFF0EA5E9)), // Sky
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = _selectedBrandColor.value == color.value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBrandColor = color;
        });
        Navigator.of(context).pop();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 28,
              )
            : null,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService = SupabaseService();
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Upload business logo if selected
      String? logoUrl;
      if (_businessLogo != null) {
        final bytes = await _businessLogo!.readAsBytes();
        logoUrl = await supabaseService.uploadImage(
          bucket: 'business-logos',
          path: 'logos/$userId',
          fileBytes: bytes,
          contentType: 'image/jpeg',
        );
      }

      // Convert Color to hex string (e.g., #10B981)
      final brandColorHex = '#${_selectedBrandColor.value.toRadixString(16).substring(2).toUpperCase()}';

      // Create business/tenant with country settings and brand color
      final tenantId = await supabaseService.createBusiness(
        ownerId: userId,
        businessName: _businessNameController.text.trim(),
        businessType: _selectedBusinessType!,
        locationType: _selectedLocationType!,
        state: _stateController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        logoUrl: logoUrl,
        brandColor: brandColorHex,
        countryCode: _selectedCountry?['code'] as String?,
        dialCode: _selectedCountry?['dialCode'] as String?,
        currencyCode: _selectedCountry?['currencyCode'] as String?,
      );

      // Update user with tenant_id and mark onboarding complete
      await supabaseService.updateUser(
        userId: userId,
        tenantId: tenantId,
        completeOnboarding: true,
      );

      if (mounted) {
        // Navigate to Dashboard
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left side - Form
          Expanded(
            flex: isDesktop ? 1 : 2,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Row(
                        children: [
                          Icon(
                            Icons.point_of_sale,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kemani POS',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),

                      // Progress Indicator
                      Row(
                        children: List.generate(
                          4,
                          (index) => Expanded(
                            child: Container(
                              height: 4,
                              margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Heading
                      Text(
                        'Business Setup',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Step 4 of 4: Business Information',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(height: 32),

                      // Business Logo
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickLogo,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[100],
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: _businessLogo != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: kIsWeb
                                            ? Image.network(
                                                _businessLogo!.path,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                File(_businessLogo!.path),
                                                fit: BoxFit.cover,
                                              ),
                                      )
                                    : Icon(
                                        Icons.business,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _pickLogo,
                              icon: const Icon(Icons.upload, size: 18),
                              label: Text(
                                _businessLogo == null ? 'Upload logo' : 'Change logo',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_businessLogo != null)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _businessLogo = null;
                                  });
                                },
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text(
                                  'Remove logo',
                                  style: TextStyle(fontSize: 14),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Brand Color Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Brand Color',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showColorPicker,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _selectedBrandColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[400]!,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Choose your brand color',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '#${_selectedBrandColor.value.toRadixString(16).substring(2).toUpperCase()}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.color_lens_outlined,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'This color will be used for branding across your POS and receipts',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Business Name
                      _buildTextField(
                        controller: _businessNameController,
                        label: 'Business Name',
                        hintText: 'Enter your business name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your business name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Business Type
                      _buildDropdownField(
                        value: _selectedBusinessType,
                        label: 'Business Type',
                        hintText: 'Select business type',
                        items: _businessTypes,
                        onChanged: (value) {
                          setState(() {
                            _selectedBusinessType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select business type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Location Type
                      _buildDropdownField(
                        value: _selectedLocationType,
                        label: 'Location Type',
                        hintText: 'Select location type',
                        items: const ['Head Office', 'Branch'],
                        onChanged: (value) {
                          setState(() {
                            _selectedLocationType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select location type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // State
                      _buildTextField(
                        controller: _stateController,
                        label: 'State/Province',
                        hintText: 'Enter state or province',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter state/province';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // City
                      _buildTextField(
                        controller: _cityController,
                        label: 'City',
                        hintText: 'Enter city',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter city';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Office Address
                      _buildTextField(
                        controller: _addressController,
                        label: 'Office Address',
                        hintText: 'Enter complete office address',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter office address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Complete Setup',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right side - Hero Section (only show on desktop)
          if (isDesktop)
            Expanded(
              flex: 1,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF047857), // emerald-700
                      Color(0xFF059669), // emerald-600
                      Color(0xFF10B981), // emerald-500
                    ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.storefront,
                          size: 120,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Almost There!',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Complete your business setup to start managing your sales, inventory, and customers with ease.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: const [
              TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required String hintText,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: const [
              TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
