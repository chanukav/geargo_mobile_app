import 'package:flutter/material.dart';

import '../../core/constants/dummy_shop_data.dart';
import '../../core/theme/shop_theme.dart';
import '../../core/utils/format.dart';
import '../../models/shop_product.dart';
import '../../services/booking_draft_service.dart';
import 'checkout_screen.dart';
import 'widgets/fulfillment_toggle.dart';

/// Screen 1: Equipment Detail & Booking Configuration
/// Replicates "7.4 Commercial Rental Shop Interfaces" (Report Page 17, Screen 1).
class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key, required this.product});

  final ShopProduct product;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  late DateTimeRange _range;
  bool _delivery = false; // false = Self Pickup, true = Door Delivery
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    // Restore existing draft if for this product, otherwise default to prototype dates (NFR-04)
    final draft = BookingDraftService.instance.draft;
    if (draft != null && draft.productId == widget.product.id) {
      _range = DateTimeRange(start: draft.startDate, end: draft.endDate);
      _delivery = draft.isDelivery;
    } else {
      final now = DateTime.now();
      final start = DateTime(now.year, 10, 15);
      final end = DateTime(now.year, 10, 19);
      _range = DateTimeRange(start: start, end: end);
    }
    _autoSaveDraft();
  }

  void _autoSaveDraft() {
    BookingDraftService.instance.saveDraft(
      productId: widget.product.id,
      range: _range,
      isDelivery: _delivery,
    );
  }

  int get _days => calculateRentalDays(_range.start, _range.end);

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today.subtract(const Duration(days: 30)),
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: _range,
      helpText: 'Select Rental Period',
    );
    if (picked != null) {
      if (!picked.end.isAfter(picked.start)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rental return date must be after pickup date.'),
          ),
        );
        return;
      }
      setState(() {
        _range = picked;
        _autoSaveDraft();
      });
    }
  }

  void _proceedToCheckout() {
    _autoSaveDraft();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          product: widget.product,
          range: _range,
          delivery: _delivery,
        ),
      ),
    );
  }

  String _formatDateShort(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final w = weekdays[d.weekday - 1];
    return '$w, ${fmtDate(d)}';
  }

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    final p = widget.product;
    final heroUrl = p.imageUrl.trim().isNotEmpty
        ? p.imageUrl.trim()
        : DummyShopData.defaultHeroImage;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable Page Content
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 1. Hero Image with Overlay Actions
                Stack(
                  children: [
                    SizedBox(
                      height: 280,
                      width: double.infinity,
                      child: Image.network(
                        heroUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFF1E293B),
                          child: const Icon(
                            Icons.directions_bike,
                            size: 80,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    // Dark Gradient Overlay for icon contrast
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Top App Bar Icons
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _circleIconButton(
                              icon: Icons.arrow_back,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            Row(
                              children: [
                                _circleIconButton(
                                  icon: Icons.ios_share_outlined,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Share link copied')),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                _circleIconButton(
                                  icon: _isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _isFavorite
                                      ? Colors.red
                                      : Colors.white,
                                  onTap: () {
                                    setState(() => _isFavorite = !_isFavorite);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // 2. Main Details Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tag and Price Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ShopPalette.badgeBlue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.category.toUpperCase(),
                              style: const TextStyle(
                                color: ShopPalette.badgeBlueText,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                money(p.pricePerDay),
                                style: const TextStyle(
                                  color: ShopPalette.blue,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                ' /day',
                                style: TextStyle(
                                  color: ShopPalette.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Equipment Title
                      Text(
                        p.name,
                        style: const TextStyle(
                          color: ShopPalette.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Shop / Lender Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: ShopPalette.border),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 22,
                              backgroundImage: NetworkImage(
                                DummyShopData.hostAvatar,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Text(
                                        DummyShopData.shopName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: ShopPalette.text,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: ShopPalette.blue,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.star_rounded,
                                        size: 16,
                                        color: Color(0xFFF59E0B),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        DummyShopData.shopRating,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: ShopPalette.textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: ShopPalette.border),
                              ),
                              child: IconButton(
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: ShopPalette.blue,
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Opening chat with Apex Trail Rentals...'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Rental Period
                      const Text(
                        'Rental Period',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ShopPalette.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickRange,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: ShopPalette.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PICKUP DATE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: ShopPalette.textMuted,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 15,
                                          color: ShopPalette.blue,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatDateShort(_range.start),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: ShopPalette.text,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: ShopPalette.textMuted,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'RETURN DATE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: ShopPalette.textMuted,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 15,
                                          color: ShopPalette.blue,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatDateShort(_range.end),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
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
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Fulfillment Option
                      const Text(
                        'Fulfillment Option',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ShopPalette.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FulfillmentToggle(
                        isDelivery: _delivery,
                        onChanged: (val) {
                          setState(() {
                            _delivery = val;
                            _autoSaveDraft();
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Equipment Condition
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Equipment Condition',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ShopPalette.text,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: ShopPalette.greenTint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.condition.toUpperCase(),
                              style: const TextStyle(
                                color: ShopPalette.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.description.isEmpty
                            ? DummyShopData.defaultProduct.description
                            : p.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3 Thumbnails Gallery
                      Row(
                        children: DummyShopData.detailThumbnails
                            .map((url) => Expanded(
                                  child: Container(
                                    height: 72,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: ShopPalette.border),
                                      image: DecorationImage(
                                        image: NetworkImage(url),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Sticky Bottom Action Bar
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
                  onPressed: _proceedToCheckout,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Proceed to Checkout ($_days day${_days == 1 ? '' : 's'})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
