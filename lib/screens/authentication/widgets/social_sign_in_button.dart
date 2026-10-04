import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Reusable button for alternative/social sign-in providers.
class SocialSignInButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  const SocialSignInButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  /// Factory for Google sign-in button
  factory SocialSignInButton.google({
    Key? key,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SocialSignInButton(
      key: key,
      label: 'Continue with Google',
      icon: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.g_mobiledata_rounded,
          color: AppColors.googleRed,
          size: 24,
        ),
      ),
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }

  /// Factory for Anonymous / Guest sign-in button
  factory SocialSignInButton.guest({
    Key? key,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SocialSignInButton(
      key: key,
      label: 'Continue as Guest',
      icon: const Icon(
        Icons.person_outline_rounded,
        size: 20,
      ),
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor ??
            (isDark ? const Color(0xFF1B2438) : Colors.white),
        foregroundColor: foregroundColor ??
            (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        side: BorderSide(
          color: borderColor ??
              (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}
