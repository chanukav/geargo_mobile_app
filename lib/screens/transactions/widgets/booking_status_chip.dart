import 'package:flutter/material.dart';

import '../../../core/theme/shop_theme.dart';

/// Reusable status badge chip supporting:
/// Pending, Confirmed, Active, Returned, Cancelled.
class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'confirmed':
        bg = ShopPalette.blueTint;
        fg = ShopPalette.blue;
        label = 'CONFIRMED';
        break;
      case 'active':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'ACTIVE';
        break;
      case 'returned':
      case 'completed':
        bg = ShopPalette.greenTint;
        fg = ShopPalette.green;
        label = 'RETURNED';
        break;
      case 'cancelled':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = 'CANCELLED';
        break;
      case 'pending':
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
