import 'package:flutter/material.dart';

import 'meetup_screen.dart';
import 'repository.dart';
import 'widgets.dart';

class ChatScreen extends StatefulWidget {
  final Member4Repository repo;
  final String rentalId;
  const ChatScreen({super.key, required this.repo, required this.rentalId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  bool busy = false;
  String? error, messageId, attemptedText;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty) {
      setState(() => error = 'Enter a message before sending.');
      return;
    }
    if (text.length > 2000) {
      setState(() => error = 'Messages must be under 2,000 characters.');
      return;
    }
    if (busy) return;
    if (attemptedText != text) messageId = widget.repo.newMessageId();
    attemptedText = text;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repo.send(widget.rentalId, messageId!, text);
      input.clear();
      messageId = null;
      attemptedText = null;
    } catch (e) {
      if (mounted) setState(() => error = member4Error(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Rental Conversation')),
    body: SafeArea(
      child: Column(
        children: [
          RentalView(
            repo: widget.repo,
            id: widget.rentalId,
            builder: (r) => ListTile(
              title: Text(r.counterpart(widget.repo.uid)),
              subtitle: Text(r.equipmentName),
              trailing: IconButton(
                tooltip: 'View shared meetup',
                icon: const Icon(Icons.location_on_outlined),
                onPressed: () => openMember4(
                  context,
                  MeetupScreen(repo: widget.repo, rentalId: r.id),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.repo.messages(widget.rentalId),
              builder: (context, s) {
                if (s.hasError) {
                  return DataState(
                    member4Error(s.error!),
                    retry: () => setState(() {}),
                  );
                }
                if (!s.hasData) {
                  return const DataState(
                    'Loading conversation…',
                    loading: true,
                  );
                }
                if (s.data!.isEmpty) {
                  return const DataState(
                    'No messages yet. Start the conversation.',
                  );
                }
                final messages = s.data!.reversed.toList();
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i],
                        own = m['senderId'] == widget.repo.uid;
                    final time = DateTime.tryParse(
                      m['createdAt'] as String? ?? '',
                    )?.toLocal();
                    return Align(
                      alignment: own
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * .78,
                        ),
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: own ? Member4Theme.blue : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE0E7EF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['text'] as String,
                              style: TextStyle(
                                color: own ? Colors.white : Member4Theme.navy,
                              ),
                            ),
                            if (m['kind'] == 'location') ...[
                              Text(
                                (m['location'] as Map)['name'] as String,
                                style: TextStyle(
                                  color: own ? Colors.white : Member4Theme.navy,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: own
                                      ? Colors.white
                                      : Member4Theme.blue,
                                ),
                                onPressed: () => openMember4(
                                  context,
                                  MeetupScreen(
                                    repo: widget.repo,
                                    rentalId: widget.rentalId,
                                    sharedLocation: Map<String, dynamic>.from(
                                      m['location'] as Map,
                                    ),
                                  ),
                                ),
                                child: const Text('View shared meetup'),
                              ),
                            ],
                            Text(
                              '${own ? 'Sent' : 'Received'}${time == null ? '' : ' · ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: own ? Colors.white : Member4Theme.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Semantics(
                liveRegion: true,
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    enabled: !busy,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                      counterText: '',
                    ),
                    onSubmitted: (_) => send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: busy ? 'Sending message' : 'Send message',
                  onPressed: busy ? null : send,
                  icon: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
