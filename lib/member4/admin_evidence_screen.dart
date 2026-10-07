import 'package:flutter/material.dart';

import 'models.dart';
import 'repository.dart';
import 'widgets.dart';

/// Read-only evidence for operational review; never reuses participant mutation controls.
class AdminEvidenceScreen extends StatefulWidget {
  final Member4Repository repo;
  final String rentalId;
  const AdminEvidenceScreen({
    super.key,
    required this.repo,
    required this.rentalId,
  });
  @override
  State<AdminEvidenceScreen> createState() => _AdminEvidenceScreenState();
}

class _AdminEvidenceScreenState extends State<AdminEvidenceScreen> {
  late Future<bool> allowed = widget.repo.isAdmin();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Rental Condition Evidence')),
    body: FutureBuilder<bool>(
      future: allowed,
      builder: (context, access) {
        if (access.hasError) {
          return DataState(
            'Unable to check administrator access.',
            retry: () => setState(() => allowed = widget.repo.isAdmin()),
          );
        }
        if (!access.hasData) {
          return const DataState(
            'Checking administrator access…',
            loading: true,
          );
        }
        if (access.data != true) {
          return const DataState('Administrator access is required.');
        }
        return RentalView(
          repo: widget.repo,
          id: widget.rentalId,
          builder: (r) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              EquipmentCard(r),
              DepositCard(r),
              for (final phase in ['pickup', 'return']) ...[
                Text(
                  '$phase condition · ${r.condition(phase)['status']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text('Notes: ${r.condition(phase)['notes']}'),
                Text(
                  'Damage reported: ${r.condition(phase)['damageReported'] == true ? 'Yes' : 'No'}',
                ),
                if (r.photos(phase).isEmpty)
                  const Panel(
                    child: Text('No condition photos submitted yet.'),
                  ),
                for (final angle in photoAngles.entries)
                  if (r.photos(phase)[angle.key] != null)
                    ExpansionTile(
                      title: Text('${angle.value} view'),
                      children: [
                        SizedBox(
                          height: 240,
                          child: PrivatePhoto(
                            repo: widget.repo,
                            path: r.photos(phase)[angle.key]!,
                          ),
                        ),
                      ],
                    ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    ),
  );
}
