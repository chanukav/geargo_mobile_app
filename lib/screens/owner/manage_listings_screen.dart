import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/equipment.dart';
import '../../services/equipment_service.dart';
import 'add_edit_equipment_screen.dart';
import 'equipment_details_screen.dart';
import 'widgets/delete_confirmation_dialog.dart';
import 'widgets/equipment_card.dart';

enum ListingFilter {
  all,
  active,
  paused,
}

/// Manage Listings screen allowing equipment owners to view, filter, toggle,
/// edit, and delete their listed gear.
class ManageListingsScreen extends StatefulWidget {
  final String ownerId;
  final String ownerName;

  const ManageListingsScreen({
    super.key,
    required this.ownerId,
    this.ownerName = 'GearGo Owner',
  });

  @override
  State<ManageListingsScreen> createState() => _ManageListingsScreenState();
}

class _ManageListingsScreenState extends State<ManageListingsScreen> {
  final _service = EquipmentService();
  final _searchController = TextEditingController();

  ListingFilter _activeFilter = ListingFilter.all;
  String _selectedCategoryFilter = 'all';
  String _searchQuery = '';
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddEquipment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditEquipmentScreen(ownerId: widget.ownerId),
      ),
    );
  }

  void _navigateToEditEquipment(Equipment item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditEquipmentScreen(
          ownerId: widget.ownerId,
          equipment: item,
        ),
      ),
    );
  }

  void _navigateToDetails(Equipment item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EquipmentDetailsScreen(
          equipment: item,
          ownerName: widget.ownerName,
        ),
      ),
    );
  }

  Future<void> _handleDelete(Equipment item) async {
    final choice = await DeleteConfirmationDialog.show(context, item);
    if (choice == null || choice == DeleteActionChoice.cancel) return;

    if (choice == DeleteActionChoice.unpublish) {
      await _service.toggleAvailability(item.id, false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment listing paused/unpublished.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    if (choice == DeleteActionChoice.delete) {
      await _service.deleteEquipment(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment deleted successfully.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleToggleAvailability(Equipment item, bool value) async {
    try {
      await _service.toggleAvailability(item.id, value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? '"${item.name}" is now available for rent.'
                  : '"${item.name}" is now paused.',
            ),
            backgroundColor: value ? AppColors.success : AppColors.warning,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _seedSampleGear() async {
    setState(() => _isSeeding = true);
    try {
      await _service.seedStarterEquipment(widget.ownerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Starter gear catalog loaded!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  List<Equipment> _applyFilters(List<Equipment> list) {
    return list.where((item) {
      // 1. Availability Filter
      if (_activeFilter == ListingFilter.active && !item.availability) {
        return false;
      }
      if (_activeFilter == ListingFilter.paused && item.availability) {
        return false;
      }

      // 2. Category Filter
      if (_selectedCategoryFilter != 'all' &&
          item.categoryId != _selectedCategoryFilter) {
        return false;
      }

      // 3. Search query
      if (_searchQuery.isNotEmpty) {
        final matchesName = item.name.toLowerCase().contains(_searchQuery);
        final matchesCat = item.category.name.toLowerCase().contains(_searchQuery);
        final matchesDesc =
            item.description.toLowerCase().contains(_searchQuery);
        return matchesName || matchesCat || matchesDesc;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Manage Listings',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddEquipment,
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'Add Equipment',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      body: StreamBuilder<List<Equipment>>(
        stream: _service.getOwnerEquipmentStream(widget.ownerId),
        builder: (context, snapshot) {
          final allItems = snapshot.data ?? [];
          final activeCount =
              allItems.where((item) => item.availability).length;
          final pausedCount = allItems.length - activeCount;

          final filteredItems = _applyFilters(allItems);

          return Column(
            children: [
              // Search & Filter Header Container
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search equipment name or category...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondaryLight,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        fillColor: AppColors.backgroundLight,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter Tabs: All / Active / Paused
                    Row(
                      children: [
                        _buildFilterTab(
                          label: 'All (${allItems.length})',
                          filter: ListingFilter.all,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTab(
                          label: 'Active ($activeCount)',
                          filter: ListingFilter.active,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTab(
                          label: 'Paused ($pausedCount)',
                          filter: ListingFilter.paused,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Category Filter Pills Carousel
              Container(
                height: 44,
                color: AppColors.white,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryFilterChip('all', 'All Categories', null),
                    ...EquipmentCategory.allCategories.map(
                      (cat) => _buildCategoryFilterChip(
                        cat.id,
                        cat.name,
                        cat.icon,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),

              // Listings List View
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting &&
                        allItems.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.blue),
                      )
                    : filteredItems.isEmpty
                        ? _buildEmptyState(allItems.isEmpty)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return EquipmentCard(
                                equipment: item,
                                onTap: () => _navigateToDetails(item),
                                onEdit: () => _navigateToEditEquipment(item),
                                onDelete: () => _handleDelete(item),
                                onToggleAvailability: (val) =>
                                    _handleToggleAvailability(item, val),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required ListingFilter filter,
  }) {
    final isSelected = _activeFilter == filter;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeFilter = filter),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.blue.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.blue : AppColors.borderLight,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.blue : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChip(String id, String label, IconData? icon) {
    final isSelected = _selectedCategoryFilter == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 6),
      child: FilterChip(
        avatar: icon != null
            ? Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.deepNavy,
              )
            : null,
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategoryFilter = id),
        selectedColor: AppColors.deepNavy,
        backgroundColor: AppColors.backgroundLight,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.deepNavy,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.deepNavy : AppColors.borderLight,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildEmptyState(bool isCompletelyEmpty) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.orange,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCompletelyEmpty
                  ? 'No Equipment Listed Yet'
                  : 'No Matching Equipment Found',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCompletelyEmpty
                  ? 'Start earning by listing your outdoor gear, bikes, tents, and tools for rental.'
                  : 'Try clearing your search query or adjusting your filters.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _navigateToAddEquipment,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add New Equipment'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (isCompletelyEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isSeeding ? null : _seedSampleGear,
                icon: _isSeeding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Load Starter Equipment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.blue),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
