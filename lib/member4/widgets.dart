import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'models.dart';
import 'repository.dart';

class Member4Theme {
  static const blue = Color(0xFF2F80ED);
  static const navy = Color(0xFF123B5D);
  static const orange = Color(0xFFFF8A3D);
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF6F8FA),
    colorScheme: ColorScheme.fromSeed(
      seedColor: blue,
      primary: blue,
      secondary: orange,
      onSurface: navy,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: navy,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E7EF)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
  );
}

void openMember4(BuildContext context, Widget screen) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(data: Member4Theme.theme, child: screen),
      ),
    );

class Panel extends StatelessWidget {
  final Widget child;
  const Panel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

class DataState extends StatelessWidget {
  final String message;
  final VoidCallback? retry;
  final bool loading;
  const DataState(this.message, {super.key, this.retry, this.loading = false});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading) const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class RentalView extends StatefulWidget {
  final Member4Repository repo;
  final String id;
  final Widget Function(RentalRecord) builder;
  final VoidCallback? retry;
  const RentalView({
    super.key,
    required this.repo,
    required this.id,
    required this.builder,
    this.retry,
  });
  @override
  State<RentalView> createState() => _RentalViewState();
}

class _RentalViewState extends State<RentalView> {
  late Stream<RentalRecord?> rental = widget.repo.rental(widget.id);

  @override
  void didUpdateWidget(RentalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repo != widget.repo || oldWidget.id != widget.id) {
      rental = widget.repo.rental(widget.id);
    }
  }

  void retry() {
    setState(() => rental = widget.repo.rental(widget.id));
    widget.retry?.call();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<RentalRecord?>(
    stream: rental,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return DataState(member4Error(snapshot.error!), retry: retry);
      }
      if (snapshot.connectionState == ConnectionState.waiting &&
          !snapshot.hasData) {
        return const DataState('Loading handover details…', loading: true);
      }
      if (snapshot.data == null) {
        return const DataState('Rental not found or no longer available.');
      }
      return widget.builder(snapshot.data!);
    },
  );
}

class EquipmentCard extends StatelessWidget {
  final RentalRecord rental;
  const EquipmentCard(this.rental, {super.key});
  @override
  Widget build(BuildContext context) => Panel(
    child: Row(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child:
              rental.data['equipmentImageUrl'] is String &&
                  (rental.data['equipmentImageUrl'] as String).isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    rental.data['equipmentImageUrl'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.sports, size: 36),
                  ),
                )
              : const Icon(
                  Icons.sports,
                  size: 36,
                  semanticLabel: 'Sports equipment',
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rental.equipmentName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('${rental.data['ownerName']} · Owner'),
              Text(rental.dateLabel),
              Text(
                '${rental.money(rental.data['dailyRate'] as num)} / day',
                style: const TextStyle(
                  color: Member4Theme.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class PrivatePhoto extends StatefulWidget {
  final Member4Repository repo;
  final String path;
  const PrivatePhoto({super.key, required this.repo, required this.path});
  @override
  State<PrivatePhoto> createState() => _PrivatePhotoState();
}

class _PrivatePhotoState extends State<PrivatePhoto> {
  late Future<Uint8List?> bytes = widget.repo.photo(widget.path);
  @override
  void didUpdateWidget(PrivatePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) bytes = widget.repo.photo(widget.path);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: bytes,
    builder: (context, s) {
      if (s.hasError) {
        return DataState(
          'Unable to load photo.',
          retry: () => setState(() => bytes = widget.repo.photo(widget.path)),
        );
      }
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      return Image.memory(
        s.data!,
        fit: BoxFit.contain,
        semanticLabel: 'Saved equipment condition evidence',
      );
    },
  );
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String detail,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(detail),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
    false;

class DepositCard extends StatelessWidget {
  final RentalRecord rental;
  const DepositCard(this.rental, {super.key});
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Refundable Security Deposit',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          rental.money(rental.deposit['amount'] as num),
          style: const TextStyle(
            color: Member4Theme.navy,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text('Status: ${depositLabel(rental.deposit['status'] as String)}'),
        const SizedBox(height: 8),
        const Text(
          'Separate from the rental charge. Release is reviewed after both parties confirm return and condition evidence.',
        ),
        const SizedBox(height: 8),
        const Text(
          'This app records deposit review status. A payment provider must confirm any real hold or refund.',
        ),
      ],
    ),
  );
}

String depositLabel(String value) => switch (value) {
  'recorded' => 'Recorded for this rental',
  'reviewRequired' => 'Damage review required',
  'releasePending' => 'Return verified — release review pending',
  'released' => 'Release confirmed by payment provider',
  _ => 'Awaiting pickup verification',
};
