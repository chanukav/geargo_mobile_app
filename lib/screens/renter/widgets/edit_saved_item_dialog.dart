import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/saved_equipment.dart';
import '../../../services/saved_equipment_service.dart';

/// Dialog allowing a renter to edit their personal memo note and collection for a saved item (CRUD 02 - Update).
class EditSavedItemDialog extends StatefulWidget {
  final SavedEquipment item;

  const EditSavedItemDialog({super.key, required this.item});

  static Future<void> show(BuildContext context, SavedEquipment item) {
    return showDialog<void>(
      context: context,
      builder: (_) => EditSavedItemDialog(item: item),
    );
  }

  @override
  State<EditSavedItemDialog> createState() => _EditSavedItemDialogState();
}

class _EditSavedItemDialogState extends State<EditSavedItemDialog> {
  final _service = SavedEquipmentService();
  late TextEditingController _noteController;
  late TextEditingController _customCollectionController;
  late String _selectedCollection;

  static const List<String> _presetCollections = [
    'Favorites',
    'Wishlist',
    'Weekend Trips',
    'Camping Gear',
    'Water Sports',
    'Photography',
    'Custom...',
  ];

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.item.renterNote);
    _selectedCollection = widget.item.collectionName;

    final isPreset = _presetCollections.contains(_selectedCollection) &&
        _selectedCollection != 'Custom...';
    _customCollectionController = TextEditingController(
      text: isPreset ? '' : _selectedCollection,
    );
    if (!isPreset && _selectedCollection.isNotEmpty) {
      _selectedCollection = 'Custom...';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _customCollectionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final finalCollection = _selectedCollection == 'Custom...'
        ? (_customCollectionController.text.trim().isEmpty
            ? 'Favorites'
            : _customCollectionController.text.trim())
        : _selectedCollection;

    await _service.updateSavedDetails(
      widget.item.id,
      collectionName: finalCollection,
      renterNote: _noteController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved item memo updated!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.deepNavy;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: bg,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Saved Gear Memo',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            widget.item.equipmentName,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign to Collection',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetCollections.map((col) {
                final selected = _selectedCollection == col;
                return ChoiceChip(
                  label: Text(col),
                  selected: selected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedCollection = col);
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : textColor,
                  ),
                );
              }).toList(),
            ),
            if (_selectedCollection == 'Custom...') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customCollectionController,
                style: TextStyle(fontSize: 13.5, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Enter new collection name...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'Personal Renter Note / Memo',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: TextStyle(fontSize: 13.5, color: textColor),
              decoration: InputDecoration(
                hintText: 'e.g. Compare with Trek fuel bike before booking...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _handleSave,
          child: const Text('Save Memo'),
        ),
      ],
    );
  }
}
