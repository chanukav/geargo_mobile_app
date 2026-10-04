import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Card showing authentication and user metadata on the Home screen.
class AccountDetailsCard extends StatelessWidget {
  final User user;

  const AccountDetailsCard({
    super.key,
    required this.user,
  });

  String _getProviderName() {
    if (user.isAnonymous) return 'Anonymous Guest';
    if (user.providerData.isEmpty) return 'Firebase';
    final providerId = user.providerData.first.providerId;
    switch (providerId) {
      case 'google.com':
        return 'Google OAuth';
      case 'password':
        return 'Email & Password';
      case 'phone':
        return 'Phone SMS';
      default:
        return providerId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Authentication Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Provider
            _buildDetailRow(
              context,
              label: 'Sign-in Provider',
              value: _getProviderName(),
              icon: Icons.login_rounded,
            ),
            const SizedBox(height: 12),

            // Email / Anonymous
            _buildDetailRow(
              context,
              label: 'Email',
              value: user.email ?? 'Not linked (Guest session)',
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 12),

            // Email verification
            if (!user.isAnonymous) ...[
              _buildDetailRow(
                context,
                label: 'Email Status',
                value: user.emailVerified ? 'Verified' : 'Unverified',
                icon: user.emailVerified
                    ? Icons.verified_user_rounded
                    : Icons.mark_email_unread_outlined,
                valueColor:
                    user.emailVerified ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(height: 12),
            ],

            // User ID with copy button
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.fingerprint_rounded,
                  size: 18,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User ID (UID)',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      Text(
                        user.uid,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copy UID',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: user.uid));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('UID copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondaryLight),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
