import 'package:firebase_auth/firebase_auth.dart';

/// Clean domain model representing an authenticated user in GearGo.
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final bool isEmailVerified;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
    this.isEmailVerified = false,
  });

  /// Factory constructor to map from a Firebase [User].
  factory AppUser.fromFirebase(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
      isEmailVerified: user.emailVerified,
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
