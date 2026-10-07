import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_helper.dart';
import '../../models/rental_request.dart';
import '../../services/rental_request_service.dart';
import 'edit_rental_request_dialog.dart';
import 'rental_request_details_screen.dart';

/// Screen listing all rental requests submitted by the current renter (CRUD 01 - Read / Filter / Manage).
/// Integrated as the main "Bookings" tab in GearGo shell.
class RentalRequestsListScreen extends StatefulWidget {
  final VoidCallback? onExploreTap;

  const RentalRequestsListScreen({super.key, this.onExploreTap});

  @override
  State<RentalRequestsListScreen> createState() =>
      _RentalRequestsListScreenState();
}

class _RentalRequestsListScreenState extends State<RentalRequestsListScreen> {
  final _service = RentalRequestService();
  final _searchController = TextEditingController();

  RentalStatus? _selectedStatusFilter; // null = All
  String _searchQuery = '';

  String get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid ?? 'guest_renter';
  }

  @override
  void initState() {
    super.initState();
    _seedIfNeeded();
  }

  Future<void> _seedIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    await _service.seedStarterRequests(
      renterId: _currentUserId,
      renterName: user?.displayName ?? 'Renter Explorer',
      renterEmail: user?.email ?? 'renter@geargo.com',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.deepNavy;
    final subText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final borderCol = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top App Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Bookings',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Manage your rental requests and reservations',
                              style: TextStyle(fontSize: 13, color: subText),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_outlined,
                                  size: 15, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Renter',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search within Bookings
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderCol),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                        style: TextStyle(fontSize: 14.5, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Search gear or owner...',
                          hintStyle: TextStyle(fontSize: 13.5, color: subText),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Status Filter Tabs
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _filterChip('All', null, textColor, borderCol),
                          _filterChip('Pending', RentalStatus.pending, textColor, borderCol),
                          _filterChip('Approved', RentalStatus.approved, textColor, borderCol),
                          _filterChip('Active', RentalStatus.active, textColor, borderCol),
                          _filterChip('Completed', RentalStatus.completed, textColor, borderCol),
                          _filterChip('Cancelled', RentalStatus.cancelled, textColor, borderCol),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
          body: StreamBuilder<List<RentalRequest>>(
            stream: _service.getRenterRequestsStream(_currentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final all = snapshot.data ?? [];
              final filtered = all.where((r) {
                final matchesStatus = _selectedStatusFilter == null ||
                    r.status == _selectedStatusFilter;
                final matchesQuery = _searchQuery.isEmpty ||
                    r.equipmentName.toLowerCase().contains(_searchQuery) ||
                    r.ownerName.toLowerCase().contains(_searchQuery) ||
                    r.equipmentCategory.toLowerCase().contains(_searchQuery);
                return matchesStatus && matchesQuery;
              }).toList();

              if (filtered.isEmpty) {
                return _buildEmptyState(textColor, subText);
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _RentalRequestCard(
                    request: filtered[index],
                    cardBg: cardBg,
                    borderCol: borderCol,
                    textColor: textColor,
                    subText: subText,
                    isDark: isDark,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _filterChip(
    String label,
    RentalStatus? status,
    Color textColor,
    Color borderCol,
  ) {
    final selected = _selectedStatusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatusFilter = status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceDark
                    : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : borderCol,
              width: selected ? 1.4 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? Colors.white : textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subText) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 46,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching bookings found'
                  : (_selectedStatusFilter != null
                      ? 'No ${_selectedStatusFilter!.name} requests'
                      : 'No rental requests yet'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching with a different term or clear filters.'
                  : 'Rent gear from local owners in your area and track your bookings here.',
              style: TextStyle(fontSize: 13.5, color: subText, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (widget.onExploreTap != null)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: widget.onExploreTap,
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: const Text(
                  'Explore Equipment',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RentalRequestCard extends StatelessWidget {
  final RentalRequest request;
  final Color cardBg;
  final Color borderCol;
  final Color textColor;
  final Color subText;
  final bool isDark;

  const _RentalRequestCard({
    required this.request,
    required this.cardBg,
    required this.borderCol,
    required this.textColor,
    required this.subText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RentalRequestDetailsScreen(request: request),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        request.equipmentCategory.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    _statusBadge(request.status),
                  ],
                ),
                const SizedBox(height: 12),

                // Main Info Row: Image + Name + Owner
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: EquipmentImageViewer(
                          imageSource: request.equipmentImage,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.equipmentName,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Owner: ${request.ownerName}',
                            style: TextStyle(fontSize: 12.5, color: subText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                request.isDelivery
                                    ? Icons.local_shipping_outlined
                                    : Icons.storefront_outlined,
                                size: 14,
                                color: subText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                request.isDelivery ? 'Delivery' : 'Pickup',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: subText,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: subText,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${request.totalDays}d duration',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: subText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Bottom Row: Date range & Total Price + Details Button
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.shortDateRange,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'Total: ',
                                style: TextStyle(fontSize: 12, color: subText),
                              ),
                              Text(
                                '\$${request.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (request.canEdit)
                      IconButton(
                        icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                        color: AppColors.primary,
                        tooltip: 'Edit Dates',
                        onPressed: () => EditRentalRequestDialog.show(context, request),
                      ),
                    const SizedBox(width: 4),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        foregroundColor: textColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: borderCol),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                RentalRequestDetailsScreen(request: request),
                          ),
                        );
                      },
                      child: const Row(
                        children: [
                          Text(
                            'Manage',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(RentalStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}
