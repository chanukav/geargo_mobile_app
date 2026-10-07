import 'package:flutter/material.dart';

import 'chat_screen.dart';
import 'condition_screen.dart';
import 'meetup_screen.dart';
import 'deposit_screen.dart';
import 'models.dart';
import 'repository.dart';
import 'widgets.dart';

class HandoverScreen extends StatefulWidget {
  final Member4Repository repo;
  final String rentalId;
  const HandoverScreen({super.key, required this.repo, required this.rentalId});
  @override
  State<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends State<HandoverScreen> {
  bool busy = false;
  String? error;
  Future<void> save(String action, Map<String, dynamic> values) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repo.action(widget.rentalId, action, values);
    } catch (e) {
      if (mounted) setState(() => error = member4Error(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Equipment Handover')),
    body: RentalView(
      repo: widget.repo,
      id: widget.rentalId,
      retry: () => setState(() {}),
      builder: (r) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.status == 'completed'
                      ? 'Handover completed'
                      : '${r.phase == 'pickup' ? 'Pickup' : 'Return'} · ${r.status}',
                  style: const TextStyle(
                    color: Member4Theme.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: r.completedSteps / 4),
                const SizedBox(height: 8),
                const Text(
                  'Verify Identity → Check Equipment → Confirm Handover',
                ),
                Text('${r.completedSteps} of 4 steps completed'),
              ],
            ),
          ),
          EquipmentCard(r),
          const Text(
            'Handover Checklist',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text('Walk through this checklist together at the meetup.'),
          const SizedBox(height: 12),
          for (final entry in checklistLabels.entries)
            Card(
              child: CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(entry.value),
                value: r.checklist(r.phase)[entry.key] == true,
                onChanged:
                    busy ||
                        r.status == 'completed' ||
                        r.confirmedBy(widget.repo.uid)
                    ? null
                    : (v) => save('checklist', {
                        'phase': r.phase,
                        'key': entry.key,
                        'value': v,
                      }),
              ),
            ),
          Card(
            child: ListTile(
              leading: Icon(
                r.confirmedCondition
                    ? Icons.check_circle
                    : Icons.photo_camera_outlined,
              ),
              title: const Text('Take condition photos as proof'),
              subtitle: Text(
                r.confirmedCondition
                    ? 'Four photos verified'
                    : '${r.photos(r.phase).length} of 4 saved',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openMember4(
                context,
                ConditionScreen(
                  repo: widget.repo,
                  rentalId: r.id,
                  phase: r.phase,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => openMember4(
              context,
              ChatScreen(repo: widget.repo, rentalId: r.id),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text('Message ${r.counterpart(widget.repo.uid)}'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => openMember4(
              context,
              MeetupScreen(repo: widget.repo, rentalId: r.id),
            ),
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('Navigate to Meetup'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Member4Theme.orange,
              foregroundColor: Colors.black,
            ),
            onPressed: () => openMember4(
              context,
              ConditionScreen(
                repo: widget.repo,
                rentalId: r.id,
                phase: r.phase,
              ),
            ),
            child: const Text('Proceed to Condition Check'),
          ),
          const SizedBox(height: 16),
          DepositCard(r),
          TextButton(
            onPressed: () => openMember4(
              context,
              DepositScreen(repo: widget.repo, rentalId: r.id),
            ),
            child: const Text('View deposit and payment breakdown'),
          ),
          if (r.confirmedBy(widget.repo.uid) && r.status != 'completed')
            const Panel(
              child: Text(
                'Your confirmation is saved. Waiting for the other participant.',
              ),
            ),
          if (error != null)
            Text(
              error!,
              style: const TextStyle(color: Colors.red),
              semanticsLabel: 'Save failed: $error',
            ),
          if (busy) const LinearProgressIndicator(),
          if (r.status != 'completed')
            FilledButton(
              onPressed: busy || !r.canConfirm || r.confirmedBy(widget.repo.uid)
                  ? null
                  : () async {
                      if (await confirmAction(
                        context,
                        'Confirm ${r.phase} handover?',
                        'The condition evidence will remain on record. Both participants must confirm.',
                      )) {
                        await save('confirmHandover', {'phase': r.phase});
                      }
                    },
              child: Text(
                'Confirm ${r.phase == 'pickup' ? 'Pickup' : 'Return'}',
              ),
            ),
          if (!r.canConfirm && r.status != 'completed')
            const Text(
              'Complete all checklist steps and confirm the photos to continue.',
            ),
        ],
      ),
    ),
  );
}
