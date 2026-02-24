import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => _client;

  // Auth helpers
  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Consultations
  Future<List<Map<String, dynamic>>> getConsultations() async {
    final response = await _client
        .from('consultations')
        .select()
        .eq('provider_id', currentUser!.id)
        .order('scheduled_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createConsultation(Map<String, dynamic> consultation) async {
    await _client.from('consultations').insert(consultation);
  }

  Future<void> updateConsultation(String id, Map<String, dynamic> updates) async {
    await _client.from('consultations').update(updates).eq('id', id);
  }

  // Patients
  Future<List<Map<String, dynamic>>> getPatients() async {
    final response = await _client.from('patients').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getPatient(String patientId) async {
    final response = await _client.from('patients').select().eq('id', patientId).single();
    return response;
  }

  // Consultation Notes
  Future<List<Map<String, dynamic>>> getConsultationNotes(String consultationId) async {
    final response = await _client
        .from('consultation_notes')
        .select()
        .eq('consultation_id', consultationId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addConsultationNote(Map<String, dynamic> note) async {
    await _client.from('consultation_notes').insert(note);
  }

  // Appointments
  Future<List<Map<String, dynamic>>> getAppointments() async {
    final response = await _client
        .from('appointments')
        .select()
        .eq('provider_id', currentUser!.id)
        .order('scheduled_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createAppointment(Map<String, dynamic> appointment) async {
    await _client.from('appointments').insert(appointment);
  }

  Future<void> updateAppointment(String id, Map<String, dynamic> updates) async {
    await _client.from('appointments').update(updates).eq('id', id);
  }

  // Healthcare Provider Profile
  Future<Map<String, dynamic>?> getProviderProfile() async {
    final response = await _client
        .from('healthcare_providers')
        .select()
        .eq('user_id', currentUser!.id)
        .single();
    return response;
  }

  Future<void> updateProviderProfile(Map<String, dynamic> updates) async {
    await _client
        .from('healthcare_providers')
        .update(updates)
        .eq('user_id', currentUser!.id);
  }
}
