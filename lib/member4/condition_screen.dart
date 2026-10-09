import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'chat_screen.dart';
import 'models.dart';
import 'repository.dart';
import 'widgets.dart';

class ConditionScreen extends StatefulWidget {
  final Member4Repository repo;
  final String rentalId;
  final String phase;
  const ConditionScreen({
    super.key,
    required this.repo,
    required this.rentalId,
    required this.phase,
  });
  @override
  State<ConditionScreen> createState() => _ConditionScreenState();
}

class _ConditionScreenState extends State<ConditionScreen> {
  final notes = TextEditingController();
  final picker = ImagePicker();
  String angle = 'front';
  bool damage = false, busy = false, initialized = false;
  String? error, cue;
  XFile? pending;
  String? pendingAngle;
  @override
  void initState() {
    super.initState();
    recover();
  }

  Future<void> recover() async {
    try {
      final response = await picker.retrieveLostData();
      if (response.files?.isNotEmpty == true && mounted) {
        setState(() {
          pending = response.files!.first;
          cue = 'Recovered photo. Choose its angle, then tap Retry upload.';
        });
      }
    } catch (_) {
      /* Unsupported platforms have no lost activity data. */
    }
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function() operation) async {
    if (!mounted || busy) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await operation();
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              error = e is StateError ? e.message.toString() : member4Error(e),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> capture(ImageSource source, RentalRecord rental) =>
      run(() async {
        final file = await picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1800,
        );
        if (file == null) return;
        pending = file;
        pendingAngle = angle;
        await upload(rental);
      });
  Future<void> upload(RentalRecord rental) async {
    final savedAngle = pendingAngle ?? angle;
    await widget.repo.upload(rental.id, widget.phase, savedAngle, pending!);
    pending = null;
    pendingAngle = null;
    final remaining = photoAngles.keys
        .where(
          (key) =>
              key != savedAngle &&
              !rental.photos(widget.phase).containsKey(key),
        )
        .toList();
    if (mounted) {
      setState(() {
        cue =
            '${photoAngles[savedAngle]} View Saved. ${remaining.isEmpty ? 'Review all four photos.' : 'Next: ${photoAngles[remaining.first]} View'}';
        if (remaining.isNotEmpty) angle = remaining.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        '${widget.phase == 'pickup' ? 'Pickup' : 'Return'} Condition Check',
      ),
    ),
    body: RentalView(
      repo: widget.repo,
      id: widget.rentalId,
      retry: () => setState(() {}),
      builder: (r) {
        final check = r.condition(widget.phase),
            photos = r.photos(widget.phase);
        final locked =
            check['status'] == 'confirmed' ||
            r.status != (widget.phase == 'pickup' ? 'pending' : 'active');
        if (!initialized) {
          notes.text = check['notes'] as String? ?? '';
          damage = check['damageReported'] == true;
          initialized = true;
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${photos.length} / 4 photos saved · ${photoAngles[angle]} View',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            LinearProgressIndicator(value: photos.length / 4),
            const SizedBox(height: 16),
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: Member4Theme.navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: photos[angle] == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_camera_outlined,
                              size: 64,
                              color: Colors.white,
                            ),
                            Text(
                              'Capture ${photoAngles[angle]} View',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                            const Text(
                              'Keep the whole item in view. Use the labelled camera button below.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: PrivatePhoto(
                        repo: widget.repo,
                        path: photos[angle]!,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in photoAngles.entries)
                  ChoiceChip(
                    label: Text(
                      '${e.value}${photos.containsKey(e.key) ? ' ✓' : ''}',
                    ),
                    selected: angle == e.key,
                    onSelected: busy
                        ? null
                        : (_) => setState(() => angle = e.key),
                    avatar: photos.containsKey(e.key)
                        ? const Icon(Icons.check, size: 16)
                        : null,
                  ),
              ],
            ),
            if (cue != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Semantics(liveRegion: true, child: Text(cue!)),
              ),
            const Text(
              'These photographs serve as condition proof. Review each angle before confirming.',
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 16),
            if (!locked) ...[
              FilledButton.icon(
                onPressed: busy ? null : () => capture(ImageSource.camera, r),
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  '${photos[angle] == null ? 'Capture' : 'Retake'} ${photoAngles[angle]} View',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: busy ? null : () => capture(ImageSource.gallery, r),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text('Upload ${photoAngles[angle]} View'),
              ),
              if (pending != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: busy ? null : () => run(() => upload(r)),
                  child: const Text('Retry upload'),
                ),
              ],
            ],
            if (widget.phase == 'return' && r.photos('pickup')[angle] != null)
              ExpansionTile(
                title: Text('Compare pickup ${photoAngles[angle]} photo'),
                children: [
                  SizedBox(
                    height: 220,
                    child: PrivatePhoto(
                      repo: widget.repo,
                      path: r.photos('pickup')[angle]!,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            TextField(
              controller: notes,
              enabled: !locked && !busy,
              maxLength: 2000,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Condition notes',
                hintText: 'Describe existing marks or visible damage',
              ),
            ),
            CheckboxListTile(
              title: const Text('Visible damage requires review'),
              value: damage,
              onChanged: locked || busy
                  ? null
                  : (v) => setState(() => damage = v!),
            ),
            if (!locked)
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        await widget.repo.action(r.id, 'notes', {
                          'phase': widget.phase,
                          'notes': notes.text,
                          'damageReported': damage,
                        });
                        if (mounted) {
                          setState(() => cue = 'Condition notes saved.');
                        }
                      }),
                child: const Text('Save notes'),
              ),
            if (error != null)
              Semantics(
                liveRegion: true,
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 12),
            if (!locked)
              FilledButton(
                onPressed: busy || photos.length != 4
                    ? null
                    : () async {
                        if (damage && notes.text.trim().isEmpty) {
                          setState(
                            () => error = 'Describe the visible damage before confirming.',
                          );
                          return;
                        }
                        if (!await confirmAction(
                          context,
                          'Confirm condition evidence?',
                          'All four photographs and notes become read-only. Review them first.',
                        )) {
                          return;
                        }
                        await run(() async {
                          await widget.repo.action(r.id, 'notes', {
                            'phase': widget.phase,
                            'notes': notes.text,
                            'damageReported': damage,
                          });
                          await widget.repo.action(r.id, 'submitCondition', {
                            'phase': widget.phase,
                          });
                          if (mounted) {
                            setState(
                              () => cue = 'Condition evidence confirmed. Return to the handover checklist.',
                            );
                          }
                        });
                      },
                child: const Text('Confirm all four condition photos'),
              ),
            if (!locked && photos.length < 4)
              Text('${4 - photos.length} required views remaining.'),
            if (locked)
              const Panel(
                child: Text('Condition evidence is confirmed and read-only.'),
              ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => openMember4(
                context,
                ChatScreen(repo: widget.repo, rentalId: r.id),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Open rental chat'),
            ),
          ],
        );
      },
    ),
  );
}
