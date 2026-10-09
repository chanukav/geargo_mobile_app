import 'package:flutter/material.dart';

import '../../core/theme/shop_theme.dart';
import '../../core/utils/format.dart';
import '../../models/rental_transaction.dart';
import '../../services/transaction_service.dart';
import 'address_selection_screen.dart';
import 'browse_equipment_screen.dart';
import 'price_breakdown_card.dart';

/// Transaction/Payment Management.
/// READ: My Bookings (as renter) and Shop Orders (as shop) tabs + details sheet.
/// UPDATE: edit delivery details, mark completed (releases deposit).
/// DELETE: cancel booking (refund) and delete a cancelled record.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transactions'),
          bottom: const TabBar(
            tabs: [Tab(text: 'My Bookings'), Tab(text: 'Shop Orders')],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BrowseEquipmentScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('New booking'),
        ),
        body: const TabBarView(
          children: [
            _TransactionList(shopView: false),
            _TransactionList(shopView: true),
          ],
        ),
      ),
    );
  }
}

class _TransactionList extends StatefulWidget {
  const _TransactionList({required this.shopView});

  final bool shopView;

  @override
  State<_TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<_TransactionList> {
  final _service = TransactionService();
  late final Stream<List<RentalTransaction>> _stream;
  String _selectedStatus = 'All';

  static const _filters = ['All', 'Confirmed', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _stream = widget.shopView
        ? _service.streamShopOrders()
        : _service.streamMyBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: _filters.map((f) {
              final isSelected = _selectedStatus == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedStatus = f);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<RentalTransaction>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load transactions.\n${snap.error}',
                        textAlign: TextAlign.center),
                  ),
                );
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final allItems = snap.data!;
              final items = _selectedStatus == 'All'
                  ? allItems
                  : allItems
                      .where((t) =>
                          t.status.toLowerCase() ==
                          _selectedStatus.toLowerCase())
                      .toList();

              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _selectedStatus == 'All'
                          ? (widget.shopView
                              ? 'No orders for your shop yet.'
                              : 'No bookings yet. Tap "New booking" to rent equipment.')
                          : 'No ${_selectedStatus.toLowerCase()} orders found.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _TransactionCard(
                  t: items[i],
                  shopView: widget.shopView,
                  service: _service,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.t,
    required this.shopView,
    required this.service,
  });

  final RentalTransaction t;
  final bool shopView;
  final TransactionService service;

  String get _paymentLabel {
    switch (t.paymentStatus) {
      case 'refunded':
        return 'Refunded';
      case 'deposit_refunded':
        return 'Deposit refunded';
      default:
        return 'Paid';
    }
  }

  Future<bool> _confirm(
      BuildContext context, String title, String message, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _run(
    ScaffoldMessengerState messenger,
    Future<void> Function() action,
    String success,
  ) async {
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(success)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Action failed: $e')));
    }
  }

  Future<void> _editDelivery(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final d = await Navigator.push<DeliveryDetails>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressSelectionScreen(
          initial: DeliveryDetails(
            address: t.deliveryAddress,
            instructions: t.deliveryInstructions,
            window: t.deliveryWindow,
          ),
        ),
      ),
    );
    if (d == null) return;
    await _run(
      messenger,
      () => service.updateDelivery(
        id: t.id,
        address: d.address,
        instructions: d.instructions,
        window: d.window,
      ),
      'Delivery details updated',
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _confirm(
      context,
      'Cancel booking?',
      'Booking #${t.bookingRef} will be cancelled and the payment refunded.',
      'Cancel booking',
    );
    if (!ok) return;
    await _run(messenger, () => service.cancelBooking(t.id),
        'Booking cancelled and refunded');
  }

  Future<void> _complete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _confirm(
      context,
      'Mark as returned?',
      'The equipment was returned in good condition and the deposit '
          '(${money(t.deposit)}) will be released to the renter.',
      'Confirm',
    );
    if (!ok) return;
    await _run(messenger, () => service.completeBooking(t.id),
        'Rental completed, deposit released');
  }

  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _confirm(
      context,
      'Delete record?',
      'Booking #${t.bookingRef} will be permanently removed from your history.',
      'Delete',
    );
    if (!ok) return;
    await _run(messenger, () => service.deleteBooking(t.id), 'Record deleted');
  }

  void _showDetails(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.productName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Booking #${t.bookingRef}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Text('${fmtDateFull(t.startDate)} - ${fmtDateFull(t.endDate)} '
                '(${t.days} days)'),
            const SizedBox(height: 4),
            Text(t.isDelivery
                ? 'Door Delivery • ${t.deliveryWindow}\n${t.deliveryAddress}'
                    '${t.deliveryInstructions.isEmpty ? '' : '\nNote: ${t.deliveryInstructions}'}'
                : 'Self Pickup'),
            const SizedBox(height: 4),
            Text('Payment: ${t.paymentMethod} • $_paymentLabel'),
            const SizedBox(height: 4),
            Text('Due now: ${money(t.dueNow)} • Security hold: ${money(t.deposit)}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            PriceBreakdownCard(price: t.breakdown),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Color bg;
    Color fg;
    switch (t.status) {
      case 'cancelled':
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        break;
      case 'completed':
        bg = scheme.tertiaryContainer;
        fg = scheme.onTertiaryContainer;
        break;
      default:
        bg = scheme.primaryContainer;
        fg = scheme.onPrimaryContainer;
    }

    final actions = <Widget>[];
    if (t.status == 'confirmed') {
      if (shopView) {
        actions.add(FilledButton.tonal(
          onPressed: () => _complete(context),
          child: const Text('Mark returned'),
        ));
      } else if (t.isDelivery) {
        actions.add(OutlinedButton(
          onPressed: () => _editDelivery(context),
          child: const Text('Edit delivery'),
        ));
      }
      actions.add(OutlinedButton(
        onPressed: () => _cancel(context),
        child: const Text('Cancel'),
      ));
    } else if (t.status == 'cancelled') {
      actions.add(OutlinedButton(
        onPressed: () => _delete(context),
        child: const Text('Delete'),
      ));
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(t.productName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t.status.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(color: fg),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text('#${t.bookingRef}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Text('${fmtDate(t.startDate)} - ${fmtDate(t.endDate)} • '
                  '${t.isDelivery ? 'Door Delivery' : 'Self Pickup'}'),
              const SizedBox(height: 4),
              Text(
                'Due now: ${money(t.dueNow)} (Hold: ${money(t.deposit)}) • $_paymentLabel',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
