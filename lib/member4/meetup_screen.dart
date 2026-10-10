import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chat_screen.dart';
import 'models.dart';
import 'repository.dart';
import 'widgets.dart';

class MeetupScreen extends StatefulWidget {
  final Member4Repository repo;
  final String rentalId;
  final Map<String, dynamic>? sharedLocation;
  const MeetupScreen({
    super.key,
    required this.repo,
    required this.rentalId,
    this.sharedLocation,
  });
  @override
  State<MeetupScreen> createState() => _MeetupScreenState();
}

class _MeetupScreenState extends State<MeetupScreen> {
  bool busy = false;
  String? error, shareId;
  Future<void> run(Future<void> Function() work) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await work();
    } catch (e) {
      if (mounted) setState(() => error = member4Error(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit(RentalRecord r) async {
    final name = TextEditingController(text: r.meetup['name'] as String),
        address = TextEditingController(text: r.meetup['address'] as String),
        lat = TextEditingController(text: '${r.meetup['latitude']}'),
        lng = TextEditingController(text: '${r.meetup['longitude']}');
    final form = GlobalKey<FormState>();
    final location = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Agree meetup details'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Place name'),
                  maxLength: 120,
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Enter a place name' : null,
                ),
                TextFormField(
                  controller: address,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLength: 300,
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Enter an address' : null,
                ),
                TextFormField(
                  controller: lat,
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (v) => _coordinate(v, 90),
                ),
                TextFormField(
                  controller: lng,
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (v) => _coordinate(v, 180),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(c, {
                  'name': name.text.trim(),
                  'address': address.text.trim(),
                  'latitude': double.parse(lat.text),
                  'longitude': double.parse(lng.text),
                });
              }
            },
            child: const Text('Save meetup'),
          ),
        ],
      ),
    );
    name.dispose();
    address.dispose();
    lat.dispose();
    lng.dispose();
    if (location != null) {
      await run(
        () => widget.repo.action(r.id, 'meetup', {'location': location}),
      );
    }
  }

  String? _coordinate(String? value, int limit) {
    final n = double.tryParse(value ?? '');
    return n == null || !n.isFinite || n.abs() > limit
        ? 'Enter a coordinate between -$limit and $limit'
        : null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meetup Location')),
    body: RentalView(
      repo: widget.repo,
      id: widget.rentalId,
      retry: () => setState(() {}),
      builder: (r) {
        final m = widget.sharedLocation ?? r.meetup;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Member4Theme.blue.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 64,
                      color: Member4Theme.blue,
                    ),
                    const Text('Shared Meetup Point'),
                    Text('${m['latitude']}, ${m['longitude']}'),
                    const Text('Open directions to view the live map.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    m['name'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(m['address'] as String),
                  const SizedBox(height: 12),
                  Text('Meet with ${r.counterpart(widget.repo.uid)}'),
                  if (widget.sharedLocation != null)
                    const Text(
                      'This is the location shared in that message. Current rental details may have changed.',
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => run(() async {
                            final uri = Uri.https(
                              'www.google.com',
                              '/maps/dir/',
                              {
                                'api': '1',
                                'destination':
                                    '${m['latitude']},${m['longitude']}',
                              },
                            );
                            if (!await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            )) {
                              throw StateError('Unable to open maps.');
                            }
                          }),
                    icon: const Icon(Icons.directions),
                    label: const Text('Get Directions'),
                  ),
                  if (widget.sharedLocation == null)
                    FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () => run(() async {
                              shareId ??= widget.repo.newMessageId();
                              await widget.repo.send(
                                r.id,
                                shareId!,
                                '',
                                location: true,
                              );
                              shareId = null;
                              if (context.mounted) {
                                openMember4(
                                  context,
                                  ChatScreen(repo: widget.repo, rentalId: r.id),
                                );
                              }
                            }),
                      icon: const Icon(Icons.share_location),
                      label: const Text('Share Location in Chat'),
                    ),
                  if (r.status != 'completed' && widget.sharedLocation == null)
                    TextButton(
                      onPressed: busy ? null : () => edit(r),
                      child: const Text('Update agreed meetup'),
                    ),
                ],
              ),
            ),
            const Panel(
              child: Text(
                'Meetup Safety Tip\nAlways meet in public, well-lit areas. Share your meetup details with a friend.',
              ),
            ),
            FilledButton.icon(
              onPressed: () => openMember4(
                context,
                ChatScreen(repo: widget.repo, rentalId: r.id),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Message Owner / Renter'),
            ),
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
          ],
        );
      },
    ),
  );
}
