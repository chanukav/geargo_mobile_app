/// Utility class for reusable form validation logic.
class AppValidators {
  AppValidators._();

  /// Validates email address format and presence.
  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Please enter your email address.';
    }
    // Standard RFC-compliant relaxed email regex
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  /// Validates password presence and minimum length (min 6 characters).
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  /// Validates full name presence and minimum length.
  static String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Please enter your full name.';
    }
    if (name.length < 2) {
      return 'Name must be at least 2 characters long.';
    }
    return null;
  }

  /// Validates that confirm password matches the initial password.
  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != originalPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }
}

// Top-level alias functions for direct consumption and backward compatibility
String? validateEmail(String? value) => AppValidators.validateEmail(value);
String? validatePassword(String? value) => AppValidators.validatePassword(value);
String? validateName(String? value) => AppValidators.validateName(value);
String? validateConfirmPassword(String? value, String originalPassword) =>
    AppValidators.validateConfirmPassword(value, originalPassword);
