import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_helper.dart';
import '../../models/gear_item.dart';
import 'create_rental_request_sheet.dart';
import 'widgets/favorite_toggle_button.dart';

/// Comprehensive Renter Discovery & Equipment Details Screen.
/// Provides renters with detailed gear specs, owner credentials, pricing breakdown,
/// real-time favorite bookmarking, and instant rental request submission.
class RenterEquipmentDetailsScreen extends StatefulWidget {
  final String equipmentId;
  final String name;
  final String category;
  final String image;
  final double dailyPrice;
  final double rating;
  final int reviewsCount;
  final String ownerName;
  final double distanceKm;
  final bool available;

  const RenterEquipmentDetailsScreen({
    super.key,
    required this.equipmentId,
    required this.name,
    required this.category,
    required this.image,
    required this.dailyPrice,
    this.rating = 4.9,
    this.reviewsCount = 28,
    this.ownerName = 'Marcus Vance',
    this.distanceKm = 1.4,
    this.available = true,
  });

  /// Factory constructor when navigating from [GearItem].
  factory RenterEquipmentDetailsScreen.fromGearItem(GearItem item) {
    final id = 'gear_${item.name.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
    return RenterEquipmentDetailsScreen(
      equipmentId: id,
      name: item.name,
      category: item.category,
      image: item.image,
      dailyPrice: item.pricePerDay.toDouble(),
      rating: item.rating,
      reviewsCount: item.reviews,
      ownerName: item.owner,
      distanceKm: item.distanceKm,
      available: item.available,
    );
  }

  @override
  State<RenterEquipmentDetailsScreen> createState() =>
      _RenterEquipmentDetailsScreenState();
}

class _RenterEquipmentDetailsScreenState
    extends State<RenterEquipmentDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.deepNavy;
    final subText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderCol = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image with Overlays
                Stack(
                  children: [
                    SizedBox(
                      height: 320,
                      width: double.infinity,
                      child: EquipmentImageViewer(
                        imageSource: widget.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Top App Bar buttons
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _circleButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          FavoriteToggleButton(
                            equipmentId: widget.equipmentId,
                            equipmentName: widget.name,
                            equipmentCategory: widget.category,
                            equipmentImage: widget.image,
                            dailyPrice: widget.dailyPrice,
                            rating: widget.rating,
                            reviewsCount: widget.reviewsCount,
                            available: widget.available,
                            backgroundColor: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    // Bottom Hero Chips
                    Positioned(
                      bottom: 16,
                      left: 20,
                      right: 20,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.available
                                  ? AppColors.success
                                  : AppColors.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.available ? 'AVAILABLE NOW' : 'RENTED',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  '${widget.distanceKm} km away',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Main Info Container
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Rating
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Ratings and Reviews
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 19, color: Color(0xFFFFB400)),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.rating}',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          Text(
                            ' (${widget.reviewsCount} verified renter reviews)',
                            style: TextStyle(fontSize: 13, color: subText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Owner Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderCol),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.deepNavy,
                              child: Text(
                                widget.ownerName.isNotEmpty
                                    ? widget.ownerName[0]
                                    : 'O',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.ownerName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'GearGo Host • Responds within 15 mins',
                                    style: TextStyle(fontSize: 12, color: subText),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Chat with ${widget.ownerName}'),
                                    backgroundColor: AppColors.deepNavy,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderCol),
                                ),
                                child: Text(
                                  'Contact',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Gear Features Highlights
                      Text(
                        'Equipment Highlights',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _highlightBadge(
                              Icons.verified_user_outlined,
                              'Verified Safe',
                              'Inspection passed',
                              cardBg,
                              borderCol,
                              textColor,
                              subText,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _highlightBadge(
                              Icons.cleaning_services_outlined,
                              'Sanitized',
                              'Freshly cleaned',
                              cardBg,
                              borderCol,
                              textColor,
                              subText,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _highlightBadge(
                              Icons.handshake_outlined,
                              'Free Pickup',
                              'Direct handover',
                              cardBg,
                              borderCol,
                              textColor,
                              subText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'About this Equipment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Professional-grade ${widget.name.toLowerCase()} in pristine operating condition. Regularly inspected, thoroughly maintained and tested prior to each booking. Includes standard protective case and accessories needed for immediate use.',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Rental Guidelines
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.shield_outlined,
                                    color: AppColors.primary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'GearGo Renter Protection',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Every booking on GearGo is backed by our complete damage protection guarantee and 24/7 renter support hotline.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: subText,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Bar with CTA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: cardBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Price / day',
                          style: TextStyle(fontSize: 12, color: subText),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '\$${widget.dailyPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'USD',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: subText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.available
                                ? AppColors.secondary
                                : const Color(0xFF94A3B8),
                            foregroundColor: Colors.white,
                            elevation: widget.available ? 4 : 0,
                            shadowColor:
                                AppColors.secondary.withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: widget.available
                              ? () {
                                  CreateRentalRequestSheet.show(
                                    context,
                                    equipmentId: widget.equipmentId,
                                    equipmentName: widget.name,
                                    equipmentCategory: widget.category,
                                    equipmentImage: widget.image,
                                    dailyPrice: widget.dailyPrice,
                                    ownerName: widget.ownerName,
                                  );
                                }
                              : null,
                          child: Text(
                            widget.available ? 'Request to Rent' : 'Currently Rented',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8),
        ],
      ),
      child: IconButton(
        iconSize: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        icon: Icon(icon, color: AppColors.deepNavy),
        onPressed: onTap,
      ),
    );
  }

  Widget _highlightBadge(
    IconData icon,
    String title,
    String subtitle,
    Color cardBg,
    Color borderCol,
    Color textColor,
    Color subText,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: subText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
