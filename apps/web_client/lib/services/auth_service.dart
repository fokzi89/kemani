import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign up a new user with email confirmation required
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
      emailRedirectTo:
          'http://localhost:8080/login', // Redirect to login after confirmation
    );
  }

  // Sign in existing user
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign in with phone OTP
  Future<void> signInWithOtp(String phone) async {
    await _supabase.auth.signInWithOtp(phone: phone);
  }

  // Verify phone OTP
  Future<AuthResponse> verifyOtp(String phone, String token) async {
    return await _supabase.auth.verifyOTP(
      token: token,
      type: OtpType.sms,
      phone: phone,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Stream auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Validate invitation token
  Future<Map<String, dynamic>?> validateInvitation(String token) async {
    try {
      final response = await _supabase
          .from('staff_invitations')
          .select()
          .eq('invitation_token', token)
          .eq('status', 'pending')
          .gt(
            'expires_at',
            DateTime.now().toIso8601String(),
          ) // Ensure not expired
          .maybeSingle();
      return response;
    } catch (e) {
      // Handle error or return null
      return null;
    }
  }

  // Accept invitation and create account
  Future<AuthResponse> acceptInvitation({
    required String token,
    required String password,
    required Map<String, dynamic> invitationData,
  }) async {
    final email = invitationData['email'];
    final fullName = invitationData['full_name'];

    // 1. Sign up user
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    final user = authResponse.user;
    if (user == null) {
      throw Exception('Failed to create user account');
    }

    // 2. Update users table with tenant details (if not handled by trigger)
    // We assume there might be a trigger, but explicitly updating ensures consistency
    await _supabase
        .from('users')
        .update({
          'tenant_id': invitationData['tenant_id'],
          'role': invitationData['role'],
          'branch_id': invitationData['branch_id'],
          'full_name': fullName, // redundancy but safe
        })
        .eq('id', user.id);

    // 3. Mark invitation as accepted
    await _supabase
        .from('staff_invitations')
        .update({
          'status': 'accepted',
          // 'accepted_at': DateTime.now().toIso8601String(), // if column exists
        })
        .eq('id', invitationData['id']);

    return authResponse;
  }

  // Verify passcode (Placeholder for backend verification)
  Future<bool> verifyPasscode(String passcode) async {
    // TODO: Call Edge Function or verify hash locally if possible
    // For now, return true to simulate success
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Check if user has passcode set
  Future<bool> hasPasscode() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final data = await _supabase
          .from('users')
          .select('passcode_hash')
          .eq('id', user.id)
          .single();

      return data['passcode_hash'] != null &&
          (data['passcode_hash'] as String).isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
