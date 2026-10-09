import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/shop_theme.dart';
import '../../core/utils/format.dart';
import '../../models/shop_product.dart';
import '../../models/rental_transaction.dart';
import '../../services/transaction_service.dart';
import 'address_selection_screen.dart';
import 'payment_confirmation_screen.dart';
import 'price_breakdown_card.dart';

/// Confirm Order: fulfillment choice, address, payment method, price breakdown.
/// Pressing "Confirm & Pay" CREATES the transaction in Firestore.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.product,
    required this.range,
    required this.delivery,
    this.details,
  });

  final ShopProduct product;
  final DateTimeRange range;
  final bool delivery;
  final DeliveryDetails? details;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _methods = [
    'Visa ending in 4242',
    'Mastercard ending in 8890',
    'Mobile wallet',
  ];

  final _service = TransactionService();
  late bool _delivery;
  DeliveryDetails? _details;
  String _payment = _methods.first;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _delivery = widget.delivery;
    _details = widget.details;
  }

  int get _days =>
      math.max(1, widget.range.end.difference(widget.range.start).inDays);

  PriceBreakdown get _price => PriceBreakdown.calculate(
        pricePerDay: widget.product.pricePerDay,
        days: _days,
        deposit: widget.product.deposit,
        delivery: _delivery,
      );

  Future<void> _chooseFulfillment(bool delivery) async {
    if (!delivery) {
      setState(() => _delivery = false);
      return;
    }
    if (_details == null) {
      final d = await Navigator.push<DeliveryDetails>(
        context,
        MaterialPageRoute(builder: (_) => const AddressSelectionScreen()),
      );
      if (d == null || !mounted) return;
      setState(() {
        _delivery = true;
        _details = d;
      });
    } else {
      setState(() => _delivery = true);
    }
  }

  Future<void> _changeAddress() async {
    final d = await Navigator.push<DeliveryDetails>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressSelectionScreen(initial: _details),
      ),
    );
    if (d != null && mounted) setState(() => _details = d);
  }

  Future<void> _pay() async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _paying = true);
    try {
      final txn = await _service.createBooking(
        product: widget.product,
        start: widget.range.start,
        end: widget.range.end,
        delivery: _delivery,
        address: _details?.address ?? '',
        instructions: _details?.instructions ?? '',
        window: _details?.window ?? '',
        paymentMethod: _payment,
      );
      nav.pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentConfirmationScreen(transaction: txn),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _paying = false);
      messenger.showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.product;
    final price = _price;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Order')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.sports_basketball_outlined),
              title: Text(p.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${fmtDate(widget.range.start)} - ${fmtDate(widget.range.end)}'
                ' • $_days day${_days == 1 ? '' : 's'}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('How would you like to get your gear?',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _OptionCard(
            selected: !_delivery,
            icon: Icons.storefront_outlined,
            title: 'Self Pickup',
            subtitle: 'Meet at a safe public location',
            trailing: 'Free',
            onTap: () => _chooseFulfillment(false),
          ),
          const SizedBox(height: 8),
          _OptionCard(
            selected: _delivery,
            icon: Icons.local_shipping_outlined,
            title: 'GearGo Delivery',
            subtitle: 'Contactless drop-off & safe returns',
            trailing: '+${money(PriceBreakdown.deliveryFlatFee)}',
            onTap: () => _chooseFulfillment(true),
          ),
          if (_delivery && _details != null) ...[
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(_details!.address),
                subtitle: Text(_details!.window +
                    (_details!.instructions.isEmpty
                        ? ''
                        : '\n${_details!.instructions}')),
                isThreeLine: _details!.instructions.isNotEmpty,
                trailing: TextButton(
                  onPressed: _changeAddress,
                  child: const Text('CHANGE'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('Payment Method', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final m in _methods) ...[
            _OptionCard(
              selected: _payment == m,
              icon: Icons.credit_card_outlined,
              title: m,
              onTap: () => setState(() => _payment = m),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          Text('Price Breakdown', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          PriceBreakdownCard(
            price: price,
            rentalLabel: 'Rental fee (${money(p.pricePerDay)} x $_days days)',
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _paying ? null : _pay,
            child: _paying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Confirm & Pay ${money(price.total)}'),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(trailing!,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            Icon(selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked),
          ],
        ),
      ),
    );
  }
}
