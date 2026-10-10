import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/owner_profile.dart';

enum DeactivateProfileChoice { deactivate, delete, cancel }

/// Confirmation dialog for soft-deactivation or hard-deletion of an owner profile.
class DeactivateProfileDialog extends StatelessWidget {
  final OwnerProfile profile;

  const DeactivateProfileDialog({super.key, required this.profile});

  static Future<DeactivateProfileChoice?> show(
    BuildContext context,
    OwnerProfile profile,
  ) {
    return showDialog<DeactivateProfileChoice>(
      context: context,
      builder: (_) => DeactivateProfileDialog(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_off_outlined,
              color: AppColors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Profile Action',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What would you like to do with your profile?',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.pause_circle_outline_rounded,
            iconColor: AppColors.warning,
            title: 'Deactivate Profile',
            subtitle:
                'Temporarily hide your profile. Your listings will be paused. You can reactivate at any time.',
          ),
          const SizedBox(height: 8),
          _OptionTile(
            icon: Icons.delete_forever_outlined,
            iconColor: AppColors.error,
            title: 'Permanently Delete',
            subtitle:
                'Remove all your profile data. This action cannot be undone.',
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () =>
              Navigator.of(context).pop(DeactivateProfileChoice.cancel),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 4),
        OutlinedButton(
          onPressed: () =>
              Navigator.of(context).pop(DeactivateProfileChoice.deactivate),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            foregroundColor: AppColors.warning,
            side: const BorderSide(color: AppColors.warning),
          ),
          child: const Text('Deactivate'),
        ),
        const SizedBox(width: 4),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(DeactivateProfileChoice.delete),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            backgroundColor: AppColors.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
