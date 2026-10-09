import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/image_helper.dart';
import '../../models/equipment.dart';
import '../../services/equipment_service.dart';

/// Commercial rental shop persona (SPSE De Silva): batch inventory & shop logistics.
class CommercialShopConsoleScreen extends StatefulWidget {
  final String ownerId;
  const CommercialShopConsoleScreen({super.key, required this.ownerId});

  @override
  State<CommercialShopConsoleScreen> createState() =>
      _CommercialShopConsoleScreenState();
}

class _CommercialShopConsoleScreenState extends State<CommercialShopConsoleScreen> {
  final _service = EquipmentService();
  final _pickupLocation = TextEditingController(text: 'De Silva Sports — Colombo 03');
  final _openingHours = TextEditingController(text: 'Mon–Sat 8:00–18:00');
  String _deliveryWindow = 'Morning';
  bool _batchBusy = false;

  static const _windows = ['Morning', 'Afternoon', 'Evening'];

  @override
  void dispose() {
    _pickupLocation.dispose();
    _openingHours.dispose();
    super.dispose();
  }

  Future<void> _batchUploadPresets() async {
    setState(() => _batchBusy = true);
    try {
      final presets = GearImagePreset.presets.take(4);
      for (final preset in presets) {
        await _service.createEquipment(
          Equipment(
            id: '',
            ownerId: widget.ownerId,
            name: '${preset.title} (Shop Unit)',
            categoryId: preset.categoryId,
            description:
                'Commercial shop listing with tiered pricing. Pickup: ${_pickupLocation.text}. '
                'Hours: ${_openingHours.text}. Preferred delivery window: $_deliveryWindow.',
            price: 25,
            availability: true,
            image: preset.imageUrl,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            location: _pickupLocation.text,
            priceWeekly: 140,
            priceMonthly: 480,
            stockUnits: 3,
            shopPickupLocation: _pickupLocation.text,
            shopOpeningHours: _openingHours.text,
            deliveryWindow: _deliveryWindow,
          ),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch uploaded 4 shop units with tiered rates.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _batchBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commercial Shop Console')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Multi-unit inventory',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _batchBusy ? null : _batchUploadPresets,
            icon: const Icon(Icons.upload_file),
            label: Text(_batchBusy ? 'Uploading…' : 'Batch upload sample units'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pickup location & hours',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: _pickupLocation,
            decoration: const InputDecoration(labelText: 'Commercial pickup location'),
          ),
          TextField(
            controller: _openingHours,
            decoration: const InputDecoration(labelText: 'Opening hours'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Delivery window',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Wrap(
            spacing: 8,
            children: _windows
                .map(
                  (w) => ChoiceChip(
                    label: Text(w),
                    selected: _deliveryWindow == w,
                    onSelected: (_) => setState(() => _deliveryWindow = w),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tiered duration pricing is stored on each listing (daily / weekly / monthly). '
            'Edit individual units from Manage Listings.',
            style: TextStyle(fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }
}
