import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

export 'auth_service.dart';

/// Legacy compatibility wrapper for [AuthService].
/// Keeps backward compatibility while adhering to production quality guidelines.
class AuthServices {
  final AuthService _authService = AuthService();

  // Stream of auth state changes
  Stream<User?> get user => _authService.authStateChanges;

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      debugPrint('AuthServices legacy signIn error: $e');
      return null;
    }
  }

  // Register with email and password
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      debugPrint('AuthServices legacy register error: $e');
      return null;
    }
  }

  // Sign in anonymously
  Future<User?> signInAnonymously() async {
    try {
      final credential = await _authService.signInAnonymously();
      return credential.user;
    } catch (e) {
      debugPrint('AuthServices legacy anonymous signIn error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('AuthServices legacy signOut error: $e');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _authService.currentUser;
  }
}
