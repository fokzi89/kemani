import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_widgets.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // Note: Actual OTP logic to be connected to provider when implemented
  // Currently AuthNotifier in auth_provider.dart has signIn/Up but needs verifyOtp wrapper.
  // For now, will add verifyOtp to AuthNotifier or call service directly if provider not updated yet.
  // Assuming AuthNotifier will have it.

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    // TODO: Implement OTP verification via provider
    // await ref.read(authProvider.notifier).verifyOtp(
    //   phone: widget.phoneNumber,
    //   token: _otpController.text
    // );
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
                          "Enter OTP",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text("A code has been sent to ${widget.phoneNumber}"),
                        const SizedBox(height: 32),

                        AuthTextField(
                          controller: _otpController,
                          label: "OTP Code",
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.lock_clock,
                          validator: (val) =>
                              val?.length != 6 ? "Enter 6-digit code" : null,
                        ),

                        const SizedBox(height: 24),

                        AuthButton(text: "Verify", onPressed: _verify),

                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text("Use different number"),
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
                  quote: "Security is our top priority.",
                  authorName: "System",
                  authorTitle: "Automated Message",
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
