import 'package:flutter/material.dart';

import '../../core/constants/dummy_shop_data.dart';
import '../../core/theme/shop_theme.dart';
import '../../core/utils/format.dart';
import '../../models/rental_transaction.dart';
import '../../models/shop_product.dart';
import '../../services/booking_draft_service.dart';
import 'address_selection_screen.dart';
import 'confirm_order_screen.dart';

/// Screen 2: Checkout & Fulfillment Selection
/// Replicates "7.4 Commercial Rental Shop Interfaces" (Report Page 17, Screen 2).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.product,
    required this.range,
    this.delivery = true,
  });

  final ShopProduct product;
  final DateTimeRange range;
  final bool delivery;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late bool _delivery;

  @override
  void initState() {
    super.initState();
    _delivery = widget.delivery;
    _autoSaveDraft();
  }

  void _autoSaveDraft() {
    BookingDraftService.instance.saveDraft(
      productId: widget.product.id,
      range: widget.range,
      isDelivery: _delivery,
    );
  }

  int get _days =>
      calculateRentalDays(widget.range.start, widget.range.end);

  PriceBreakdown get _price => PriceBreakdown.calculate(
        pricePerDay: widget.product.pricePerDay,
        days: _days,
        deposit: widget.product.deposit,
        delivery: _delivery,
      );

  void _onContinue() {
    _autoSaveDraft();
    if (_delivery) {
      // Navigate to Screen 3: Delivery Address
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddressSelectionScreen(
            product: widget.product,
            range: widget.range,
          ),
        ),
      );
    } else {
      // Navigate directly to Screen 4: Confirm Order for Self Pickup
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmOrderScreen(
            product: widget.product,
            range: widget.range,
            delivery: false,
            deliveryAddress: DummyShopData.pickupLocation,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    final p = widget.product;
    final price = _price;
    final heroUrl = p.imageUrl.trim().isNotEmpty
        ? p.imageUrl.trim()
        : DummyShopData.defaultHeroImage;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ShopPalette.text,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ShopPalette.text,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // 1. Equipment Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ShopPalette.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        heroUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 64,
                          height: 64,
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.directions_bike),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ShopPalette.badgeBlue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p.category.toUpperCase(),
                              style: const TextStyle(
                                color: ShopPalette.badgeBlueText,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ShopPalette.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${fmtDate(widget.range.start)} - ${fmtDate(widget.range.end)} • $_days Day${_days == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ShopPalette.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Fulfillment Section Header
              const Text(
                'How would you like to get your gear?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ShopPalette.text,
                ),
              ),
              const SizedBox(height: 12),

              // Option A: Self Pickup
              _fulfillmentCard(
                title: 'Self Pickup',
                trailingText: 'Free',
                subtitle: DummyShopData.pickupLocation,
                icon: Icons.location_on_outlined,
                selected: !_delivery,
                onTap: () {
                  setState(() => _delivery = false);
                  _autoSaveDraft();
                },
              ),
              const SizedBox(height: 12),

              // Option B: GearGo Delivery
              _fulfillmentCard(
                title: 'GearGo Delivery',
                trailingText: '+${money(PriceBreakdown.deliveryFlatFee)}',
                subtitle: DummyShopData.deliveryDescription,
                icon: Icons.local_shipping_outlined,
                selected: _delivery,
                onTap: () {
                  setState(() => _delivery = true);
                  _autoSaveDraft();
                },
              ),
              const SizedBox(height: 24),

              // 3. Price Details Section Header
              const Text(
                'PRICE DETAILS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ShopPalette.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              // Price Breakdown Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ShopPalette.border),
                ),
                child: Column(
                  children: [
                    _priceRow(
                      'Rental (${money(p.pricePerDay)} x $_days days)',
                      money(price.rentalFee),
                    ),
                    const SizedBox(height: 10),
                    _priceRow(
                      'Delivery Fee',
                      _delivery ? money(price.deliveryFee) : 'Free',
                      valueColor: _delivery ? ShopPalette.blue : null,
                    ),
                    const SizedBox(height: 10),
                    _priceRow(
                      'Service Fee',
                      money(price.serviceFee),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: ShopPalette.border),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Due Now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ShopPalette.text,
                          ),
                        ),
                        Text(
                          money(price.dueNow),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: ShopPalette.text,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 4. Sticky Bottom Action Bar
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
                  onPressed: _onContinue,
                  child: const Text(
                    'Continue',
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

  Widget _fulfillmentCard({
    required String title,
    required String trailingText,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? ShopPalette.blueTint : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? ShopPalette.blue : ShopPalette.border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? ShopPalette.blue.withValues(alpha: 0.12)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? ShopPalette.blue : ShopPalette.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ShopPalette.text,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            trailingText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? ShopPalette.blue
                                  : ShopPalette.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            selected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 18,
                            color: selected
                                ? ShopPalette.blue
                                : const Color(0xFFCBD5E1),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: ShopPalette.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? ShopPalette.text,
          ),
        ),
      ],
    );
  }
}
