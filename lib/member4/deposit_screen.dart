import 'package:flutter/material.dart';

import 'repository.dart';
import 'widgets.dart';

class DepositScreen extends StatefulWidget {
  final Member4Repository repo;
  final String rentalId;
  const DepositScreen({super.key, required this.repo, required this.rentalId});
  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  bool busy = false;
  String? error;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Deposit & Payment')),
    body: RentalView(
      repo: widget.repo,
      id: widget.rentalId,
      retry: () => setState(() {}),
      builder: (r) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EquipmentCard(r),
          DepositCard(r),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cost Breakdown',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  'Rental charge: ${r.money(r.data['rentalCharge'] as num)}',
                ),
                Text('Service fee: ${r.money(r.data['serviceFee'] as num)}'),
                const Divider(),
                Text(
                  'Amount Paid: ${r.money(r.data['amountPaid'] as num)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Payment record: ${r.data['paymentStatus']}'),
                const Text(
                  'The refundable security deposit is excluded from this rental payment.',
                ),
              ],
            ),
          ),
          const Panel(
            child: Text(
              'Payment is managed by the booking/transaction module. No card details are stored on this screen.',
            ),
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          if (busy) const LinearProgressIndicator(),
          FilledButton(
            onPressed:
                busy ||
                    r.data['depositAcknowledgedBy'] is Map &&
                        (r.data['depositAcknowledgedBy'] as Map).containsKey(
                          widget.repo.uid,
                        )
                ? null
                : () async {
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      await widget.repo.action(r.id, 'acknowledgeDeposit', {});
                    } catch (e) {
                      if (mounted) setState(() => error = member4Error(e));
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: Text(
              r.data['depositAcknowledgedBy'] is Map &&
                      (r.data['depositAcknowledgedBy'] as Map).containsKey(
                        widget.repo.uid,
                      )
                  ? 'Deposit information acknowledged'
                  : 'Acknowledge deposit information',
            ),
          ),
        ],
      ),
    ),
  );
}
