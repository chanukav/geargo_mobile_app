import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_user.dart';
import '../../models/equipment.dart';
import '../../services/equipment_service.dart';
import 'add_edit_equipment_screen.dart';
import 'equipment_details_screen.dart';
import 'manage_listings_screen.dart';
import 'widgets/equipment_card.dart';

/// Owner Dashboard screen - Central hub for equipment owners/lenders.
class OwnerDashboardScreen extends StatefulWidget {
  final User user;

  const OwnerDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final _service = EquipmentService();

  void _navigateToManageListings() {
    final appUser = AppUser.fromFirebase(widget.user);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManageListingsScreen(
          ownerId: widget.user.uid,
          ownerName: appUser.displayTitle,
        ),
      ),
    );
  }

  void _navigateToAddEquipment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditEquipmentScreen(ownerId: widget.user.uid),
      ),
    );
  }

  void _navigateToDetails(Equipment item) {
    final appUser = AppUser.fromFirebase(widget.user);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EquipmentDetailsScreen(
          equipment: item,
          ownerName: appUser.displayTitle,
        ),
      ),
    );
  }

  void _navigateToEditEquipment(Equipment item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditEquipmentScreen(
          ownerId: widget.user.uid,
          equipment: item,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appUser = AppUser.fromFirebase(widget.user);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Owner Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.deepNavy,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Equipment',
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.orange,
              size: 26,
            ),
            onPressed: _navigateToAddEquipment,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Equipment>>(
          stream: _service.getOwnerEquipmentStream(widget.user.uid),
          builder: (context, snapshot) {
            final equipmentList = snapshot.data ?? [];
            final totalCount = equipmentList.length;
            final activeCount =
                equipmentList.where((e) => e.availability).length;
            final pausedCount = totalCount - activeCount;
            final potentialDailyEarnings = equipmentList
                .where((e) => e.availability)
                .fold(0.0, (sum, item) => sum + item.price);

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              color: AppColors.blue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome & Owner Status Card
                    _buildOwnerBanner(appUser),
                    const SizedBox(height: 18),

                    // Metrics Grid (Total, Active, Paused, Potential Earning)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            title: 'Total Gear',
                            value: '$totalCount',
                            subtitle: 'Listed items',
                            icon: Icons.inventory_2_rounded,
                            iconColor: AppColors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            title: 'Active Gear',
                            value: '$activeCount',
                            subtitle: 'Available now',
                            icon: Icons.check_circle_rounded,
                            iconColor: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            title: 'Paused Gear',
                            value: '$pausedCount',
                            subtitle: 'Hidden from search',
                            icon: Icons.pause_circle_rounded,
                            iconColor: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            title: 'Daily Value',
                            value:
                                '\$${potentialDailyEarnings.toStringAsFixed(0)}',
                            subtitle: 'Active daily rate',
                            icon: Icons.attach_money_rounded,
                            iconColor: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Primary Action Hub
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Listing Management',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Control your inventory, adjust pricing, toggle availability, or add new items.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              // Manage Listings Button
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _navigateToManageListings,
                                  icon: const Icon(
                                    Icons.format_list_bulleted_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Manage Listings'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // + Add Equipment CTA (Orange)
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _navigateToAddEquipment,
                                  icon: const Icon(Icons.add_rounded, size: 20),
                                  label: const Text('+ Add Gear'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recent Listings Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Equipment Listings',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepNavy,
                          ),
                        ),
                        if (equipmentList.isNotEmpty)
                          TextButton(
                            onPressed: _navigateToManageListings,
                            child: const Row(
                              children: [
                                Text('See All'),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, size: 12),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Equipment List
                    if (equipmentList.isEmpty)
                      _buildEmptyPrompt()
                    else
                      ...equipmentList.take(3).map(
                            (item) => EquipmentCard(
                              equipment: item,
                              onTap: () => _navigateToDetails(item),
                              onEdit: () => _navigateToEditEquipment(item),
                              onDelete: () async {
                                await _service.deleteEquipment(item.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Equipment removed.'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                              onToggleAvailability: (val) async {
                                await _service.toggleAvailability(item.id, val);
                              },
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOwnerBanner(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepNavy.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.blue.withValues(alpha: 0.3),
            child: Text(
              user.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'GearGo Verified Lender',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE2E8F0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPrompt() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_shopping_cart_rounded,
              color: AppColors.orange,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ready to List Your First Equipment?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add bikes, kayaks, camping sets or tools to start receiving rental requests.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _navigateToAddEquipment,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Equipment Now'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
