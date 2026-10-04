import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';

/// Production-ready Firebase Authentication Service.
/// Handles Email/Password, Anonymous ("Guest"), Google Sign-In, and Auth state streams.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of Firebase User authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Stream mapped to domain [AppUser] model.
  Stream<AppUser?> get userStream =>
      _auth.authStateChanges().map((user) => user != null ? AppUser.fromFirebase(user) : null);

  /// Current raw Firebase [User].
  User? get currentUser => _auth.currentUser;

  /// Current domain [AppUser].
  AppUser? get currentAppUser =>
      _auth.currentUser != null ? AppUser.fromFirebase(_auth.currentUser!) : null;

  /// Sign in using Email and Password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('AuthService.signInWithEmailAndPassword error: $e');
      rethrow;
    }
  }

  /// Register using Email and Password, optionally setting Display Name.
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
        await credential.user?.reload();
      }

      return credential;
    } catch (e) {
      debugPrint('AuthService.registerWithEmailAndPassword error: $e');
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
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
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
