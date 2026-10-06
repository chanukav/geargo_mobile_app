import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/equipment.dart';

enum DeleteActionChoice {
  delete,
  unpublish,
  cancel,
}

/// Dialog asking confirmation to delete or unpublish equipment.
class DeleteConfirmationDialog extends StatelessWidget {
  final Equipment equipment;

  const DeleteConfirmationDialog({
    super.key,
    required this.equipment,
  });

  static Future<DeleteActionChoice?> show(
    BuildContext context,
    Equipment equipment,
  ) {
    return showDialog<DeleteActionChoice>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(equipment: equipment),
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
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Remove Listing?',
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
            'Are you sure you want to remove "${equipment.name}"?',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.deepNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can choose to temporarily unpublish (hide from renters while saving details) or permanently delete it from your equipment inventory.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pop(DeleteActionChoice.cancel),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 8),
            if (equipment.availability) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(DeleteActionChoice.unpublish),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: AppColors.orange,
                    side: const BorderSide(color: AppColors.orange),
                  ),
                  child: const Text('Unpublish'),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(DeleteActionChoice.delete),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Delete'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
