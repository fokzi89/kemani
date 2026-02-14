import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import '../../theme.dart';
import 'login_screen.dart';

class AcceptInvitationScreen extends StatefulWidget {
  final String? initialToken;

  const AcceptInvitationScreen({super.key, this.initialToken});

  @override
  State<AcceptInvitationScreen> createState() => _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState extends State<AcceptInvitationScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isVerified = false;
  Map<String, dynamic>? _invitationData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) {
      _tokenController.text = widget.initialToken!;
      // Optionally auto-verify if token is passed
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _tokenController.text.trim();
      if (token.isEmpty) {
        throw Exception('Please enter an invitation code');
      }

      final data = await _authService.validateInvitation(token);
      if (data != null) {
        setState(() {
          _invitationData = data;
          _isVerified = true;
        });
      } else {
        throw Exception('Invalid or expired invitation code');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptInvitation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_invitationData == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.acceptInvitation(
        token: _tokenController.text.trim(),
        password: _passwordController.text.trim(),
        invitationData: _invitationData!,
      );

      if (mounted) {
        // Navigate to Login or Dashboard
        // For now, let's go to Login with a success message, or directly to onboarding
        // The Spec says: Step 2 - Profile Setup. So we should log them in (done by signUp usually?)
        // If signUp doesn't auto-login (depends on config/confirm), we might need to signIn.
        // Assuming Supabase auto-signs in or we can redirect to Login.
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Please log in.')),
        );
         Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Accept Invitation',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.red.shade100,
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (!_isVerified) ...[
                        AuthTextField(
                          controller: _tokenController,
                          label: 'Invitation Code',
                          prefixIcon: Icons.vpn_key,
                        ),
                        const SizedBox(height: 24),
                        AuthButton(
                          text: 'Verify Code',
                          onPressed: _verifyToken,
                          isLoading: _isLoading,
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome, ${_invitationData!['full_name']}'),
                              Text(
                                '${_invitationData!['email']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        AuthTextField(
                          controller: _passwordController,
                          label: 'Set Password',
                          prefixIcon: Icons.lock,
                          obscureText: true,
                          validator: (val) =>
                              (val?.length ?? 0) < 6 ? 'Min 6 chars' : null,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          prefixIcon: Icons.lock_clock,
                          obscureText: true,
                          validator: (val) => val != _passwordController.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        AuthButton(
                          text: 'Create Account',
                          onPressed: _acceptInvitation,
                          isLoading: _isLoading,
                        ),
                      ],
                       const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text('Back to Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
