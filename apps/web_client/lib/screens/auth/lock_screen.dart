import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/auth_widgets.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _passcodeController = TextEditingController();
  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyPasscode() async {
    if (_passcodeController.text.length != 6) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final service = OnboardingService();
      final isValid = await service.verifyPasscode(_passcodeController.text);

      if (mounted) {
        if (isValid) {
          context.go('/dashboard');
        } else {
          setState(() {
            _error = 'Incorrect passcode';
            _passcodeController.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'An error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDigitPress(String digit) {
    if (_passcodeController.text.length < 6) {
      setState(() {
        _passcodeController.text += digit;
        _error = '';
      });
      if (_passcodeController.text.length == 6) {
        _verifyPasscode();
      }
    }
  }

  void _onBackspace() {
    if (_passcodeController.text.isNotEmpty) {
      setState(() {
        _passcodeController.text = _passcodeController.text.substring(
          0,
          _passcodeController.text.length - 1,
        );
        _error = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Enter Passcode',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  _error.isNotEmpty ? _error : 'Unlock to continue',
                  style: TextStyle(
                    color: _error.isNotEmpty ? Colors.red : Colors.grey,
                  ),
                ),
              const SizedBox(height: 32),

              // Dots display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _passcodeController.text.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                      border: isFilled
                          ? null
                          : Border.all(color: Colors.grey.shade400),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 48),

              // Keypad
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) return const SizedBox(); // Empty space
                  if (index == 11) {
                    return InkWell(
                      onTap: _onBackspace,
                      borderRadius: BorderRadius.circular(40),
                      child: const Center(
                        child: Icon(Icons.backspace_outlined),
                      ),
                    );
                  }

                  final digit = index == 10 ? '0' : '${index + 1}';
                  return InkWell(
                    onTap: () => _onDigitPress(digit),
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(
                          digit,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  // Handle forgot passcode flow (e.g. sign out)
                  context.go('/login');
                },
                child: const Text('Forgot Passcode? Sign in again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
