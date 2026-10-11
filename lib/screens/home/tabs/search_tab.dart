import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../filter_screen.dart';
import '../sport_search_results_screen.dart';

/// Screen 1: Home / Search Screen for SportShare / GearGo
/// Allows users to enter search keywords, select their location,
/// browse by sport category, and navigate to Search Results.
class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedLocation = 'Current Location';
  String? _selectedSport = 'Football';

  final List<(String, IconData)> _sportCategories = const [
    ('Cricket', Icons.sports_cricket_rounded),
    ('Football', Icons.sports_soccer_rounded),
    ('Badminton', Icons.sports_tennis_rounded),
    ('Cycling', Icons.directions_bike_rounded),
    ('Gym', Icons.fitness_center_rounded),
    ('More', Icons.more_horiz_rounded),
  ];

  final List<String> _locationOptions = const [
    'Current Location',
    'Kuala Lumpur',
    'Petaling Jaya',
    'Bangsar',
    'Mont Kiara',
    'Subang Jaya',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showLocationPicker() {
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
                    'Select Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._locationOptions.map((loc) {
                  final isSelected = _selectedLocation == loc;
                  return ListTile(
                    leading: Icon(
                      Icons.location_on_rounded,
                      color: isSelected ? AppColors.primary : null,
                    ),
                    title: Text(
                      loc,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _selectedLocation = loc);
                      Navigator.of(context).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMoreSportsPicker() {
    final extraSports = [
      'Surfing',
      'Hiking',
      'Skiing',
      'Tennis',
      'Camping',
      'Water Sports',
      'Table Tennis',
      'Basketball',
    ];

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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'All Sports & Activities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...extraSports.map((sport) {
                  return ListTile(
                    title: Text(sport),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      setState(() => _selectedSport = sport);
                      Navigator.of(context).pop();
                      _executeSearch(sportOverride: sport);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _executeSearch({String? sportOverride}) {
    final sport = sportOverride ?? _selectedSport;
    final Set<String> categories =
        (sport != null && sport != 'More') ? {sport} : {};

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SportSearchResultsScreen(
          initialQuery: _searchCtrl.text,
          initialFilters: GearFilters(
            categories: categories,
            location: _selectedLocation,
            distanceKm: 5.0,
            availableNow: true,
          ),
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
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. App Header: Logo + SportShare title + subtitle
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.sports_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SportShare',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rent • Play • Share',
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

                const SizedBox(height: 24),

                // 2. Search Field: "What equipment do you need?"
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _executeSearch(),
                    style: TextStyle(
                      fontSize: 15,
                      color: titleColor,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What equipment do you need?',
                      hintStyle: TextStyle(
                        fontSize: 14.5,
                        color: subColor,
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => setState(_searchCtrl.clear),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Location Dropdown Selector
                InkWell(
                  onTap: _showLocationPicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedLocation,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: subColor,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // 4. Section: "Browse by Sport"
                Text(
                  'Browse by Sport',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 16),

                // 5. 2x3 Grid of sport tiles matching wireframe
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: _sportCategories.length,
                  itemBuilder: (context, index) {
                    final item = _sportCategories[index];
                    final isSelected = _selectedSport == item.$1;

                    return InkWell(
                      onTap: () {
                        if (item.$1 == 'More') {
                          _showMoreSportsPicker();
                        } else {
                          setState(() => _selectedSport = item.$1);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                              : cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.03,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.borderDark
                                        : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.$2,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textSecondaryLight),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.$1,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 36),

                // 6. Bottom Search Equipment Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _executeSearch(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepNavy,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Search Equipment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
