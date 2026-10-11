import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/equipment.dart';
import '../../models/gear_item.dart';
import '../../services/equipment_service.dart';
import '../../services/review_service.dart';
import '../renter/renter_equipment_details_screen.dart';

/// Public Owner Profile Screen matching wireframe.
/// Displays owner stats, all listed equipment by that owner, and reviews received.
class PublicOwnerProfileScreen extends StatefulWidget {
  final String ownerId;
  final String ownerName;
  final bool ownerVerified;
  final String memberSince;
  final double rating;
  final int reviewsCount;
  final int totalRentals;
  final String responseRate;

  const PublicOwnerProfileScreen({
    super.key,
    required this.ownerId,
    this.ownerName = 'Marcus Vance',
    this.ownerVerified = true,
    this.memberSince = 'April 2021',
    this.rating = 4.9,
    this.reviewsCount = 42,
    this.totalRentals = 128,
    this.responseRate = '100%',
  });

  @override
  State<PublicOwnerProfileScreen> createState() =>
      _PublicOwnerProfileScreenState();
}

class _PublicOwnerProfileScreenState extends State<PublicOwnerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EquipmentService _equipmentService = EquipmentService();
  final ReviewService _reviewService = ReviewService();

  // Curated demo listings for Marcus Vance matching wireframe if live listings are fewer
  final List<GearItem> _marcusDemoListings = [
    const GearItem(
      name: 'Specialized Stumpjumper EVO Comp Bike',
      owner: 'Marcus Vance',
      category: 'Cycling',
      image: 'assets/images/gear_bike_red.jpg',
      rating: 4.8,
      reviews: 42,
      distanceKm: 1.2,
      pricePerDay: 45,
      available: true,
      verified: true,
      listingId: 'gear_specialized_stumpjumper',
      ownerId: 'owner_default',
      description:
          'Mechanically perfect, freshly tuned, cleaned after every rental.',
    ),
    const GearItem(
      name: 'Giro Manifest Spheric Helmet',
      owner: 'Marcus Vance',
      category: 'Cycling',
      image: 'assets/images/gear_bike_black.jpg',
      rating: 4.9,
      reviews: 18,
      distanceKm: 1.2,
      pricePerDay: 8,
      available: true,
      verified: true,
      listingId: 'gear_giro_manifest',
      ownerId: 'owner_default',
      description: 'MIPS Spheric technology trail helmet, size Medium.',
    ),
    const GearItem(
      name: 'The North Face Wawona Tent',
      owner: 'Marcus Vance',
      category: 'Camping',
      image: 'assets/images/gear_backpack.jpg',
      rating: 4.7,
      reviews: 26,
      distanceKm: 1.5,
      pricePerDay: 28,
      available: true,
      verified: true,
      listingId: 'gear_north_face_tent',
      ownerId: 'owner_default',
      description: 'Spacious 6-person car camping tent with massive vestibule.',
    ),
    const GearItem(
      name: 'Babolat Pure Drive Tennis Racket',
      owner: 'Marcus Vance',
      category: 'Badminton',
      image: 'assets/images/gear_badminton_set.jpg',
      rating: 4.6,
      reviews: 14,
      distanceKm: 1.8,
      pricePerDay: 15,
      available: true,
      verified: true,
      listingId: 'gear_babolat_pure_drive',
      ownerId: 'owner_default',
      description: 'High power and spin tennis racket with fresh strings.',
    ),
    const GearItem(
      name: 'Black Diamond Trekking Poles',
      owner: 'Marcus Vance',
      category: 'Hiking',
      image: 'assets/images/gear_cones.jpg',
      rating: 4.8,
      reviews: 22,
      distanceKm: 1.2,
      pricePerDay: 12,
      available: true,
      verified: true,
      listingId: 'gear_trekking_poles',
      ownerId: 'owner_default',
      description: 'Adjustable carbon fiber hiking poles with shock absorption.',
    ),
    const GearItem(
      name: 'Specialized Rockhopper Comp',
      owner: 'Marcus Vance',
      category: 'Cycling',
      image: 'assets/images/gear_bike_yellow.jpg',
      rating: 4.9,
      reviews: 38,
      distanceKm: 1.5,
      pricePerDay: 32,
      available: true,
      verified: true,
      listingId: 'gear_specialized_rockhopper_comp',
      ownerId: 'owner_default',
      description: 'Lightweight aluminum hardtail mountain bike with hydraulic disc brakes.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121417) : const Color(0xFFF9FAFB);
    final cardBg = isDark ? const Color(0xFF1E2228) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.grey[400]! : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF2D333D) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Owner Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: textColor),
            onSelected: (val) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$val option selected'),
                  backgroundColor: AppColors.deepNavy,
                ),
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Share', child: Text('Share Profile')),
              const PopupMenuItem(value: 'Report', child: Text('Report Host')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Equipment>>(
        stream: _equipmentService.getOwnerEquipmentStream(widget.ownerId),
        builder: (context, equipSnapshot) {
          final liveListings = equipSnapshot.data ?? [];
          final displayedListings = _mergeEquipmentListings(liveListings);
          final listingsCount = displayedListings.length;

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _reviewService.reviewsForOwner(
              widget.ownerId,
              ownerName: widget.ownerName,
            ),
            builder: (context, reviewSnapshot) {
              final reviews = reviewSnapshot.data ?? [];
              final reviewsCount = reviews.isNotEmpty
                  ? reviews.length
                  : widget.reviewsCount;

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Container(
                      color: cardBg,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        children: [
                          // Large Avatar
                          _buildProfileAvatar(borderColor),
                          const SizedBox(height: 12),

                          // Owner Name + Verified Icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.ownerName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (widget.ownerVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Member Since
                          Text(
                            'Member since ${widget.memberSince}',
                            style: TextStyle(
                              fontSize: 13,
                              color: subColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Rating Pill Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2B2516)
                                  : const Color(0xFFFFF9E6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFFB400).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: Color(0xFFFFB400),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.rating} ($reviewsCount)',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 3 Stats Cards
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF171A20)
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildStatColumn(
                                    '$listingsCount',
                                    'Items Listed',
                                    textColor,
                                    subColor,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: borderColor,
                                ),
                                Expanded(
                                  child: _buildStatColumn(
                                    '${widget.totalRentals}',
                                    'Total Rentals',
                                    textColor,
                                    subColor,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: borderColor,
                                ),
                                Expanded(
                                  child: _buildStatColumn(
                                    widget.responseRate,
                                    'Response Rate',
                                    textColor,
                                    subColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab Bar
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: textColor,
                        indicatorWeight: 2.5,
                        labelColor: textColor,
                        unselectedLabelColor: subColor,
                        labelStyle: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: [
                          Tab(text: 'Listings ($listingsCount)'),
                          Tab(text: 'Reviews ($reviewsCount)'),
                        ],
                      ),
                      cardBg,
                      borderColor,
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Listings (2-column Grid)
                    _buildListingsTab(
                      displayedListings,
                      cardBg,
                      textColor,
                      subColor,
                      borderColor,
                    ),

                    // Tab 2: Reviews List
                    _buildReviewsTab(
                      reviews,
                      cardBg,
                      textColor,
                      subColor,
                      borderColor,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(cardBg, borderColor, subColor),
    );
  }

  Widget _buildProfileAvatar(Color borderColor) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Center(
        child: Text(
          widget.ownerName.isNotEmpty ? widget.ownerName[0] : 'M',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(
      String value, String label, Color textColor, Color subColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: subColor,
          ),
        ),
      ],
    );
  }

  List<GearItem> _mergeEquipmentListings(List<Equipment> live) {
    final results = <GearItem>[];
    for (final eq in live) {
      results.add(GearItem(
        name: eq.name,
        owner: widget.ownerName,
        category: eq.category.name,
        image: eq.image,
        rating: eq.rating,
        reviews: eq.reviewsCount,
        distanceKm: 1.2,
        pricePerDay: eq.price.round(),
        available: eq.availability,
        verified: widget.ownerVerified,
        listingId: eq.id,
        ownerId: widget.ownerId,
        description: eq.description,
      ));
    }

    // Merge demo listings for Marcus Vance or if list is empty
    for (final demo in _marcusDemoListings) {
      final exists = results.any(
        (r) => r.name.toLowerCase() == demo.name.toLowerCase(),
      );
      if (!exists) {
        results.add(demo);
      }
    }
    return results;
  }

  Widget _buildListingsTab(
    List<GearItem> listings,
    Color cardBg,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    if (listings.isEmpty) {
      return Center(
        child: Text(
          'No equipment listings yet.',
          style: TextStyle(color: subColor, fontSize: 14),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: listings.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.76,
      ),
      itemBuilder: (context, index) {
        final item = listings[index];
        return _buildEquipmentCard(
          item,
          cardBg,
          textColor,
          subColor,
          borderColor,
        );
      },
    );
  }

  Widget _buildEquipmentCard(
    GearItem item,
    Color cardBg,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RenterEquipmentDetailsScreen.fromGearItem(item),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with placeholder cross or image
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFE5E7EB),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _CrossPlaceholderPainter(),
                    ),
                    if (item.image.isNotEmpty &&
                        !item.image.startsWith('assets/'))
                      Image.network(
                        item.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ),

            // Item Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${item.pricePerDay} / day',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: Color(0xFFFFB400),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${item.rating}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textColor,
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
    );
  }

  Widget _buildReviewsTab(
    List<Map<String, dynamic>> reviews,
    Color cardBg,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    if (reviews.isEmpty) {
      return Center(
        child: Text(
          'No reviews yet for this host.',
          style: TextStyle(color: subColor, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = reviews[index];
        final author = r['author_name']?.toString() ?? 'Renter';
        final rating = (r['rating'] as num?)?.toInt() ?? 5;
        final comment = r['comment']?.toString() ?? '';
        final equipName = r['equipment_name']?.toString() ?? '';
        final dateStr = _formatDate(r['created_at']);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE5E7EB),
                    child: Text(
                      author.isNotEmpty ? author[0] : 'R',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              return Icon(
                                i < rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 14,
                                color: const Color(0xFFFFB400),
                              );
                            }),
                            if (dateStr.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: subColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (equipName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    equipName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                comment,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    DateTime? dt;
    if (raw is Timestamp) dt = raw.toDate();
    if (raw is DateTime) dt = raw;
    dt ??= DateTime.tryParse(raw.toString());
    if (dt == null) return '';
    return DateFormat('MMM d, yyyy').format(dt);
  }

  Widget _buildBottomNav(Color cardBg, Color borderColor, Color subColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', false, subColor),
              _buildNavItem(Icons.search_rounded, 'Search', false, subColor),
              _buildNavItem(Icons.add_circle_outline_rounded, 'List', false, subColor),
              _buildNavItem(Icons.chat_bubble_outline_rounded, 'Messages', false, subColor),
              _buildNavItem(Icons.person_rounded, 'Profile', true, AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isActive, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color bgColor;
  final Color borderColor;

  _SliverTabBarDelegate(this.tabBar, this.bgColor, this.borderColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

class _CrossPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
