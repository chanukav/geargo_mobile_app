import 'package:flutter/material.dart';

import '../../../core/theme/shop_theme.dart';

/// Reusable saved address radio selection card.
class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.label,
    required this.address,
    required this.isSelected,
    required this.onTap,
    this.isHome = true,
  });

  final String label;
  final String address;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? ShopPalette.blueTint : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? ShopPalette.blue : ShopPalette.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? ShopPalette.blue.withValues(alpha: 0.14)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isHome ? Icons.home_rounded : Icons.work_outline_rounded,
                size: 19,
                color: isSelected ? ShopPalette.blue : ShopPalette.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ShopPalette.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ShopPalette.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: isSelected ? ShopPalette.blue : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}
