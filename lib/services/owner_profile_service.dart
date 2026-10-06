import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/owner_profile.dart';

/// Service managing all Owner Profile CRUD operations against Firestore.
/// Each owner has exactly one profile document keyed by their userId.
class OwnerProfileService {
  static final OwnerProfileService _instance = OwnerProfileService._internal();
  factory OwnerProfileService() => _instance;
  OwnerProfileService._internal();

  static const String collectionName = 'owner_profile';

  // In-memory cache — keeps profile available even when offline.
  final Map<String, OwnerProfile> _cache = {};

  CollectionReference<Map<String, dynamic>>? get _collection {
    try {
      return FirebaseFirestore.instance.collection(collectionName);
    } catch (_) {
      return null;
    }
  }

  // ─── CREATE ────────────────────────────────────────────────────────────────

  /// Creates a new owner profile. Uses [userId] as the Firestore document ID
  /// for O(1) lookups without extra queries.
  Future<OwnerProfile> createProfile(OwnerProfile profile) async {
    final now = DateTime.now();
    final toSave = profile.copyWith(
      id: profile.userId,
      createdAt: now,
      updatedAt: now,
    );

    _cache[toSave.userId] = toSave;

    final col = _collection;
    if (col != null) {
      try {
        await col.doc(toSave.userId).set(toSave.toMap());
        debugPrint('[OwnerProfileService] profile created: ${toSave.userId}');
      } catch (e) {
        debugPrint('[OwnerProfileService] create warning (cached): $e');
      }
    }

    return toSave;
  }

  // ─── READ ──────────────────────────────────────────────────────────────────

  /// Loads the profile for [userId]. Returns null if not yet created.
  Future<OwnerProfile?> getProfile(String userId) async {
    if (_cache.containsKey(userId)) return _cache[userId];

    final col = _collection;
    if (col != null) {
      try {
        final doc = await col.doc(userId).get();
        if (doc.exists && doc.data() != null) {
          final profile = OwnerProfile.fromMap(doc.data()!, doc.id);
          _cache[userId] = profile;
          return profile;
        }
      } catch (e) {
        debugPrint('[OwnerProfileService] read error: $e');
      }
    }

    return _cache[userId];
  }

  /// Real-time stream of the owner's profile document.
  Stream<OwnerProfile?> profileStream(String userId) {
    final col = _collection;
    if (col == null) {
      return Stream.value(_cache[userId]);
    }

    return col.doc(userId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return _cache[userId];
      final profile = OwnerProfile.fromMap(snap.data()!, snap.id);
      _cache[userId] = profile;
      return profile;
    }).handleError((error) {
      debugPrint('[OwnerProfileService] stream error: $error');
      return _cache[userId];
    });
  }

  // ─── UPDATE ────────────────────────────────────────────────────────────────

  /// Saves all editable fields of a profile.
  Future<OwnerProfile> updateProfile(OwnerProfile profile) async {
    final updated = profile.copyWith(updatedAt: DateTime.now());
    _cache[updated.userId] = updated;

    final col = _collection;
    if (col != null) {
      try {
        await col.doc(updated.userId).update(updated.toMap());
        debugPrint('[OwnerProfileService] profile updated: ${updated.userId}');
      } catch (e) {
        // If doc doesn't exist yet, create it
        try {
          await col.doc(updated.userId).set(updated.toMap());
        } catch (e2) {
          debugPrint('[OwnerProfileService] update warning (cached): $e2');
        }
      }
    }

    return updated;
  }

  /// Updates only the profile image field.
  Future<OwnerProfile?> updateProfileImage(
    String userId,
    String imageData,
  ) async {
    final existing = await getProfile(userId);
    if (existing == null) return null;
    return updateProfile(existing.copyWith(profileImage: imageData));
  }

  // ─── DELETE / DEACTIVATE ───────────────────────────────────────────────────

  /// Soft-delete: marks profile as inactive (`is_active = false`).
  /// The document remains in Firestore but the owner is treated as deactivated.
  Future<OwnerProfile?> deactivateProfile(String userId) async {
    final existing = await getProfile(userId);
    if (existing == null) return null;

    final deactivated = existing.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );
    _cache[userId] = deactivated;

    final col = _collection;
    if (col != null) {
      try {
        await col.doc(userId).update({
          'is_active': false,
          'updated_at': Timestamp.fromDate(deactivated.updatedAt),
        });
        debugPrint('[OwnerProfileService] profile deactivated: $userId');
      } catch (e) {
        debugPrint('[OwnerProfileService] deactivate error: $e');
      }
    }

    return deactivated;
  }

  /// Hard-delete: permanently removes the profile document from Firestore.
  Future<void> deleteProfile(String userId) async {
    _cache.remove(userId);

    final col = _collection;
    if (col != null) {
      try {
        await col.doc(userId).delete();
        debugPrint('[OwnerProfileService] profile deleted: $userId');
      } catch (e) {
        debugPrint('[OwnerProfileService] delete error: $e');
      }
    }
  }

  /// Reactivates a previously deactivated profile.
  Future<OwnerProfile?> reactivateProfile(String userId) async {
    final existing = await getProfile(userId);
    if (existing == null) return null;
    return updateProfile(existing.copyWith(isActive: true));
  }

  /// Clears local cache entry (forces next read from Firestore).
  void invalidateCache(String userId) => _cache.remove(userId);
}
