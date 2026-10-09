import 'package:flutter/material.dart';

import '../../core/theme/shop_theme.dart';
/// Delivery information returned by [AddressSelectionScreen].
class DeliveryDetails {
  const DeliveryDetails({
    required this.address,
    required this.instructions,
    required this.window,
  });

  final String address;
  final String instructions;
  final String window;
}

class _SavedAddress {
  const _SavedAddress(this.label, this.text);
  final String label;
  final String text;
}

/// Address Selection: choose/add an address, delivery notes and a time window.
/// Pops with a [DeliveryDetails] when the user confirms.
class AddressSelectionScreen extends StatefulWidget {
  const AddressSelectionScreen({super.key, this.initial});

  final DeliveryDetails? initial;

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  /// Addresses saved during this app session.
  static final List<_SavedAddress> _saved = [];

  static const _windows = [
    'Morning (9 AM - 12 PM)',
    'Afternoon (12 PM - 5 PM)',
    'Evening (5 PM - 8 PM)',
  ];

  late final TextEditingController _instructions;
  int? _selected;
  String _window = _windows[1];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _instructions = TextEditingController(text: initial?.instructions ?? '');
    if (initial != null) {
      if (_windows.contains(initial.window)) _window = initial.window;
      if (initial.address.isNotEmpty) {
        var idx = _saved.indexWhere((a) => a.text == initial.address);
        if (idx == -1) {
          _saved.add(_SavedAddress('Address', initial.address));
          idx = _saved.length - 1;
        }
        _selected = idx;
      }
    }
  }

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _addAddress() async {
    final label = TextEditingController();
    final text = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add new address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: label,
              decoration: const InputDecoration(
                labelText: 'Label (e.g. Home, Work)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: text,
              decoration: const InputDecoration(labelText: 'Full address'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final l = label.text.trim();
    final t = text.text.trim();
    label.dispose();
    text.dispose();
    if (!mounted) return;
    if (added == true && t.isNotEmpty) {
      setState(() {
        _saved.add(_SavedAddress(l.isEmpty ? 'Address' : l, t));
        _selected = _saved.length - 1;
      });
    }
  }

  void _confirm() {
    final sel = _selected;
    if (sel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add an address')),
      );
      return;
    }
    Navigator.pop(
      context,
      DeliveryDetails(
        address: _saved[sel].text,
        instructions: _instructions.text.trim(),
        window: _window,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery address')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Saved Addresses', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_saved.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No saved addresses yet. Add one below.'),
            ),
          for (var i = 0; i < _saved.length; i++)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: _selected == i
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                onTap: () => setState(() => _selected = i),
                leading: Icon(i == 0
                    ? Icons.home_outlined
                    : Icons.location_on_outlined),
                title: Text(_saved[i].label),
                subtitle: Text(_saved[i].text),
                trailing: Icon(_selected == i
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
              ),
            ),
          TextButton.icon(
            onPressed: _addAddress,
            icon: const Icon(Icons.add),
            label: const Text('Add New Address'),
          ),
          const SizedBox(height: 12),
          Text('Delivery Instructions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _instructions,
            decoration: const InputDecoration(
              hintText: 'e.g. Leave at front door, ring bell',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Text('Preferred Delivery Window', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _windows
                .map((w) => ChoiceChip(
                      label: Text(w),
                      selected: _window == w,
                      onSelected: (_) => setState(() => _window = w),
                    ))
                .toList(),
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _confirm,
            child: const Text('Confirm Address'),
          ),
        ),
      ),
    );
  }
}
