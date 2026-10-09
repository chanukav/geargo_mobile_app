import 'package:flutter/material.dart';

import '../../core/theme/shop_theme.dart';
import '../../core/utils/format.dart';
import '../../models/rental_transaction.dart';
import 'transactions_screen.dart';

/// Payment Confirmation: shown after the transaction was created.
class PaymentConfirmationScreen extends StatelessWidget {
  const PaymentConfirmationScreen({super.key, required this.transaction});

  final RentalTransaction transaction;

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final t = transaction;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Icon(Icons.check_circle_rounded,
                  size: 88, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text('Booking Confirmed!',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('BOOKING REF: #${t.bookingRef}',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _line(context, 'Equipment', t.productName),
                      _line(context, 'Rental dates',
                          '${fmtDate(t.startDate)} - ${fmtDate(t.endDate)} (${t.days} days)'),
                      _line(context, 'Fulfillment',
                          t.isDelivery ? 'Door Delivery' : 'Self Pickup'),
                      if (t.isDelivery && t.deliveryWindow.isNotEmpty)
                        _line(context, 'Delivery window', t.deliveryWindow),
                      _line(context, 'Payment', t.paymentMethod),
                      const Divider(height: 24),
                      _line(context, 'Due now (Paid)', money(t.dueNow),
                          bold: true),
                      _line(context, 'Refundable deposit hold', money(t.deposit)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your ${money(t.deposit)} deposit will be refunded within '
                '2 business days after the equipment is returned in good condition.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                    (route) => route.isFirst,
                  ),
                  child: const Text('View My Bookings'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value,
      {bool bold = false}) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          const SizedBox(width: 16),
          Flexible(
            child: Text(value, textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}
