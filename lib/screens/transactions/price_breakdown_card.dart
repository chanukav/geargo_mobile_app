import 'package:flutter/material.dart';

import '../../core/utils/format.dart';
import '../../models/rental_transaction.dart';

/// Itemised price card showing "Due now" separately from the refundable deposit.
/// Directly resolves usability issue UI-01 where users believed the deposit was non-refundable.
class PriceBreakdownCard extends StatelessWidget {
  const PriceBreakdownCard({
    super.key,
    required this.price,
    this.rentalLabel = 'Rental fee',
  });

  final PriceBreakdown price;
  final String rentalLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row(context, rentalLabel, money(price.rentalFee)),
            _row(context, 'GearGo service fee (8%)', money(price.serviceFee)),
            _row(context, 'Delivery fee', money(price.deliveryFee)),
            const Divider(height: 20),
            _row(context, 'Due now', money(price.dueNow), bold: true),
            const SizedBox(height: 12),
            _row(context, 'Refundable security hold', money(price.deposit),
                textColor: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Refundable hold: not charged permanently. Released back to your payment '
                'method within 2 business days after equipment is returned in good condition.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    Color? textColor,
  }) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium;
    final style = baseStyle?.copyWith(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: textColor ?? baseStyle.color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
