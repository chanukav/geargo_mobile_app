import 'package:flutter/material.dart';

import 'admin_evidence_screen.dart';

import 'models.dart';
import 'repository.dart';
import 'widgets.dart';

class AdminScreen extends StatefulWidget {
  final Member4Repository repo;
  const AdminScreen({super.key, required this.repo});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<bool> allowed = widget.repo.isAdmin();
  bool busy = false;
  String? error;
  Future<void> review(String kind, Map<String, dynamic> record) async {
    final note = TextEditingController();
    String status = kind == 'verification' ? 'approved' : 'investigating';
    final options = kind == 'verification'
        ? ['approved', 'rejected']
        : ['investigating', 'resolved', 'dismissed'];
    final key = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialog) => AlertDialog(
          title: Text('Review $kind'),
          content: SingleChildScrollView(
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(record['summary'] as String),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Review status',
                    ),
                    items: options
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (s) => setDialog(() => status = s!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: note,
                    maxLines: 3,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Decision / investigation note',
                    ),
                    validator: (v) =>
                        v!.trim().isEmpty ? 'A review note is required' : null,
                  ),
                  const Text(
                    'Confirming saves the decision and an audit record.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (key.currentState!.validate()) Navigator.pop(c, true);
              },
              child: const Text('Confirm decision'),
            ),
          ],
        ),
      ),
    );
    final text = note.text;
    note.dispose();
    if (confirmed != true) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repo.review(kind, record['id'] as String, status, text);
    } catch (e) {
      if (mounted) setState(() => error = member4Error(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget reviews(String kind) => StreamBuilder<List<Map<String, dynamic>>>(
    stream: widget.repo.reviews(kind),
    builder: (context, s) {
      if (s.hasError) {
        return DataState(member4Error(s.error!), retry: () => setState(() {}));
      }
      if (!s.hasData) {
        return const DataState('Loading operational reviews…', loading: true);
      }
      if (s.data!.isEmpty) {
        return DataState(
          'No ${kind == 'dispute' ? 'disputes' : 'verification requests'}.',
        );
      }
      return Column(
        children: [
          for (final r in s.data!)
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    r['summary'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Status: ${r['status']}'),
                  if (r['rentalId'] != null) Text('Rental: ${r['rentalId']}'),
                  if (r['rentalId'] != null)
                    TextButton(
                      onPressed: () => openMember4(
                        context,
                        AdminEvidenceScreen(
                          repo: widget.repo,
                          rentalId: r['rentalId'] as String,
                        ),
                      ),
                      child: const Text('Review pickup / return evidence'),
                    ),
                  for (final n in (r['notes'] as List? ?? []))
                    Text('${(n as Map)['text']} · ${n['createdAt']}'),
                  OutlinedButton(
                    onPressed:
                        busy ||
                            [
                              'approved',
                              'rejected',
                              'resolved',
                              'dismissed',
                            ].contains(r['status'])
                        ? null
                        : () => review(kind, r),
                    child: const Text('Review and update'),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Platform Operations')),
    body: FutureBuilder<bool>(
      future: allowed,
      builder: (context, s) {
        if (s.hasError) {
          return DataState(
            'Unable to check administrator access.',
            retry: () => setState(() => allowed = widget.repo.isAdmin()),
          );
        }
        if (!s.hasData) {
          return const DataState(
            'Checking administrator access…',
            loading: true,
          );
        }
        if (s.data != true) {
          return const DataState('Administrator access is required.');
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Rental monitoring',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            StreamBuilder<List<RentalRecord>>(
              stream: widget.repo.rentals(all: true),
              builder: (context, r) {
                if (r.hasError) {
                  return DataState(
                    member4Error(r.error!),
                    retry: () => setState(() {}),
                  );
                }
                if (!r.hasData) {
                  return const DataState(
                    'Loading rental activity…',
                    loading: true,
                  );
                }
                if (r.data!.isEmpty) {
                  return const DataState('No rental activity yet.');
                }
                return Column(
                  children: [
                    Panel(
                      child: Text(
                        '${r.data!.length} rentals · ${r.data!.where((x) => x.status == 'active').length} active',
                      ),
                    ),
                    for (final rental in r.data!)
                      Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rental.equipmentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${rental.data['ownerName']} → ${rental.data['renterName']}',
                            ),
                            Text('Rental ${rental.id} · ${rental.status}'),
                            TextButton(
                              onPressed: () => openMember4(
                                context,
                                AdminEvidenceScreen(
                                  repo: widget.repo,
                                  rentalId: rental.id,
                                ),
                              ),
                              child: const Text('View condition evidence'),
                            ),
                            Text(
                              'Deposit: ${depositLabel(rental.deposit['status'] as String)}',
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const Text(
              'Verification reviews',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            reviews('verification'),
            const Text(
              'Dispute resolution',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            reviews('dispute'),
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
          ],
        );
      },
    ),
  );
}
