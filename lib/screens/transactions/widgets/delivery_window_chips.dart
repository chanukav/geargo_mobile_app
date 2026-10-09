import 'package:flutter/material.dart';

import '../../../core/theme/shop_theme.dart';

/// Reusable segmented delivery time window selection chips.
class DeliveryWindowChips extends StatelessWidget {
  const DeliveryWindowChips({
    super.key,
    required this.windows,
    required this.selectedWindow,
    required this.onSelected,
  });

  final List<String> windows;
  final String selectedWindow;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: windows.map((w) {
        final isSelected = selectedWindow == w;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => onSelected(w),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? ShopPalette.blueTint : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? ShopPalette.blue : ShopPalette.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  w,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? ShopPalette.blue : ShopPalette.text,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
