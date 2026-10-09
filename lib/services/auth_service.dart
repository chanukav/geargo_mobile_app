import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';
import '../models/owner_profile.dart';
import 'owner_profile_service.dart';

/// Production-ready Firebase Authentication Service with Persona/Role management.
/// Handles Email/Password, Anonymous ("Guest"), Google Sign-In, and Role persistence.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // In-memory cache for user roles to avoid redundant Firestore reads
  final Map<String, UserRole> _roleCache = {};

  FirebaseFirestore? get _safeFirestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Stream of Firebase User authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Stream mapped to domain [AppUser] model with resolved role.
  Stream<AppUser?> get userStream =>
      _auth.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        final role = await getUserRole(user.uid, email: user.email);
        return AppUser.fromFirebase(user, role: role);
      });

  /// Current raw Firebase [User].
  User? get currentUser => _auth.currentUser;

  /// Current domain [AppUser] with cached role.
  AppUser? get currentAppUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    final cachedRole = _roleCache[user.uid] ??
        (user.email?.toLowerCase().contains('owner') == true
            ? UserRole.owner
            : UserRole.renter);
    return AppUser.fromFirebase(user, role: cachedRole);
  }

  /// Gets the role of a user from Firestore with cache and smart fallbacks.
  Future<UserRole> getUserRole(String uid, {String? email}) async {
    if (_roleCache.containsKey(uid)) {
      return _roleCache[uid]!;
    }

    final emailLower = (email ?? _auth.currentUser?.email ?? '').toLowerCase();

    // 1. Check if email matches designated owner accounts
    if (emailLower.contains('owner')) {
      _roleCache[uid] = UserRole.owner;
      return UserRole.owner;
    }

    final fs = _safeFirestore;
    if (fs != null) {
      try {
        final doc = await fs.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final roleStr = doc.data()!['role'] as String?;
          final role = UserRole.fromString(roleStr);
          _roleCache[uid] = role;
          return role;
        }

        // 2. Check if user already has an owner_profile document
        final ownerDoc = await fs.collection('owner_profile').doc(uid).get();
        if (ownerDoc.exists) {
          _roleCache[uid] = UserRole.owner;
          return UserRole.owner;
        }
      } catch (e) {
        debugPrint('[AuthService] Firestore read role warning: $e');
      }
    }

    _roleCache[uid] = UserRole.renter;
    return UserRole.renter;
  }

  /// Saves or updates the user profile and role in the Firestore 'users' collection.
  Future<void> saveUserProfile(AppUser user) async {
    _roleCache[user.uid] = user.role;
    final fs = _safeFirestore;
    if (fs != null) {
      try {
        await fs.collection('users').doc(user.uid).set(
          user.toMap(),
          SetOptions(merge: true),
        );
        debugPrint('[AuthService] Saved user profile: ${user.uid} with role: ${user.role.name}');
      } catch (e) {
        debugPrint('[AuthService] Warning saving user profile to Firestore: $e');
      }
    }
  }

  /// Sign in using Email and Password. Ensures user document is in database.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final role = await getUserRole(user.uid, email: user.email);
        final appUser = AppUser.fromFirebase(user, role: role);
        await saveUserProfile(appUser);
      }

      return credential;
    } catch (e) {
      debugPrint('AuthService.signInWithEmailAndPassword error: $e');
      rethrow;
    }
  }

  /// Register using Email and Password with designated [role].
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    UserRole role = UserRole.renter,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        if (displayName != null && displayName.trim().isNotEmpty) {
          await user.updateDisplayName(displayName.trim());
          await user.reload();
        }

        final appUser = AppUser(
          uid: user.uid,
          email: user.email,
          displayName: displayName ?? user.displayName,
          role: role,
        );

        await saveUserProfile(appUser);

        // If registered as Owner, create initial owner profile
        if (role == UserRole.owner || role == UserRole.commercialShop) {
          try {
            await OwnerProfileService().createProfile(
              OwnerProfile(
                id: user.uid,
                userId: user.uid,
                name: displayName ?? user.displayName ?? 'Gear Owner',
                phone: '',
                address: '',
                profileImage: '',
                businessName: role == UserRole.commercialShop
                    ? '${displayName ?? "Gear"} Commercial Shop'
                    : '${displayName ?? "Gear"} Rentals',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                isVerified: true,
              ),
            );
          } catch (profileErr) {
            debugPrint('[AuthService] Owner profile initial setup warning: $profileErr');
          }
        }
      }

      return credential;
    } catch (e) {
      debugPrint('AuthService.registerWithEmailAndPassword error: $e');
      rethrow;
    }
  }

  /// Seamlessly signs in or provisions the official GearGo Owner demo account.
  Future<UserCredential> signInOrRegisterOfficialOwner() async {
    const ownerEmail = 'owner@geargo.com';
    const ownerPassword = 'GearGoOwner2026!';
    const ownerName = 'Marcus Vance (Owner)';

    try {
      return await signInWithEmailAndPassword(
        email: ownerEmail,
        password: ownerPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        // Create new owner account in Firebase Auth and Firestore
        return await registerWithEmailAndPassword(
          email: ownerEmail,
          password: ownerPassword,
          displayName: ownerName,
          role: UserRole.owner,
        );
      }
      rethrow;
    }
  }

  /// Seamlessly signs in or provisions the official GearGo Renter demo account.
  Future<UserCredential> signInOrRegisterOfficialRenter() async {
    const renterEmail = 'user@geargo.com';
    const renterPassword = 'GearGoRenter2026!';
    const renterName = 'Sam Wilson (Renter)';

    try {
      return await signInWithEmailAndPassword(
        email: renterEmail,
        password: renterPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        return await registerWithEmailAndPassword(
          email: renterEmail,
          password: renterPassword,
          displayName: renterName,
          role: UserRole.renter,
        );
      }
      rethrow;
    }
  }

  /// Sign in anonymously (Guest Mode).
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      debugPrint('AuthService.signInAnonymously error: $e');
      rethrow;
    }
  }

  /// Sign in using Google OAuth.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the Google sign-in prompt
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('AuthService.signInWithGoogle error: $e');
      rethrow;
    }
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      debugPrint('AuthService.sendPasswordResetEmail error: $e');
      rethrow;
    }
  }

  /// Sign out current user from all providers.
  Future<void> signOut() async {
    try {
      if (kIsWeb) {
        await _auth.signOut();
      } else {
        await Future.wait([
          _auth.signOut(),
          _googleSignIn.signOut(),
        ]);
      }
    } catch (e) {
      debugPrint('AuthService.signOut error: $e');
      rethrow;
    }
  }

  /// Convert Firebase Auth errors into clear, user-friendly messages.
  static String getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'The email or password entered is invalid.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'weak-password':
          return 'The password is too weak. Please use a stronger password.';
        case 'operation-not-allowed':
          return 'This sign-in provider is disabled in Firebase console.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again in a few minutes.';
        default:
          return error.message ?? 'An unexpected authentication error occurred.';
      }
    }
    return error?.toString() ?? 'An unknown error occurred. Please try again.';
  }
}
