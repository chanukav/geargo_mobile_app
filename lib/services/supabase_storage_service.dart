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

  /// In-memory mock storage for testing environments when Supabase client is offline.
  @visibleForTesting
  static final Map<String, Uint8List> mockProfileStorage = {};

  /// Uploads a profile image into Supabase Storage in the dedicated 'profile image' folder.
  /// Returns the public CDN URL.
  ///
  /// Folder in Supabase Storage: 'profile image'
  static Future<String> uploadProfileImage({
    required String userId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError('Cannot upload empty profile image bytes.');
    }

    if (bytes.length > 5 * 1024 * 1024) {
      throw StateError('Profile photo must be under 5 MB.');
    }

    final sanitizedId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${SupabaseConfig.profileImageFolder}/$sanitizedId-$timestamp.jpg';

    final client = _client;
    if (client == null) {
      // Offline / Test mock fallback
      mockProfileStorage[filePath] = bytes;
      final mockUrl =
          '${SupabaseConfig.url}/storage/v1/object/public/${SupabaseConfig.profileBucket}/$filePath';
      debugPrint('[SupabaseStorageService] (Mock) Stored profile image: $mockUrl');
      return mockUrl;
    }

    debugPrint('Uploading profile image to Supabase Storage: $filePath (${bytes.lengthInBytes} bytes)...');

    try {
      await client.storage.from(SupabaseConfig.profileBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );
    } catch (e) {
      debugPrint('Supabase profile image uploadBinary failed: $e');
      throw StateError(
        'Failed to upload profile image to Supabase Storage: $e. '
        'Folder: "${SupabaseConfig.profileImageFolder}" in bucket "${SupabaseConfig.profileBucket}".',
      );
    }

    final publicUrl = client.storage
        .from(SupabaseConfig.profileBucket)
        .getPublicUrl(filePath);

    debugPrint('Successfully uploaded profile image to Supabase! Public URL: $publicUrl');
    return publicUrl;
  }

  /// Reads/constructs the public CDN URL for a profile image in the 'profile image' folder.
  static String getProfileImageUrl(String filePathOrUrl) {
    if (filePathOrUrl.startsWith('http://') ||
        filePathOrUrl.startsWith('https://')) {
      return filePathOrUrl;
    }
    final client = _client;
    if (client == null) {
      return '${SupabaseConfig.url}/storage/v1/object/public/${SupabaseConfig.profileBucket}/$filePathOrUrl';
    }
    return client.storage
        .from(SupabaseConfig.profileBucket)
        .getPublicUrl(filePathOrUrl);
  }

  /// Downloads profile image bytes from Supabase Storage (CRUD Read).
  static Future<Uint8List?> downloadProfileImage(String filePathOrUrl) async {
    final client = _client;
    if (client == null) {
      // Check in mock storage
      for (final entry in mockProfileStorage.entries) {
        if (filePathOrUrl.contains(entry.key)) {
          return entry.value;
        }
      }
      return null;
    }

    try {
      final marker = '/${SupabaseConfig.profileBucket}/';
      final path = filePathOrUrl.contains(marker)
          ? filePathOrUrl.split(marker).last
          : filePathOrUrl;
      return await client.storage.from(SupabaseConfig.profileBucket).download(path);
    } catch (e) {
      debugPrint('[SupabaseStorageService] Error downloading profile image: $e');
      return null;
    }
  }

  /// Updates a user's profile image in the 'profile image' folder (CRUD Update).
  /// Automatically purges the previous image from Supabase Storage if [oldUrl] is provided.
  static Future<String> updateProfileImage({
    required String userId,
    required Uint8List bytes,
    String? oldUrl,
    String contentType = 'image/jpeg',
  }) async {
    if (oldUrl != null && oldUrl.trim().isNotEmpty) {
      try {
        await deleteProfileImage(userId: userId, photoUrl: oldUrl);
      } catch (e) {
        debugPrint('[SupabaseStorageService] Warning deleting previous profile image: $e');
      }
    }

    return uploadProfileImage(
      userId: userId,
      bytes: bytes,
      contentType: contentType,
    );
  }

  /// Deletes a profile image from Supabase Storage in the 'profile image' folder (CRUD Delete).
  static Future<void> deleteProfileImage({
    required String userId,
    String? photoUrl,
  }) async {
    if (photoUrl == null || photoUrl.trim().isEmpty) return;

    final client = _client;
    if (client == null) {
      mockProfileStorage.removeWhere((k, _) => photoUrl.contains(k));
      debugPrint('[SupabaseStorageService] (Mock) Deleted profile image: $photoUrl');
      return;
    }

    try {
      final marker = '/${SupabaseConfig.profileBucket}/';
      String path;
      if (photoUrl.contains(marker)) {
        path = Uri.decodeComponent(photoUrl.split(marker).last);
      } else if (photoUrl.contains(SupabaseConfig.profileImageFolder)) {
        path = Uri.decodeComponent(photoUrl.substring(
            photoUrl.indexOf(SupabaseConfig.profileImageFolder)));
      } else {
        path = photoUrl;
      }

      await client.storage.from(SupabaseConfig.profileBucket).remove([path]);
      debugPrint('[SupabaseStorageService] Deleted profile image from Supabase: $path');
    } catch (e) {
      debugPrint('[SupabaseStorageService] Error deleting profile image from Supabase: $e');
    }
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
