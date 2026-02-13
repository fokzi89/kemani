import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/onboarding_models.dart';

class OnboardingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Save user profile information (Step 1)
  Future<void> saveProfile(ProfileData data) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.functions.invoke(
      'onboarding-profile',
      body: data.toJson(),
    );

    if (response.status != 200) {
      throw Exception('Failed to save profile: ${response.data}');
    }
  }

  /// Save company information (Step 2)
  /// Creates tenant, default branch, and links user
  Future<void> saveCompany(CompanyData data) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.functions.invoke(
      'onboarding-company',
      body: data.toJson(),
    );

    if (response.status != 200) {
      throw Exception('Failed to save company: ${response.data}');
    }
  }

  /// Setup passcode (Step 3)
  Future<void> setupPasscode(String passcode) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.functions.invoke(
      'onboarding-passcode',
      body: {'passcode': passcode},
    );

    if (response.status != 200) {
      throw Exception('Failed to setup passcode: ${response.data}');
    }
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.functions.invoke('onboarding-complete');

    if (response.status != 200) {
      throw Exception('Failed to complete onboarding: ${response.data}');
    }
  }

  /// Get current onboarding status for the logged-in user
  Future<OnboardingStatus> getOnboardingStatus() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return OnboardingStatus(isComplete: false);
    }

    try {
      final response = await _supabase
          .from('users')
          .select('onboarding_completed_at, tenant_id, role')
          .eq('id', userId)
          .single();

      return OnboardingStatus(
        isComplete: response['onboarding_completed_at'] != null,
        completedAt: response['onboarding_completed_at'] != null
            ? DateTime.parse(response['onboarding_completed_at'])
            : null,
        tenantId: response['tenant_id'],
        role: response['role'],
      );
    } catch (e) {
      print('Error getting onboarding status: $e');
      return OnboardingStatus(isComplete: false);
    }
  }
}
