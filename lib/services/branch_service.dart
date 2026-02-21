import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch.dart';

class BranchService {
  final SupabaseClient _supabase;

  BranchService(this._supabase);

  /// Fetches all branches from Supabase.
  Future<List<Branch>> getAllBranches() async {
    final response = await _supabase.from('branches').select();
    if (response.error != null) {
      throw Exception('Failed to load branches: ${response.error!.message}');
    }
    final data = response.data as List;
    return data.map((json) => Branch.fromJson(json)).toList();
  }

  /// Creates a new branch.
  Future<void> createBranch(Branch branch) async {
    await _supabase.from('branches').insert(branch.toJson());
  }

  /// Updates an existing branch.
  Future<void> updateBranch(Branch branch) async {
    await _supabase.from('branches').update(branch.toJson()).eq('id', branch.id);
  }

  /// Deletes a branch.
  Future<void> deleteBranch(String id) async {
    await _supabase.from('branches').delete().eq('id', id);
  }
}

// Provider for BranchService
final branchServiceProvider = Provider<BranchService>((ref) {
  final supabase = Supabase.instance.client;
  return BranchService(supabase);
});

// Provider to manage the branch list state
final branchListProvider = StateNotifierProvider<BranchListNotifier, List<Branch>>((ref) {
  return BranchListNotifier(ref.watch(branchServiceProvider));
});

class BranchListNotifier extends StateNotifier<List<Branch>> {
  final BranchService _branchService;

  BranchListNotifier(this._branchService) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      state = await _branchService.getAllBranches();
    } catch (e) {
      // Handle or log error appropriately
      print(e);
      state = [];
    }
  }

  Future<void> addBranch(Branch branch) async {
    await _branchService.createBranch(branch);
    await refresh();
  }

  Future<void> updateBranch(Branch branch) async {
    await _branchService.updateBranch(branch);
    await refresh();
  }

  Future<void> deleteBranch(String id) async {
    await _branchService.deleteBranch(id);
    await refresh();
  }
}
