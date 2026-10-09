import 'package:flutter/material.dart';

import '../../core/constants/dummy_shop_data.dart';
import '../../core/theme/shop_theme.dart';
import '../../models/shop_product.dart';
import 'confirm_order_screen.dart';

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _onConfirmAddress() {
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

              // Saved Addresses Cards
              ..._addressList.map((item) {
                final id = item['id'] as String;
                final label = item['label'] as String;
                final address = item['address'] as String;
                final isHome = item['isHome'] as bool;
                final isSelected = _selectedAddressId == id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAddressId = id;
                        _selectedAddressText = address;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? ShopPalette.blueTint : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? ShopPalette.blue : ShopPalette.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? ShopPalette.blue.withValues(alpha: 0.14)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isHome
                                  ? Icons.home_rounded
                                  : Icons.work_outline_rounded,
                              size: 19,
                              color: isSelected
                                  ? ShopPalette.blue
                                  : ShopPalette.textMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: ShopPalette.text,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  address,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ShopPalette.textMuted,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: isSelected
                                ? ShopPalette.blue
                                : const Color(0xFFCBD5E1),
                          ),
                        ],
                      ),
                    ),
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

              // 3 Segmented Window Pills
              Row(
                children: _windows.map((w) {
                  final isSelected = _selectedWindow == w;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => setState(() => _selectedWindow = w),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ShopPalette.blueTint
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? ShopPalette.blue
                                  : ShopPalette.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            w,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? ShopPalette.blue
                                  : ShopPalette.text,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
