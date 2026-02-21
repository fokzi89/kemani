
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/staff.dart'; // Import the Staff model

class StaffService {
  final SupabaseClient _supabase;

  StaffService(this._supabase);

  // --- CRUD Operations for Staff ---

  /// Creates a new staff member in Supabase.
  Future<void> createStaff(Staff staff) async {
    await _supabase.from('staff').insert(staff.toJson());
  }

  /// Fetches a single staff member by ID from Supabase.
  Future<Staff?> getStaffById(String id) async {
    final response = await _supabase.from('staff').select().eq('id', id).single();
    if (response.error != null) {
      // Handle error, e.g., throw exception or return null
      return null;
    }
    return Staff.fromJson(response.data);
  }

  /// Fetches all staff members from Supabase.
  Future<List<Staff>> getAllStaff() async {
    final response = await _supabase.from('staff').select();
    if (response.error != null) {
      // Handle error
      return [];
    }
    final data = response.data as List;
    return data.map((json) => Staff.fromJson(json)).toList();
  }

  /// Updates an existing staff member in Supabase.
  Future<void> updateStaff(Staff staff) async {
    await _supabase.from('staff').update(staff.toJson()).eq('id', staff.id);
  }

  /// Deletes a staff member from Supabase.
  Future<void> deleteStaff(String id) async {
    await _supabase.from('staff').delete().eq('id', id);
  }
}

// Provider for StaffService
final staffServiceProvider = Provider<StaffService>((ref) {
  final supabase = Supabase.instance.client;
  return StaffService(supabase);
});

// Provider to manage the staff list state
final staffListProvider = StateNotifierProvider<StaffListNotifier, List<Staff>>((ref) {
  return StaffListNotifier(ref.watch(staffServiceProvider));
});

class StaffListNotifier extends StateNotifier<List<Staff>> {
  final StaffService _staffService;

  StaffListNotifier(this._staffService) : super([]) {
    // Initial fetch of staff list
    _staffService.getAllStaff().then((staffList) {
      state = staffList;
    });
  }

  Future<void> refresh() async {
    state = await _staffService.getAllStaff();
  }

  Future<void> addStaff(Staff staff) async {
    await _staffService.createStaff(staff);
    await refresh();
  }

  Future<void> updateStaff(Staff staff) async {
    await _staffService.updateStaff(staff);
    await refresh();
  }

  Future<void> deleteStaff(String id) async {
    await _staffService.deleteStaff(id);
    await refresh();
  }
}
