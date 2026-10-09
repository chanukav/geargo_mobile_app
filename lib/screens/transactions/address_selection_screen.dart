import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/shop_theme.dart';
import '../../services/address_service.dart';

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

/// Address Selection: choose/add an address, delivery notes and a time window.
/// Addresses are stored in Firestore at users/{uid}/addresses.
/// Pops with a [DeliveryDetails] when the user confirms.
class AddressSelectionScreen extends StatefulWidget {
  const AddressSelectionScreen({super.key, this.initial});

  final DeliveryDetails? initial;

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  final AddressService _addressService = AddressService();

  static const _windows = [
    'Morning (9 AM - 12 PM)',
    'Afternoon (12 PM - 5 PM)',
    'Evening (5 PM - 8 PM)',
  ];

  late final TextEditingController _instructions;
  String? _selectedAddressText;
  String? _selectedId;
  String _window = _windows[1];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _instructions = TextEditingController(text: initial?.instructions ?? '');
    if (initial != null) {
      if (_windows.contains(initial.window)) _window = initial.window;
      if (initial.address.isNotEmpty) {
        _selectedAddressText = initial.address;
      }
    }
  }

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _addAddress() async {
    final messenger = ScaffoldMessenger.of(context);
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
      if (FirebaseAuth.instance.currentUser == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Please sign in to save a delivery address.')),
        );
        return;
      }
      try {
        final newId = await _addressService.addAddress(
          label: l.isEmpty ? 'Address' : l,
          text: t,
        );
        if (mounted) {
          setState(() {
            _selectedId = newId;
            _selectedAddressText = t;
          });
          messenger.showSnackBar(const SnackBar(content: Text('Address saved')));
        }
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Could not save address: $e')));
      }
    }
  }

  Future<void> _confirmDelete(UserAddress address) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('Remove "${address.label}: ${address.text}" from your saved addresses?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _addressService.deleteAddress(address.id);
      if (mounted) {
        if (_selectedId == address.id || _selectedAddressText == address.text) {
          setState(() {
            _selectedId = null;
            _selectedAddressText = null;
          });
        }
        messenger.showSnackBar(const SnackBar(content: Text('Address deleted')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not delete address: $e')));
    }
  }

  void _confirm() {
    final addressToUse = _selectedAddressText;
    if (addressToUse == null || addressToUse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add an address')),
      );
      return;
    }
    Navigator.pop(
      context,
      DeliveryDetails(
        address: addressToUse,
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
      body: StreamBuilder<List<UserAddress>>(
        stream: _addressService.streamAddresses(),
        builder: (context, snap) {
          final addresses = snap.data ?? const <UserAddress>[];

          // Auto-select first address if none selected and not explicitly cleared
          if (_selectedAddressText == null && _selectedId == null && addresses.isNotEmpty) {
            _selectedId = addresses.first.id;
            _selectedAddressText = addresses.first.text;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Saved Addresses', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (FirebaseAuth.instance.currentUser == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Please sign in to save and sync delivery addresses.'),
                )
              else if (snap.connectionState == ConnectionState.waiting && addresses.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (addresses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No saved addresses yet. Add one below.'),
                )
              else
                for (var i = 0; i < addresses.length; i++) ...[
                  () {
                    final addr = addresses[i];
                    final isSelected = (_selectedId != null && _selectedId == addr.id) ||
                        (_selectedAddressText != null && _selectedAddressText == addr.text);
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => setState(() {
                          _selectedId = addr.id;
                          _selectedAddressText = addr.text;
                        }),
                        leading: Icon(i == 0
                            ? Icons.home_outlined
                            : Icons.location_on_outlined),
                        title: Text(addr.label),
                        subtitle: Text(addr.text),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              tooltip: 'Delete address',
                              onPressed: () => _confirmDelete(addr),
                            ),
                            Icon(isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked),
                          ],
                        ),
                      ),
                    );
                  }(),
                ],
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
          );
        },
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
