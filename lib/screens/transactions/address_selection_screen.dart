import 'package:flutter/material.dart';

import '../../core/constants/dummy_shop_data.dart';
import '../../core/theme/shop_theme.dart';
import '../../models/shop_product.dart';
import '../../services/booking_draft_service.dart';
import 'confirm_order_screen.dart';
import 'widgets/address_card.dart';
import 'widgets/delivery_window_chips.dart';

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

/// Screen 3: Delivery Address & Schedule Selection
/// Replicates "7.4 Commercial Rental Shop Interfaces" (Report Page 17, Screen 3).
class AddressSelectionScreen extends StatefulWidget {
  const AddressSelectionScreen({
    super.key,
    this.product,
    this.range,
    this.initial,
  });

  final ShopProduct? product;
  final DateTimeRange? range;
  final DeliveryDetails? initial;

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final TextEditingController _instructionsController;

  static const _addressList = [
    {
      'id': 'home',
      'label': 'Home',
      'address': DummyShopData.homeAddress,
      'isHome': true,
    },
    {
      'id': 'work',
      'label': 'Work',
      'address': DummyShopData.workAddress,
      'isHome': false,
    },
  ];

  late String _selectedAddressId;
  late String _selectedAddressText;
  late String _selectedWindow;

  static const List<String> _windows = [
    'Morning\n9 AM - 12 PM',
    'Afternoon\n12 PM - 5 PM',
    'Evening\n5 PM - 8 PM',
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _selectedAddressId = 'home';
    _selectedAddressText = init?.address.isNotEmpty == true
        ? init!.address
        : DummyShopData.homeAddress;
    _instructionsController = TextEditingController(
      text: init?.instructions ?? DummyShopData.defaultInstructions,
    );
    _selectedWindow = _windows[1];
    _autoSave();
  }

  void _autoSave() {
    if (widget.product != null && widget.range != null) {
      BookingDraftService.instance.saveDraft(
        productId: widget.product!.id,
        range: widget.range!,
        isDelivery: true,
        deliveryAddress: _selectedAddressText,
        deliveryInstructions: _instructionsController.text.trim(),
        deliveryWindow: _selectedWindow.replaceAll('\n', ' • '),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _onConfirmAddress() {
    _autoSave();
    if (widget.product == null) {
      Navigator.pop(
        context,
        DeliveryDetails(
          address: _selectedAddressText,
          instructions: _instructionsController.text.trim(),
          window: _selectedWindow.replaceAll('\n', ' • '),
        ),
      );
      return;
    }

    final p = widget.product ?? DummyShopData.defaultProduct;
    final now = DateTime.now();
    final r = widget.range ??
        DateTimeRange(
          start: DateTime(now.year, 10, 15),
          end: DateTime(now.year, 10, 19),
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmOrderScreen(
          product: p,
          range: r,
          delivery: true,
          deliveryAddress: _selectedAddressText,
          deliveryInstructions: _instructionsController.text.trim(),
          deliveryWindow: _selectedWindow.replaceAll('\n', ' • '),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: ShopPalette.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Delivery Address',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // 1. Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ShopPalette.border),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search address or zip code...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: ShopPalette.textMuted,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: ShopPalette.textMuted,
                      size: 20,
                    ),
                    suffixIcon: Icon(
                      Icons.my_location_rounded,
                      color: ShopPalette.blue,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Saved Addresses Header
              const Text(
                'Saved Addresses',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ShopPalette.text,
                ),
              ),
              const SizedBox(height: 12),

              // Saved Addresses Cards using AddressCard widget
              ..._addressList.map((item) {
                final id = item['id'] as String;
                final label = item['label'] as String;
                final address = item['address'] as String;
                final isHome = item['isHome'] as bool;
                final isSelected = _selectedAddressId == id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AddressCard(
                    label: label,
                    address: address,
                    isHome: isHome,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedAddressId = id;
                        _selectedAddressText = address;
                      });
                      _autoSave();
                    },
                  ),
                );
              }),

              // + Add New Address
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Add new address modal triggered')),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: const [
                      Icon(Icons.add_rounded, color: ShopPalette.blue, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Add New Address',
                        style: TextStyle(
                          color: ShopPalette.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Delivery Instructions Header
              const Text(
                'Delivery Instructions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ShopPalette.text,
                ),
              ),
              const SizedBox(height: 8),

              // Delivery Instructions Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ShopPalette.border),
                ),
                child: TextField(
                  controller: _instructionsController,
                  onChanged: (_) => _autoSave(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: ShopPalette.text,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Leave instructions for courier...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: ShopPalette.textMuted,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Preferred Delivery Window Header
              const Text(
                'Preferred Delivery Window',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ShopPalette.text,
                ),
              ),
              const SizedBox(height: 12),

              // 3 Segmented Window Pills using DeliveryWindowChips widget
              DeliveryWindowChips(
                windows: _windows,
                selectedWindow: _selectedWindow,
                onSelected: (val) {
                  setState(() => _selectedWindow = val);
                  _autoSave();
                },
              ),
            ],
          ),

          // 5. Sticky Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ShopPalette.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _onConfirmAddress,
                  child: const Text(
                    'Confirm Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
