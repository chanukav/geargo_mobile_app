import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/image_helper.dart';
import '../../models/gear_item.dart';
import '../../services/gear_catalog_service.dart';
import '../renter/renter_equipment_details_screen.dart';
import 'filter_screen.dart';

/// Screen 2 & Screen 4: Search Results Screen
/// Displays equipment matching search term, location/distance, sport category,
/// and availability filters with live filtering and sorting.
class SportSearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  final GearFilters initialFilters;

  const SportSearchResultsScreen({
    super.key,
    this.initialQuery = '',
    this.initialFilters = const GearFilters(),
  });

  @override
  State<SportSearchResultsScreen> createState() =>
      _SportSearchResultsScreenState();
}

class _SportSearchResultsScreenState extends State<SportSearchResultsScreen> {
  late String _query;
  late GearFilters _filters;
  String _sortBy = 'distance'; // 'distance', 'price_asc', 'price_desc', 'rating'
  List<GearItem> _catalog = sampleGear;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _filters = widget.initialFilters;

    GearCatalogService().discoveryStream().listen((items) {
      if (mounted) {
        setState(() => _catalog = items);
      }
    });
  }

  List<GearItem> get _filteredResults {
    final q = _query.trim().toLowerCase();

    var list = _catalog.where((item) {
      // 1. Text Query match
      final matchQuery = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);

      // 2. Sport / Category filter
      final matchCategory = _filters.categories.isEmpty ||
          _filters.categories.any(
            (c) => item.category.toLowerCase() == c.toLowerCase(),
          );

      // 3. Distance filter
      final matchDistance = item.distanceKm <= _filters.distanceKm;

      // 4. Availability filter
      final matchAvailability = !_filters.availableNow || item.available;

      return matchQuery && matchCategory && matchDistance && matchAvailability;
    }).toList();

    // Sorting
    switch (_sortBy) {
      case 'price_asc':
        list.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
        break;
      case 'price_desc':
        list.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
        break;
      case 'rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'distance':
      default:
        list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
    }

    return list;
  }

  Future<void> _openFilters() async {
    final updatedFilters = await Navigator.of(context).push<GearFilters>(
      MaterialPageRoute(
        builder: (_) => FilterScreen(
          initial: _filters,
          catalog: _catalog,
          searchQuery: _query,
        ),
      ),
    );

    if (updatedFilters != null) {
      setState(() {
        _filters = updatedFilters;
      });
    }
  }

  void _showSortSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textPrimaryDark : AppColors.deepNavy;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Sort Equipment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _sortOption(
                  label: 'Nearest Distance (Default)',
                  value: 'distance',
                ),
                _sortOption(
                  label: 'Price: Low to High',
                  value: 'price_asc',
                ),
                _sortOption(
                  label: 'Price: High to Low',
                  value: 'price_desc',
                ),
                _sortOption(
                  label: 'Top Customer Rating',
                  value: 'rating',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sortOption({required String label, required String value}) {
    final isSelected = _sortBy == value;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.of(context).pop();
      },
    );
  }

  void _showEditLocationDialog() {
    final locations = [
      'Current Location',
      'Kuala Lumpur',
      'Petaling Jaya',
      'Bangsar',
      'Mont Kiara',
      'Subang Jaya',
    ];
    final distances = [1.0, 5.0, 10.0, 20.0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final titleColor =
                isDark ? AppColors.textPrimaryDark : AppColors.deepNavy;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Location & Distance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: locations.map((loc) {
                        final isSel = _filters.location == loc;
                        return ChoiceChip(
                          label: Text(loc),
                          selected: isSel,
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSel ? AppColors.primary : null,
                            fontWeight: isSel ? FontWeight.bold : null,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() {
                                _filters = _filters.copyWith(location: loc);
                              });
                              setState(() {});
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Search Radius',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: distances.map((km) {
                        final isSel = _filters.distanceKm == km;
                        return ChoiceChip(
                          label: Text('Within ${km.round()} km'),
                          selected: isSel,
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSel ? AppColors.primary : null,
                            fontWeight: isSel ? FontWeight.bold : null,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() {
                                _filters = _filters.copyWith(distanceKm: km);
                              });
                              setState(() {});
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Save & Update'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEquipmentCard(GearItem item, bool isDark) {
    final titleColor = isDark ? AppColors.textPrimaryDark : AppColors.deepNavy;
    final subColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Equipment thumbnail
          EquipmentImageViewer(
            imageSource: item.image,
            width: 86,
            height: 86,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
            fallbackIcon: Icons.sports_soccer_rounded,
          ),
          const SizedBox(width: 12),

          // Middle: Title, Category, Distance
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: subColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${item.distanceKm} km',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right: Price, Availability Badge, View Details Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM ${item.pricePerDay} / day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),

              // Availability status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: item.available
                      ? const Color(0xFFE6F7ED)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.available ? 'Available Now' : 'Unavailable',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: item.available
                        ? const Color(0xFF10B981)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // View Details CTA
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            RenterEquipmentDetailsScreen.fromGearItem(item),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textPrimaryDark : AppColors.deepNavy;
    final subColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;

    final results = _filteredResults;
    final sportName = _filters.categories.isNotEmpty
        ? _filters.categories.first
        : (_query.isNotEmpty ? _query : 'Equipment');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: titleColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Search Results',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Location Info Card Banner
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$sportName equipment near you',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Within ${_filters.distanceKm.round()} km • ${_filters.location}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: subColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _showEditLocationDialog,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Filter & Sort Action Row matching wireframe
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Filter Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openFilters,
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.tune_rounded, size: 18),
                              if (_filters.hasActiveFilters)
                                Positioned(
                                  top: -2,
                                  right: -4,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          label: Text(
                            'Filter${_filters.categories.isNotEmpty ? " (${_filters.categories.length})" : ""}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            foregroundColor: titleColor,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Sort Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showSortSheet,
                          icon: const Icon(Icons.swap_vert_rounded, size: 20),
                          label: Text(
                            'Sort',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            foregroundColor: titleColor,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Active Filters Chips (if any)
                if (_filters.categories.isNotEmpty || _filters.availableNow)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._filters.categories.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(cat,
                                    style: const TextStyle(fontSize: 11)),
                                deleteIcon: const Icon(Icons.close_rounded,
                                    size: 14),
                                onDeleted: () {
                                  setState(() {
                                    final newCats = {..._filters.categories}
                                      ..remove(cat);
                                    _filters =
                                        _filters.copyWith(categories: newCats);
                                  });
                                },
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }),
                          if (_filters.availableNow)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: const Text('Available Now',
                                    style: TextStyle(fontSize: 11)),
                                deleteIcon: const Icon(Icons.close_rounded,
                                    size: 14),
                                onDeleted: () {
                                  setState(() {
                                    _filters =
                                        _filters.copyWith(availableNow: false);
                                  });
                                },
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Results Counter
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text(
                    '${results.length} results found',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: subColor,
                    ),
                  ),
                ),

                // Equipment List
                Expanded(
                  child: results.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: subColor,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No equipment found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Try adjusting your search radius or clearing filters.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _filters = const GearFilters(
                                        categories: {},
                                        distanceKm: 50,
                                        availableNow: false,
                                      );
                                      _query = '';
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Clear All Filters'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            return _buildEquipmentCard(
                              results[index],
                              isDark,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
