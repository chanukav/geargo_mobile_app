import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/owner_profile.dart';
import 'owner_profile_service.dart';
import 'supabase_storage_service.dart';

/// Central database service for user data across all personas:
/// Renter, Gear Owner, Commercial Shop, and Platform Administrator.
///
/// Handles database persistence in Firestore and profile image
/// CRUD operations in Supabase Storage under the 'profile image' folder.
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return UserService._internal(firestore: firestore);
    }
    return _instance;
  }

  UserService._internal({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  // In-memory user store for fast lookup and headless test environments
  final Map<String, AppUser> _memoryUsers = {};

  FirebaseFirestore? get _safeFirestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Saves or updates any persona's user data in the Firestore 'users' collection.
  Future<AppUser> saveUserData(AppUser user) async {
    final updated = user.copyWith(updatedAt: DateTime.now());
    _memoryUsers[updated.uid] = updated;

    final fs = _safeFirestore;
    if (fs != null) {
      try {
        await fs.collection('users').doc(updated.uid).set(
              updated.toMap(),
              SetOptions(merge: true),
            );
        debugPrint(
            '[UserService] Successfully saved persona ${updated.role.name} for ${updated.uid} in database');
      } catch (e) {
        debugPrint('[UserService] Firestore write error for ${updated.uid}: $e');
      }
    }

    // Mirror to OwnerProfile if persona is Owner or Commercial Shop
    if (updated.isOwner || updated.isCommercialShop) {
      try {
        await _syncOwnerProfile(updated);
      } catch (e) {
        debugPrint('[UserService] OwnerProfile sync warning: $e');
      }
    }

    return updated;
  }

  /// Reads user persona data by [uid] from the database.
  Future<AppUser?> getUserData(String uid) async {
    final fs = _safeFirestore;
    if (fs != null) {
      try {
        final doc = await fs.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final user = AppUser.fromMap(doc.data()!, uid);
          _memoryUsers[uid] = user;
          return user;
        }
      } catch (e) {
        debugPrint('[UserService] Firestore read error for $uid: $e');
      }
    }

    return _memoryUsers[uid];
  }

  /// Real-time stream of user persona data from Firestore.
  Stream<AppUser?> getUserStream(String uid) {
    final fs = _safeFirestore;
    if (fs == null) {
      return Stream.value(_memoryUsers[uid]);
    }

    return fs.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return _memoryUsers[uid];
      }
      final user = AppUser.fromMap(doc.data()!, uid);
      _memoryUsers[uid] = user;
      return user;
    });
  }

  /// Uploads or updates a user's profile image in Supabase Storage ('profile image' folder),
  /// then updates the user document in the database with the new CDN URL.
  Future<AppUser> updateProfilePhoto({
    required String userId,
    required Uint8List bytes,
    AppUser? currentUser,
    String contentType = 'image/jpeg',
  }) async {
    final user = currentUser ?? await getUserData(userId) ?? AppUser(uid: userId);

    // 1. Upload to Supabase Storage in folder 'profile image'
    final publicUrl = await SupabaseStorageService.updateProfileImage(
      userId: userId,
      bytes: bytes,
      oldUrl: user.photoUrl,
      contentType: contentType,
    );

    // 2. Update user data in the database with the Supabase CDN URL
    final updatedUser = user.copyWith(
      photoUrl: publicUrl,
      updatedAt: DateTime.now(),
    );

    await saveUserData(updatedUser);
    debugPrint(
        '[UserService] Updated profile photo for $userId in Supabase Storage and database.');
    return updatedUser;
  }

  /// Deletes a user's profile image from Supabase Storage ('profile image' folder),
  /// and clears the profile image URL in the database document.
  Future<AppUser> deleteProfilePhoto({
    required String userId,
    AppUser? currentUser,
  }) async {
    final user = currentUser ?? await getUserData(userId) ?? AppUser(uid: userId);

    // 1. Delete from Supabase Storage in folder 'profile image'
    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      await SupabaseStorageService.deleteProfileImage(
        userId: userId,
        photoUrl: user.photoUrl,
      );
    }

    // 2. Clear photo_url in database
    final updatedUser = user.copyWith(
      photoUrl: '',
      updatedAt: DateTime.now(),
    );

    await saveUserData(updatedUser);
    debugPrint(
        '[UserService] Deleted profile photo for $userId from Supabase Storage and cleared in database.');
    return updatedUser;
  }

  /// Retrieves all users matching a specific persona [role].
  Future<List<AppUser>> getUsersByPersona(UserRole role) async {
    final fs = _safeFirestore;
    if (fs != null) {
      try {
        final query = await fs
            .collection('users')
            .where('role', isEqualTo: role.storageValue)
            .get();
        return query.docs.map((d) => AppUser.fromMap(d.data(), d.id)).toList();
      } catch (e) {
        debugPrint('[UserService] Query users by role error: $e');
      }
    }

    return _memoryUsers.values.where((u) => u.role == role).toList();
  }

  /// Seeds default users representing every platform persona:
  /// Renter, Gear Owner, Commercial Shop, and Administrator.
  Future<void> seedPersonaUsers() async {
    final personas = [
      AppUser(
        uid: 'user_renter_maya',
        email: 'maya.chen@example.com',
        displayName: 'Maya Chen',
        photoUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
        role: UserRole.renter,
        phoneNumber: '+94 77 234 5678',
        bio: 'Avid weekend hiker, trail runner, and outdoor enthusiast.',
        address: 'Colombo 07, Sri Lanka',
        isVerified: true,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now(),
      ),
      AppUser(
        uid: 'owner_default',
        email: 'marcus.vance@example.com',
        displayName: 'Marcus Vance',
        photoUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
        role: UserRole.owner,
        phoneNumber: '+94 71 345 6789',
        bio:
            'Passionate mountain biker & gear collector. All equipment tuned before handover.',
        address: 'Kandy, Sri Lanka',
        businessName: 'Vance Trail Rentals',
        isVerified: true,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        updatedAt: DateTime.now(),
      ),
      AppUser(
        uid: 'user_shop_apex',
        email: 'rentals@apexadventure.com',
        displayName: 'Apex Mountain Gear',
        photoUrl:
            'https://images.unsplash.com/photo-1556742049-0a67e557224f?auto=format&fit=crop&w=400&q=80',
        role: UserRole.commercialShop,
        phoneNumber: '+94 11 890 1234',
        bio:
            'Commercial full-service rental depot offering fleet bikes, surfboards, and camping gear.',
        address: 'Nuwara Eliya, Sri Lanka',
        businessName: 'Apex Mountain Gear Commercial Depot',
        isVerified: true,
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
        updatedAt: DateTime.now(),
      ),
      AppUser(
        uid: 'user_admin_elena',
        email: 'admin.elena@geargo.com',
        displayName: 'Elena Rostova',
        photoUrl:
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
        role: UserRole.admin,
        phoneNumber: '+94 11 999 0001',
        bio: 'GearGo platform trust, safety, and operations administrator.',
        address: 'Colombo 03, Sri Lanka',
        businessName: 'GearGo Platform Operations',
        isVerified: true,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final persona in personas) {
      await saveUserData(persona);
    }
  }

  Future<void> _syncOwnerProfile(AppUser user) async {
    final existing = await OwnerProfileService().getProfile(user.uid);
    final now = DateTime.now();

    final profile = OwnerProfile(
      id: user.uid,
      userId: user.uid,
      name: user.displayName ?? 'Gear Owner',
      phone: user.phoneNumber ?? '',
      address: user.address ?? '',
      profileImage: user.photoUrl ?? '',
      businessName: user.businessName ??
          (user.role == UserRole.commercialShop
              ? '${user.displayName ?? "Gear"} Commercial Shop'
              : '${user.displayName ?? "Gear"} Rentals'),
      bio: user.bio ?? '',
      isVerified: user.isVerified,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    if (existing == null) {
      await OwnerProfileService().createProfile(profile);
    } else {
      await OwnerProfileService().updateProfile(profile);
    }
  }
}
