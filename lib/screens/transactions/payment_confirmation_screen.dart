import 'package:flutter/material.dart';

import '../../core/constants/dummy_shop_data.dart';
import '../../core/theme/shop_theme.dart';
import '../../core/utils/format.dart';
import '../../models/rental_transaction.dart';
import 'transactions_screen.dart';

/// Screen 5: Booking Confirmed!
/// Replicates "7.4 Commercial Rental Shop Interfaces" (Report Page 17, Screen 5).
class PaymentConfirmationScreen extends StatelessWidget {
  const PaymentConfirmationScreen({super.key, required this.transaction});

  final RentalTransaction transaction;

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    final t = transaction;
    final bookingRefText = t.bookingRef.startsWith('#')
        ? t.bookingRef
        : '#${t.bookingRef}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // 1. Success Circular Icon Badge
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: ShopPalette.orange,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ShopPalette.orange.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: ShopPalette.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              // Title and Booking Reference
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ShopPalette.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'BOOKING REF: $bookingRefText',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ShopPalette.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 24),

              // 2. Booking Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ShopPalette.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Equipment Row
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            DummyShopData.defaultHeroImage,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 48,
                              height: 48,
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
                              Text(
                                t.productName.isEmpty
                                    ? DummyShopData.defaultProduct.name
                                    : t.productName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: ShopPalette.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                DummyShopData.shopName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ShopPalette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: ShopPalette.border),
                    ),

                    // Key-Value Table Rows
                    _tableRow(
                      'RENTAL DATES',
                      '${fmtDate(t.startDate)} - ${fmtDate(t.endDate)} (${t.days} days)',
                    ),
                    const SizedBox(height: 10),
                    _tableRow(
                      'FULFILLMENT',
                      t.isDelivery ? 'Doorstep Delivery' : 'Self Pickup',
                    ),
                    const SizedBox(height: 10),
                    _tableRow(
                      'AMOUNT PAID',
                      '${money(t.dueNow)} (Paid)',
                      highlight: true,
                    ),
                    const SizedBox(height: 10),
                    _tableRow(
                      'SECURITY HOLD',
                      '${money(t.deposit)} (Released within 48h of return)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Host Card
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ShopPalette.border),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          NetworkImage(DummyShopData.hostAvatar),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'HOST',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: ShopPalette.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            DummyShopData.shopName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: ShopPalette.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _actionCircleButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Opening chat with host...')),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _actionCircleButton(
                      icon: Icons.phone_outlined,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Calling Apex Trail Rentals...')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 4. Action Buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ShopPalette.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TransactionsScreen()),
                      (route) => route.isFirst,
                    );
                  },
                  child: const Text(
                    'View My Bookings',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ShopPalette.text,
                    side: const BorderSide(color: Color(0xFF94A3B8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ShopPalette.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: highlight ? ShopPalette.blue : ShopPalette.text,
          ),
        ),
      ],
    );
  }

  Widget _actionCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
        border: Border.all(color: ShopPalette.border),
      ),
      child: IconButton(
        icon: Icon(icon, color: ShopPalette.blue, size: 18),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
