import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_helper.dart';
import '../../models/equipment.dart';
import '../../services/equipment_service.dart';
import '../../widgets/equipment_reviews_section.dart';
import 'add_edit_equipment_screen.dart';
import 'widgets/delete_confirmation_dialog.dart';

/// Screen displaying complete details for a single equipment listing.
/// Supports viewing, editing, unpublishing, and deleting.
class EquipmentDetailsScreen extends StatefulWidget {
  final Equipment equipment;
  final String ownerName;

  const EquipmentDetailsScreen({
    super.key,
    required this.equipment,
    this.ownerName = 'GearGo Owner',
  });

  @override
  State<EquipmentDetailsScreen> createState() => _EquipmentDetailsScreenState();
}

class _EquipmentDetailsScreenState extends State<EquipmentDetailsScreen> {
  late Equipment _equipment;
  final _service = EquipmentService();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _equipment = widget.equipment;
  }

  Future<void> _handleEdit() async {
    final updated = await Navigator.of(context).push<Equipment>(
      MaterialPageRoute(
        builder: (context) => AddEditEquipmentScreen(
          ownerId: _equipment.ownerId,
          equipment: _equipment,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _equipment = updated;
      });
    }
  }

  Future<void> _handleToggleAvailability() async {
    final newAvailability = !_equipment.availability;
    setState(() => _isUpdating = true);

    try {
      await _service.toggleAvailability(_equipment.id, newAvailability);
      setState(() {
        _equipment = _equipment.copyWith(
          availability: newAvailability,
          updatedAt: DateTime.now(),
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newAvailability
                  ? 'Equipment listing is now ACTIVE and available for rent.'
                  : 'Equipment listing is now PAUSED.',
            ),
            backgroundColor:
                newAvailability ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating availability: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    final choice = await DeleteConfirmationDialog.show(context, _equipment);

    if (choice == null || choice == DeleteActionChoice.cancel) return;

    if (choice == DeleteActionChoice.unpublish) {
      await _handleToggleAvailability();
      return;
    }

    if (choice == DeleteActionChoice.delete) {
      setState(() => _isUpdating = true);
      try {
        await _service.deleteEquipment(_equipment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Equipment listing removed successfully.'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.of(context).pop(true); // Return deleted signal
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing equipment: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUpdating = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = _equipment.category;
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Hero Image Header matching GearGo Screenshot
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: AppColors.deepNavy,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.deepNavy,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          tooltip: 'Share listing',
                          icon: const Icon(
                            Icons.share_outlined,
                            size: 20,
                            color: AppColors.deepNavy,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Listing link copied: geargo.app/equipment/${_equipment.id}',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(4, 8, 12, 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          tooltip: 'Edit listing',
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: AppColors.blue,
                          ),
                          onPressed: _handleEdit,
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: EquipmentImageViewer(
                        imageSource: _equipment.image,
                        fallbackIcon: category.icon,
                      ),
                    ),
                  ),

                  // Equipment Details Body
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Category badge and Price row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Category badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: category.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      category.icon,
                                      size: 14,
                                      color: category.color,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      category.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: category.color,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Price Tag
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '\$${_equipment.price.toStringAsFixed(_equipment.price.truncateToDouble() == _equipment.price ? 0 : 2)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.deepNavy,
                                    ),
                                  ),
                                  const Text(
                                    ' /day',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondaryLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Equipment Title
                          Text(
                            _equipment.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.deepNavy,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Location and Rating
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _equipment.location,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Color(0xFFFBBF24),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${_equipment.rating} (${_equipment.reviewsCount} reviews)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Availability Status Banner
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _equipment.availability
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _equipment.availability
                                    ? AppColors.success.withValues(alpha: 0.3)
                                    : AppColors.warning.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _equipment.availability
                                      ? Icons.check_circle_rounded
                                      : Icons.pause_circle_rounded,
                                  color: _equipment.availability
                                      ? AppColors.success
                                      : AppColors.warning,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _equipment.availability
                                            ? 'Listing is Active'
                                            : 'Listing is Paused',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _equipment.availability
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                      ),
                                      Text(
                                        _equipment.availability
                                            ? 'Visible to renters searching nearby.'
                                            : 'Hidden from search and new rental requests.',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isUpdating
                                      ? null
                                      : _handleToggleAvailability,
                                  child: Text(
                                    _equipment.availability
                                        ? 'Pause'
                                        : 'Activate',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _equipment.availability
                                          ? AppColors.warning
                                          : AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Owner / Host Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      AppColors.blue.withValues(alpha: 0.15),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.ownerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.deepNavy,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Equipment Owner • Verified Host',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'OWNER',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Equipment Condition Pill Badge
                          Row(
                            children: [
                              const Text(
                                'Equipment Condition',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _equipment.condition.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.success,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Description Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.deepNavy,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _equipment.description.isNotEmpty
                                      ? _equipment.description
                                      : 'No description provided.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Renter reviews',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          EquipmentReviewsSection(
                            equipmentId: _equipment.id,
                            textColor: AppColors.deepNavy,
                            subColor: AppColors.textSecondaryLight,
                            cardBg: AppColors.white,
                            borderColor: AppColors.borderLight,
                          ),
                          const SizedBox(height: 16),

                          // Database & Metadata Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Listing Information',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.deepNavy,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildMetaRow('Listing ID', _equipment.id),
                                _buildMetaRow(
                                  'Category ID',
                                  _equipment.categoryId,
                                ),
                                _buildMetaRow(
                                  'Created At',
                                  dateFormat.format(_equipment.createdAt),
                                ),
                                _buildMetaRow(
                                  'Last Updated',
                                  dateFormat.format(_equipment.updatedAt),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Action Bar for Owner
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: const Border(
                  top: BorderSide(color: AppColors.borderLight),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Delete Button
                  IconButton.outlined(
                    tooltip: 'Delete listing',
                    onPressed: _isUpdating ? null : _handleDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                    style: IconButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Toggle availability quick button
                  Expanded(
                    flex: 4,
                    child: OutlinedButton.icon(
                      onPressed: _isUpdating ? null : _handleToggleAvailability,
                      icon: Icon(
                        _equipment.availability
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _equipment.availability ? 'Pause' : 'Activate',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _equipment.availability
                            ? AppColors.textSecondaryLight
                            : AppColors.success,
                        side: BorderSide(
                          color: _equipment.availability
                              ? AppColors.borderLight
                              : AppColors.success,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Edit Listing (Primary Blue or Orange CTA)
                  Expanded(
                    flex: 5,
                    child: FilledButton.icon(
                      onPressed: _isUpdating ? null : _handleEdit,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit Listing'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.deepNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
