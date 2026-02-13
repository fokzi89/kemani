import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload profile picture to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadProfilePicture(File imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Generate unique filename
    final extension = path.extension(imageFile.path);
    final fileName =
        '$userId-${DateTime.now().millisecondsSinceEpoch}$extension';
    final filePath = 'profile-pictures/$fileName';

    // Upload to Supabase Storage
    await _supabase.storage
        .from('profile-pictures')
        .upload(filePath, imageFile);

    // Get public URL
    final publicUrl = _supabase.storage
        .from('profile-pictures')
        .getPublicUrl(filePath);

    return publicUrl;
  }

  /// Upload company logo to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadLogo(File imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Generate unique filename
    final extension = path.extension(imageFile.path);
    final fileName =
        '$userId-${DateTime.now().millisecondsSinceEpoch}$extension';
    final filePath = 'logos/$fileName';

    // Upload to Supabase Storage
    await _supabase.storage.from('logos').upload(filePath, imageFile);

    // Get public URL
    final publicUrl = _supabase.storage.from('logos').getPublicUrl(filePath);

    return publicUrl;
  }

  /// Delete a file from storage
  Future<void> deleteFile(String bucket, String filePath) async {
    await _supabase.storage.from(bucket).remove([filePath]);
  }
}
