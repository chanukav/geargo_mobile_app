import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_config.dart';

/// Service dedicated to uploading and managing images stored in Supabase Storage.
class SupabaseStorageService {
  SupabaseStorageService._();

  static SupabaseClient? get _client {
    try {
      if (SupabaseConfig.isConfigured) {
        return Supabase.instance.client;
      }
    } catch (_) {
      // Supabase not yet initialized
    }
    return null;
  }

  /// Uploads equipment image bytes to Supabase Storage and returns the public CDN URL.
  ///
  /// Throws [StateError] if Supabase is not configured or client is unavailable.
  static Future<String> uploadEquipmentImage({
    required String equipmentId,
    required Uint8List bytes,
    String? ownerId,
    String contentType = 'image/jpeg',
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase is not initialized. Please configure url & anonKey in supabase_config.dart',
      );
    }

    if (bytes.isEmpty) {
      throw ArgumentError('Cannot upload empty image bytes.');
    }

    // Limit to 5MB
    if (bytes.length > 5 * 1024 * 1024) {
      throw StateError('Equipment photo must be under 5 MB.');
    }

    final sanitizedOwner = (ownerId != null && ownerId.trim().isNotEmpty)
        ? ownerId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        : 'general';
    final sanitizedId = equipmentId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = 'equipments/$sanitizedOwner/$sanitizedId-$timestamp.jpg';

    debugPrint('Uploading equipment image to Supabase Storage: $filePath (${bytes.lengthInBytes} bytes)...');

    // Upload to public bucket
    try {
      await client.storage.from(SupabaseConfig.equipmentBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );
    } catch (e) {
      debugPrint('Supabase Storage uploadBinary failed: $e');
      throw StateError(
        'Failed to upload image to Supabase Storage bucket "${SupabaseConfig.equipmentBucket}": $e. '
        'Please ensure the "${SupabaseConfig.equipmentBucket}" public bucket exists in your Supabase project.',
      );
    }

    // Retrieve direct public CDN URL
    final publicUrl = client.storage
        .from(SupabaseConfig.equipmentBucket)
        .getPublicUrl(filePath);

    debugPrint('Successfully uploaded equipment image to Supabase! Public URL: $publicUrl');
    return publicUrl;
  }

  /// Deletes an equipment image from Supabase Storage by its public URL (optional cleanup).
  static Future<void> deleteImageByUrl(String publicUrl) async {
    final client = _client;
    if (client == null) return;

    try {
      final marker = '/${SupabaseConfig.equipmentBucket}/';
      if (!publicUrl.contains(marker)) return;

      final path = publicUrl.split(marker).last;
      await client.storage.from(SupabaseConfig.equipmentBucket).remove([path]);
      debugPrint('Removed old equipment image from Supabase: $path');
    } catch (e) {
      debugPrint('Error deleting image from Supabase: $e');
    }
  }
}
