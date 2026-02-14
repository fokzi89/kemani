import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/staff_member.dart';

class StaffService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<StaffMember>> getStaff() async {
    final response = await _supabase
        .from('users')
        .select()
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data.map((json) => StaffMember.fromJson(json)).toList();
  }

  Future<List<StaffInvitation>> getInvitations() async {
    final response = await _supabase
        .from('staff_invitations')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data.map((json) => StaffInvitation.fromJson(json)).toList();
  }

  Future<void> inviteStaff({
    required String email,
    required String fullName,
    required UserRole role,
    String? branchId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Unauthorized');

    // Fetch current user tenant_id (or store in session metadata)
    final currentUserData = await _supabase
        .from('users')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    final tenantId = currentUserData['tenant_id'];

    // Generate token
    // Note: crypto package needed for proper random bytes, using simplified timestamp for POC
    final token = DateTime.now().millisecondsSinceEpoch.toString();

    await _supabase.from('staff_invitations').insert({
      'tenant_id': tenantId,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'branch_id': branchId,
      'invited_by': user.id,
      'invitation_token': token,
      'expires_at': DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String(),
    });

    // Note: Email sending is expected to be handled by a Database Webhook or Edge Function
    // listening to 'staff_invitations' inserts.
  }

  Future<void> revokeInvitation(String invitationId) async {
    await _supabase
        .from('staff_invitations')
        .update({'status': 'revoked'})
        .eq('id', invitationId);
  }
}
