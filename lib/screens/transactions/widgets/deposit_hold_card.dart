import 'package:flutter/material.dart';

import '../../../core/theme/shop_theme.dart';
import '../../../core/utils/format.dart';

/// Explicit card explaining the refundable security deposit hold.
/// Directly resolves Usability Issue UI-01: prevents user confusion
/// by clarifying that the deposit is an authorization hold, NOT an upfront charge.
class DepositHoldCard extends StatelessWidget {
  const DepositHoldCard({
    super.key,
    required this.depositAmount,
  });

  final double depositAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ShopPalette.blueTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ShopPalette.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: ShopPalette.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Refundable Security Hold',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ShopPalette.text,
                  ),
                ),
              ),
              Text(
                money(depositAmount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ShopPalette.blue,
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message:
                    'This deposit is not charged; it will be released within 48 hours after gear return without damage.',
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: ShopPalette.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'This deposit is not charged; it will be released within 48 hours after gear return without damage.',
            style: TextStyle(
              fontSize: 12,
              color: ShopPalette.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
