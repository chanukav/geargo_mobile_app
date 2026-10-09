import 'package:flutter/material.dart';

import '../../../core/theme/shop_theme.dart';

/// Visible security assurance badge (NFR-02).
/// Displays encryption and security lock indicators to establish user trust.
class SecurityBadge extends StatelessWidget {
  const SecurityBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ShopPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.lock_outline_rounded,
            size: 15,
            color: Color(0xFF16A34A),
          ),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              '256-bit encrypted simulated checkout • Card numbers are never stored in plain text',
              style: TextStyle(
                fontSize: 11,
                color: ShopPalette.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
