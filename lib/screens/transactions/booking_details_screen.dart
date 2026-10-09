import 'package:flutter/material.dart';

import '../../core/theme/shop_theme.dart';
import '../../core/utils/format.dart';
import '../../models/shop_product.dart';
import 'address_selection_screen.dart';
import 'checkout_screen.dart';

/// Booking Details: product info, rental period and fulfillment choice.
class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key, required this.product});

  final ShopProduct product;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  late DateTimeRange _range;
  bool _delivery = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .add(const Duration(days: 1));
    _range = DateTimeRange(start: start, end: start.add(const Duration(days: 4)));
  }

  int get _days {
    final d = _range.end.difference(_range.start).inDays;
    return d < 1 ? 1 : d;
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _proceed() async {
    DeliveryDetails? details;
    if (_delivery) {
      details = await Navigator.push<DeliveryDetails>(
        context,
        MaterialPageRoute(builder: (_) => const AddressSelectionScreen()),
      );
      if (details == null) return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          product: widget.product,
          range: _range,
          delivery: _delivery,
          details: details,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.product;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking details')),
      body: ListView(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: p.imageUrl.isEmpty
                ? _placeholder(theme)
                : Image.network(
                    p.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder(theme),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(label: Text(p.category.toUpperCase())),
                    Text('${money(p.pricePerDay)} /day',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(p.name,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                Text('Rental Period', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    onTap: _pickRange,
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(
                        '${fmtDate(_range.start)}  →  ${fmtDate(_range.end)}'),
                    subtitle: Text('$_days day${_days == 1 ? '' : 's'}'),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Fulfillment Option', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: const <ButtonSegment<bool>>[
                      ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.storefront_outlined),
                        label: Text('Self Pickup'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: Icon(Icons.local_shipping_outlined),
                        label: Text('Door Delivery'),
                      ),
                    ],
                    selected: {_delivery},
                    onSelectionChanged: (s) =>
                        setState(() => _delivery = s.first),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Equipment Condition',
                        style: theme.textTheme.titleMedium),
                    Chip(label: Text(p.condition.toUpperCase())),
                  ],
                ),
                const SizedBox(height: 4),
                Text(p.description.isEmpty
                    ? 'No condition notes provided by the shop.'
                    : p.description),
                const SizedBox(height: 4),
                Text('Refundable deposit: ${money(p.deposit)}',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _proceed,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Proceed to Checkout'),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) => Container(
        color: theme.colorScheme.primaryContainer,
        child: Icon(Icons.sports_basketball_outlined,
            size: 72, color: theme.colorScheme.onPrimaryContainer),
      );
}
