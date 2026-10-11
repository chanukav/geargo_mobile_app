import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/gear_item.dart';
import 'gear_filter_logic.dart';

/// Filter values chosen by the user on the [FilterScreen].
class GearFilters {
  static const double maxDistance = 50;
  static const double maxPrice = 150;

  final double distanceKm;
  final Set<String> categories;
  final RangeValues price;
  final bool availableNow;
  final bool availableOnDate;
  final DateTime? selectedDate;
  final String location;

  const GearFilters({
    this.distanceKm = 5.0,
    this.categories = const {'Football'},
    this.price = const RangeValues(0, maxPrice),
    this.availableNow = true,
    this.availableOnDate = false,
    this.selectedDate,
    this.location = 'Current Location',
  });

  /// True when price max is at the "$150+" end (no upper limit).
  bool get priceUnbounded => price.end >= maxPrice;

  bool get hasActiveFilters =>
      categories.isNotEmpty ||
      distanceKm != 50 ||
      availableNow ||
      availableOnDate;

  GearFilters copyWith({
    double? distanceKm,
    Set<String>? categories,
    RangeValues? price,
    bool? availableNow,
    bool? availableOnDate,
    DateTime? selectedDate,
    String? location,
  }) {
    return GearFilters(
      distanceKm: distanceKm ?? this.distanceKm,
      categories: categories ?? this.categories,
      price: price ?? this.price,
      availableNow: availableNow ?? this.availableNow,
      availableOnDate: availableOnDate ?? this.availableOnDate,
      selectedDate: selectedDate ?? this.selectedDate,
      location: location ?? this.location,
    );
  }
}

const List<String> filterCategories = [
  'Cricket',
  'Football',
  'Badminton',
  'Cycling',
  'Gym',
  'Other',
];

const List<double> distanceOptions = [1.0, 5.0, 10.0, 20.0];

/// Filter Equipment screen matching Wireframe 3:
/// - Sport / Activity multi-select checkboxes
/// - Location / Distance radio options (1km, 5km, 10km, 20km)
/// - Availability (Available Now / Available on Selected Date with calendar picker)
/// - Apply Filters & Clear All buttons
class FilterScreen extends StatefulWidget {
  final GearFilters initial;
  final List<GearItem> catalog;
  final String searchQuery;

  const FilterScreen({
    super.key,
    required this.initial,
    this.catalog = const [],
    this.searchQuery = '',
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late double _distance;
  late Set<String> _cats;
  late bool _availableNow;
  late bool _availableOnDate;
  DateTime? _selectedDate;
  late String _location;

  @override
  void initState() {
    super.initState();
    _distance = widget.initial.distanceKm;
    _cats = {...widget.initial.categories};
    _availableNow = widget.initial.availableNow;
    _availableOnDate = widget.initial.availableOnDate;
    _selectedDate = widget.initial.selectedDate;
    _location = widget.initial.location;
  }

  void _clearAll() {
    setState(() {
      _distance = 20.0;
      _cats = {};
      _availableNow = false;
      _availableOnDate = false;
      _selectedDate = null;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      GearFilters(
        distanceKm: _distance,
        categories: _cats,
        availableNow: _availableNow,
        availableOnDate: _availableOnDate,
        selectedDate: _selectedDate,
        location: _location,
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _availableOnDate = true;
        _availableNow = false;
      });
    }
  }

  int get _resultCount => countFilteredGear(
        catalog: widget.catalog,
        filters: GearFilters(
          distanceKm: _distance,
          categories: _cats,
          availableNow: _availableNow,
          availableOnDate: _availableOnDate,
          selectedDate: _selectedDate,
          location: _location,
        ),
        query: widget.searchQuery,
      );

  Widget _buildSectionHeader(String title, Color titleColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: titleColor,
        ),
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
          'Filter Equipment',
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
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      // Section 1: Sport / Activity (Checkboxes)
                      _buildSectionHeader('Sport / Activity', titleColor),
                      ...filterCategories.map((category) {
                        final isChecked = _cats.contains(category);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isChecked) {
                                _cats.remove(category);
                              } else {
                                _cats.add(category);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: isChecked,
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    side: BorderSide(
                                      color: isChecked
                                          ? AppColors.primary
                                          : borderColor,
                                      width: 1.5,
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _cats.add(category);
                                        } else {
                                          _cats.remove(category);
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                    fontWeight: isChecked
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),
                      Divider(color: borderColor, height: 1),
                      const SizedBox(height: 20),

                      // Section 2: Location / Distance (Radio Options)
                      _buildSectionHeader('Location / Distance', titleColor),
                      ...distanceOptions.map((km) {
                        final isSelected = _distance == km;
                        return InkWell(
                          onTap: () {
                            setState(() => _distance = km);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Radio<double>(
                                    value: km,
                                    groupValue: _distance,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _distance = val);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Within ${km.round()} km',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),
                      Divider(color: borderColor, height: 1),
                      const SizedBox(height: 20),

                      // Section 3: Availability (Radio & Date Picker)
                      _buildSectionHeader('Availability', titleColor),

                      // Option A: Available Now
                      InkWell(
                        onTap: () {
                          setState(() {
                            _availableNow = true;
                            _availableOnDate = false;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Radio<bool>(
                                  value: true,
                                  groupValue: _availableNow,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    if (val == true) {
                                      setState(() {
                                        _availableNow = true;
                                        _availableOnDate = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Available Now',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                  fontWeight: _availableNow
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Option B: Available on Selected Date
                      InkWell(
                        onTap: () {
                          setState(() {
                            _availableOnDate = true;
                            _availableNow = false;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Radio<bool>(
                                  value: true,
                                  groupValue: _availableOnDate,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    if (val == true) {
                                      setState(() {
                                        _availableOnDate = true;
                                        _availableNow = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Available on Selected Date',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                  fontWeight: _availableOnDate
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Date selector box
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _availableOnDate
                                  ? AppColors.primary
                                  : borderColor,
                              width: _availableOnDate ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                                color: _availableOnDate
                                    ? AppColors.primary
                                    : subColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDate != null
                                      ? DateFormat('dd MMM yyyy')
                                          .format(_selectedDate!)
                                      : 'Select Date',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: _selectedDate != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: _selectedDate != null
                                        ? titleColor
                                        : subColor,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: subColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Action Buttons matching wireframe
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Apply Filters
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _apply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepNavy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Apply Filters ($_resultCount)',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Clear All
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _clearAll,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
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
        ),
      ),
    );
  }
}
