import 'package:flutter/material.dart';

import '../../core/utils/format.dart';
import '../../models/rental_transaction.dart';

/// Itemised price card used in checkout and in the transaction details sheet.
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
            _row(context, 'GearGo service fee', money(price.serviceFee)),
            _row(context, 'Delivery fee', money(price.deliveryFee)),
            _row(context, 'Refundable deposit', money(price.deposit)),
            const Divider(height: 24),
            _row(context, 'Total amount', money(price.total), bold: true),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'The deposit is refunded within 2 business days after the '
                'equipment is returned in good condition.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false}) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
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
