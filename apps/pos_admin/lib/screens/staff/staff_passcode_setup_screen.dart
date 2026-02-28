import 'package:flutter/material.dart';

class StaffPasscodeSetupScreen extends StatefulWidget {
  const StaffPasscodeSetupScreen({super.key});

  @override
  State<StaffPasscodeSetupScreen> createState() =>
      _StaffPasscodeSetupScreenState();
}

class _StaffPasscodeSetupScreenState extends State<StaffPasscodeSetupScreen> {
  String _passcode = '';
  String _confirmPasscode = '';
  bool _isConfirming = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    // In production, check if device supports biometrics
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _biometricAvailable = true; // Simulated
    });
  }

  void _onNumberPressed(String number) {
    setState(() {
      _errorMessage = null;

      if (_isConfirming) {
        if (_confirmPasscode.length < 6) {
          _confirmPasscode += number;

          if (_confirmPasscode.length == 6) {
            _verifyPasscodes();
          }
        }
      } else {
        if (_passcode.length < 6) {
          _passcode += number;

          if (_passcode.length == 6) {
            // Move to confirmation
            Future.delayed(const Duration(milliseconds: 300), () {
              setState(() {
                _isConfirming = true;
              });
            });
          }
        }
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      _errorMessage = null;

      if (_isConfirming) {
        if (_confirmPasscode.isNotEmpty) {
          _confirmPasscode =
              _confirmPasscode.substring(0, _confirmPasscode.length - 1);
        }
      } else {
        if (_passcode.isNotEmpty) {
          _passcode = _passcode.substring(0, _passcode.length - 1);
        }
      }
    });
  }

  Future<void> _verifyPasscodes() async {
    if (_passcode == _confirmPasscode) {
      setState(() {
        _isLoading = true;
      });

      // Save passcode
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Complete onboarding - Navigate to Staff Dashboard
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/staff-dashboard',
          (route) => false,
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Passcodes do not match. Please try again.';
        _confirmPasscode = '';
        _passcode = '';
        _isConfirming = false;
      });

      // Clear error after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    }
  }

  Future<void> _setupBiometric() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate biometric setup
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Complete onboarding - Navigate to Staff Dashboard
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/staff-dashboard',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Row(
        children: [
          // Left side - Passcode Setup
          Expanded(
            flex: isDesktop ? 1 : 2,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
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
                        3,
                        (index) => Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
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
                      'Security Setup',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Step 3 of 3: Set up your security method',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),

                    // Passcode Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isConfirming
                                ? 'Confirm Your Passcode'
                                : 'Create a 6-Digit Passcode',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Passcode Dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              6,
                              (index) {
                                final currentPasscode =
                                    _isConfirming ? _confirmPasscode : _passcode;
                                final isFilled = index < currentPasscode.length;

                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isFilled
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isFilled
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Number Pad
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            children: [
                              ...List.generate(9, (index) {
                                final number = (index + 1).toString();
                                return _buildNumberButton(number);
                              }),
                              const SizedBox(), // Empty space
                              _buildNumberButton('0'),
                              _buildDeleteButton(),
                            ],
                          ),

                          if (_isLoading) ...[
                            const SizedBox(height: 24),
                            const CircularProgressIndicator(),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]
                                : Colors.grey[300],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]
                                : Colors.grey[300],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Biometric Option
                    if (_biometricAvailable)
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _setupBiometric,
                        icon: const Icon(Icons.fingerprint, size: 32),
                        label: const Text(
                          'Use Biometric Authentication',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Right side - Hero Section (only show on desktop)
          if (isDesktop)
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
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
                          Icons.security,
                          size: 120,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Enhanced Security',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Choose between a 6-digit passcode or biometric authentication for quick and secure access to your account.',
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

  Widget _buildNumberButton(String number) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _onNumberPressed(number),
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            number,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _onDeletePressed,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 28,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
