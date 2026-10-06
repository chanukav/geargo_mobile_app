import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/equipment.dart';

/// Interactive Category Selector Chip Grid/List for Equipment forms.
class CategorySelector extends StatelessWidget {
  final String selectedCategoryId;
  final ValueChanged<String> onCategoryChanged;

  const CategorySelector({
    super.key,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.deepNavy,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EquipmentCategory.allCategories.map((category) {
            final isSelected =
                category.id.toLowerCase() == selectedCategoryId.toLowerCase();

            return ChoiceChip(
              avatar: Icon(
                category.icon,
                size: 16,
                color: isSelected ? AppColors.white : category.color,
              ),
              label: Text(category.name),
              selected: isSelected,
              onSelected: (_) => onCategoryChanged(category.id),
              selectedColor: AppColors.blue,
              backgroundColor: AppColors.white,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.white : AppColors.deepNavy,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? AppColors.blue : AppColors.borderLight,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }
}
