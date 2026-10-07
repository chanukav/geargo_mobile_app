import 'package:flutter/material.dart';

import 'admin_screen.dart';
import 'chat_screen.dart';
import 'handover_screen.dart';
import 'models.dart';
import 'repository.dart';
import 'widgets.dart';

class Member4Hub extends StatefulWidget {
  final Member4Repository repo;
  const Member4Hub({super.key, required this.repo});
  @override
  State<Member4Hub> createState() => _Member4HubState();
}

class _Member4HubState extends State<Member4Hub> {
  bool messages = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(messages ? 'Messages' : 'My Handovers'),
      actions: [
        IconButton(
          tooltip: 'Platform operations',
          onPressed: () => openMember4(context, AdminScreen(repo: widget.repo)),
          icon: const Icon(Icons.admin_panel_settings_outlined),
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: messages ? 1 : 0,
      onDestinationSelected: (i) => setState(() => messages = i == 1),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Bookings',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Messages',
        ),
      ],
    ),
    body: StreamBuilder<List<RentalRecord>>(
      stream: widget.repo.rentals(),
      builder: (context, s) {
        if (s.hasError) {
          return DataState(
            member4Error(s.error!),
            retry: () => setState(() {}),
          );
        }
        if (!s.hasData) {
          return const DataState('Loading your rentals…', loading: true);
        }
        if (s.data!.isEmpty) {
          return const DataState(
            'No rental handovers yet. Confirm a booking to start coordinating pickup.',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final r in s.data!)
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      r.equipmentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(r.dateLabel),
                    Text('Status: ${r.status}'),
                    Text('With ${r.counterpart(widget.repo.uid)}'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => openMember4(
                        context,
                        messages
                            ? ChatScreen(repo: widget.repo, rentalId: r.id)
                            : HandoverScreen(repo: widget.repo, rentalId: r.id),
                      ),
                      child: Text(
                        messages ? 'Open conversation' : 'Open handover',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}
