import 'package:firebase_auth/firebase_auth.dart';

enum UserRole {
  renter,
  owner,
  commercialShop,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Gear Owner & Lender';
      case UserRole.commercialShop:
        return 'Commercial Rental Shop';
      case UserRole.admin:
        return 'Platform Administrator';
      case UserRole.renter:
        return 'Renter';
    }
  }

  static UserRole fromString(String? val) {
    if (val == null) return UserRole.renter;
    final clean = val.toLowerCase().trim();
    switch (clean) {
      case 'owner':
        return UserRole.owner;
      case 'commercial_shop':
      case 'commercialshop':
        return UserRole.commercialShop;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.renter;
    }
  }

  String get storageValue => switch (this) {
        UserRole.commercialShop => 'commercial_shop',
        _ => name,
      };
}

/// Clean domain model representing an authenticated user in GearGo.
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final bool isEmailVerified;
  final UserRole role;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
    this.isEmailVerified = false,
    this.role = UserRole.renter,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isCommercialShop => role == UserRole.commercialShop;
  bool get isPlatformAdmin => role == UserRole.admin;
  bool get isRenter => role == UserRole.renter;
  bool get canManageListings => isOwner || isCommercialShop;

  /// Factory constructor to map from a Firebase [User].
  factory AppUser.fromFirebase(User user, {UserRole role = UserRole.renter}) {
    final emailLower = user.email?.toLowerCase().trim() ?? '';
    var resolvedRole = role;
    if (role == UserRole.renter && emailLower.contains('owner')) {
      resolvedRole = UserRole.owner;
    }

    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
      isEmailVerified: user.emailVerified,
      role: resolvedRole,
    );
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    bool? isEmailVerified,
    UserRole? role,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email ?? '',
      'display_name': displayName ?? '',
      'photo_url': photoUrl ?? '',
      'role': role.storageValue,
      'is_anonymous': isAnonymous,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] as String?,
      displayName: map['display_name'] as String?,
      photoUrl: map['photo_url'] as String?,
      isAnonymous: (map['is_anonymous'] as bool?) ?? false,
      role: UserRole.fromString(map['role'] as String?),
    );
  }

  /// User-friendly label for UI headers.
  String get displayTitle {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (email != null && email!.trim().isNotEmpty) {
      return email!.split('@').first;
    }
    if (isAnonymous) {
      return 'Guest Driver';
    }
    return 'GearGo Member';
  }

  /// Initials for fallback avatar circles (e.g. "JD", "G").
  String get initials {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    if (email != null && email!.trim().isNotEmpty) {
      return email![0].toUpperCase();
    }
    return isAnonymous ? 'GD' : 'U';
  }
}
