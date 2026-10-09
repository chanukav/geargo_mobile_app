import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/dummy_shop_data.dart';
import '../../core/theme/shop_theme.dart';
import '../../core/utils/format.dart';
import '../../models/rental_transaction.dart';
import '../../models/shop_product.dart';
import '../../services/booking_draft_service.dart';
import '../../services/payment_service.dart';
import '../../services/transaction_service.dart';
import 'address_selection_screen.dart';
import 'payment_confirmation_screen.dart';
import 'widgets/deposit_hold_card.dart';
import 'widgets/security_badge.dart';

/// Screen 4: Confirm Order & Payment Breakdown
/// Replicates "7.4 Commercial Rental Shop Interfaces" (Report Page 17, Screen 4).
class ConfirmOrderScreen extends StatefulWidget {
  const ConfirmOrderScreen({
    super.key,
    required this.product,
    required this.range,
    this.delivery = true,
    this.deliveryAddress,
    this.deliveryInstructions,
    this.deliveryWindow,
  });

  final ShopProduct product;
  final DateTimeRange range;
  final bool delivery;
  final String? deliveryAddress;
  final String? deliveryInstructions;
  final String? deliveryWindow;

  @override
  State<ConfirmOrderScreen> createState() => _ConfirmOrderScreenState();
}

class _ConfirmOrderScreenState extends State<ConfirmOrderScreen> {
  final TransactionService _service = TransactionService();
  bool _processing = false;
  late String _address;

  @override
  void initState() {
    super.initState();
    _address = widget.deliveryAddress ?? DummyShopData.defaultDeliveryAddress;
  }

  int get _days =>
      calculateRentalDays(widget.range.start, widget.range.end);

  PriceBreakdown get _price => PriceBreakdown.calculate(
        pricePerDay: widget.product.pricePerDay,
        days: _days,
        deposit: widget.product.deposit,
        delivery: widget.delivery,
      );

  Future<void> _changeAddress() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddressSelectionScreen(
          product: widget.product,
          range: widget.range,
        ),
      ),
    );
  }

  Future<void> _confirmAndPay() async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      final price = _price;
      // Satisfies NFR-02: process simulated payment through abstract payment gateway
      const paymentService = MockPaymentService();
      final paymentResult = await paymentService.processPayment(
        amount: price.dueNow,
        paymentMethod: DummyShopData.defaultPaymentMethod,
        bookingRef: DummyShopData.sampleBookingRef,
      );

      if (!paymentResult.isSuccess) {
        throw Exception(paymentResult.message);
      }

      final user = FirebaseAuth.instance.currentUser;
      RentalTransaction txn;

      if (user != null) {
        txn = await _service.createBooking(
          product: widget.product,
          start: widget.range.start,
          end: widget.range.end,
          delivery: widget.delivery,
          address: _address,
          instructions: widget.deliveryInstructions ??
              DummyShopData.defaultInstructions,
          window: widget.deliveryWindow ?? 'Afternoon (12 PM - 5 PM)',
          paymentMethod: DummyShopData.defaultPaymentMethod,
        );
      } else {
        // High-fidelity fallback for offline / viva demo matching prototype
        txn = RentalTransaction(
          id: 'demo-txn-8942',
          bookingRef: DummyShopData.sampleBookingRef,
          renterId: 'demo-renter',
          shopId: widget.product.ownerId,
          productId: widget.product.id,
          productName: widget.product.name,
          startDate: widget.range.start,
          endDate: widget.range.end,
          days: _days,
          fulfillment: widget.delivery ? 'delivery' : 'pickup',
          deliveryAddress: _address,
          deliveryInstructions: widget.deliveryInstructions ??
              DummyShopData.defaultInstructions,
          deliveryWindow:
              widget.deliveryWindow ?? 'Afternoon (12 PM - 5 PM)',
          rentalFee: price.rentalFee,
          serviceFee: price.serviceFee,
          deliveryFee: price.deliveryFee,
          deposit: price.deposit,
          dueNow: price.dueNow,
          total: price.total,
          paymentMethod: DummyShopData.defaultPaymentMethod,
          paymentStatus: 'paid',
          status: 'confirmed',
          createdAt: DateTime.now(),
        );
      }

      // Satisfies NFR-04: Clear active booking draft upon completed booking
      BookingDraftService.instance.clearDraft();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentConfirmationScreen(transaction: txn),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    final p = widget.product;
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
          'Confirm Order',
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
              // 1. Product Summary Card
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
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 58,
                          height: 58,
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
                            p.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ShopPalette.text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'by ${DummyShopData.shopName}',
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
              const SizedBox(height: 16),

              // 2. Dates & Address Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ShopPalette.border),
                ),
                child: Column(
                  children: [
                    // Dates Row
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: ShopPalette.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${fmtDate(widget.range.start)} - ${fmtDate(widget.range.end)}, ${widget.range.start.year}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ShopPalette.text,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$_days DAYS',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: ShopPalette.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: ShopPalette.border),
                    ),
                    // Delivery Address Header & Change link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.delivery
                              ? 'DELIVERY ADDRESS'
                              : 'PICKUP LOCATION',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ShopPalette.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (widget.delivery)
                          InkWell(
                            onTap: _changeAddress,
                            child: const Text(
                              'CHANGE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ShopPalette.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: ShopPalette.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _address,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ShopPalette.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Payment Method Section Header
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ShopPalette.text,
                ),
              ),
              const SizedBox(height: 8),

              // Payment Method Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ShopPalette.blue,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ShopPalette.blueTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.credit_card_rounded,
                        color: ShopPalette.blue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            DummyShopData.defaultPaymentMethod,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ShopPalette.text,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            DummyShopData.defaultPaymentExpiry,
                            style: TextStyle(
                              fontSize: 12,
                              color: ShopPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: ShopPalette.blue,
                      size: 22,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Visible Security Assurance Badge (NFR-02)
              const SecurityBadge(),
              const SizedBox(height: 20),

              // 4. Price Breakdown Header
              const Text(
                'Price Breakdown',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ShopPalette.text,
                ),
              ),
              const SizedBox(height: 8),

              // Price Breakdown Table Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ShopPalette.border),
                ),
                child: Column(
                  children: [
                    _breakdownRow(
                      'Rental Fee (${money(p.pricePerDay)} x $_days days)',
                      money(_price.rentalFee),
                    ),
                    const SizedBox(height: 10),
                    _breakdownRow(
                      'GearGo Service Fee (8%)',
                      money(_price.serviceFee),
                    ),
                    const SizedBox(height: 10),
                    _breakdownRow(
                      'Delivery Fee',
                      widget.delivery ? money(_price.deliveryFee) : 'Free',
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
                          money(_price.dueNow),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: ShopPalette.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Deposit Hold Card (UI-01 explicit separation)
              DepositHoldCard(depositAmount: _price.deposit),
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
                  onPressed: _processing ? null : _confirmAndPay,
                  child: _processing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Confirm & Pay ${money(_price.dueNow)}',
                          style: const TextStyle(
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

  Widget _breakdownRow(String label, String value) {
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ShopPalette.text,
          ),
        ),
      ],
    );
  }
}
