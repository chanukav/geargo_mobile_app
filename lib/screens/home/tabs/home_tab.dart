import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/gear_item.dart';
import '../../../services/app_settings_service.dart';
import '../../renter/renter_equipment_details_screen.dart';
import '../../renter/widgets/favorite_toggle_button.dart';
import '../widgets/appearance_language_sheet.dart';

const Color kNavy = Color(0xFF0F2A4A);
const Color kBg = Color(0xFFF6F8FB);

IconData categoryIcon(String c) {
  switch (c) {
    case 'Cricket':
      return Icons.sports_cricket_rounded;
    case 'Badminton':
      return Icons.sports_tennis_rounded;
    case 'Cycling':
      return Icons.directions_bike_rounded;
    case 'Surfing':
      return Icons.surfing_rounded;
    case 'Hiking':
      return Icons.hiking_rounded;
    case 'Skiing':
      return Icons.downhill_skiing_rounded;
    default:
      return Icons.apps_rounded;
  }
}

class HomeTab extends StatefulWidget {
  final String name;
  final VoidCallback onSearchTap;

  const HomeTab({super.key, required this.name, required this.onSearchTap});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _category = 'All';

  void _toggleTheme(AppSettingsService settings, bool isDark) {
    if (isDark) {
      settings.setThemeMode(ThemeMode.light);
    } else {
      settings.setThemeMode(ThemeMode.dark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
        final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
        final titleColor = isDark ? AppColors.textPrimaryDark : kNavy;
        final subColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

        final items = _category == 'All'
            ? sampleGear.take(4).toList()
            : sampleGear.where((g) => g.category == _category).toList();

        final currentLang = settings.languageCode;
        final langFlag = currentLang == 'en' ? '🇬🇧' : '🇱🇰';
        final langName = currentLang == 'en'
            ? 'EN'
            : (currentLang == 'si' ? 'සිංහල' : 'தமிழ்');

        return SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. User Welcome & Header Controls (Language & Theme Mode Switchers)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      size: 13,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    const Text(
                                      'Colombo · ',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        settings.tr('gear_up_today'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: subColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${settings.tr('hello')}, ${widget.name}! 👋',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Top-Right Header Actions: Language Switcher & Dark/Light Mode
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Language Selector Pill
                              InkWell(
                                onTap: () => AppearanceLanguageSheet.show(context),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: borderColor),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: isDark ? 0.25 : 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(langFlag,
                                          style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 4),
                                      Text(
                                        langName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: titleColor,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: subColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Theme Toggle Button (Light / Dark)
                              InkWell(
                                onTap: () => _toggleTheme(settings, isDark),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: borderColor),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: isDark ? 0.25 : 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isDark
                                        ? Icons.dark_mode_rounded
                                        : Icons.wb_sunny_rounded,
                                    size: 18,
                                    color: isDark
                                        ? const Color(0xFF60A5FA)
                                        : const Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2. Verified Insurance Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF162544)
                              : AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded,
                                color: AppColors.primary, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                settings.tr('insured_banner'),
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : kNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Search Bar with Quick Filter Button
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onSearchTap,
                              child: Container(
                                height: 52,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: isDark ? 0.2 : 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.search_rounded,
                                        color: subColor, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        settings.tr('search_hint'),
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          color: subColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Appearance & Filter icon button
                          InkWell(
                            onTap: () => AppearanceLanguageSheet.show(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 5. Browse by Sport header
                      Text(
                        settings.tr('browse_by_sport'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Categories Horizontal List
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: gearCategories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final c = gearCategories[i];
                      final sel = c == _category;
                      return GestureDetector(
                        onTap: () => setState(() => _category = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary
                                : (isDark ? AppColors.surfaceDark : Colors.white),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: sel ? AppColors.primary : borderColor,
                              width: sel ? 1.5 : 1.0,
                            ),
                            boxShadow: sel
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                categoryIcon(c),
                                size: 18,
                                color: sel
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : kNavy),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: sel
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.textPrimaryDark
                                          : kNavy),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Popular Rentals Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          settings.tr('popular_rentals'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onSearchTap,
                        child: Text(
                          settings.tr('see_all'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Gear Grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _GearCard(
                      item: items[i],
                      cardBg: cardBg,
                      borderColor: borderColor,
                      titleColor: titleColor,
                      subColor: subColor,
                      isDark: isDark,
                    ),
                    childCount: items.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.74,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

class _GearCard extends StatelessWidget {
  final GearItem item;
  final Color cardBg;
  final Color borderColor;
  final Color titleColor;
  final Color subColor;
  final bool isDark;

  const _GearCard({
    required this.item,
    required this.cardBg,
    required this.borderColor,
    required this.titleColor,
    required this.subColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
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
                builder: (_) => RenterEquipmentDetailsScreen.fromGearItem(item),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(20)),
                        child: SizedBox(
                          width: double.infinity,
                          child: Image.asset(item.image, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: FavoriteToggleButton.fromGearItem(
                        item,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFFFB400)),
                      const SizedBox(width: 3),
                      Text(
                        '${item.rating}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.distanceKm} km away',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: subColor,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '\$${item.pricePerDay}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '/day',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: subColor,
                        ),
                      ),
                      const Spacer(),
                      _StatusBadge(available: item.available),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

class _StatusBadge extends StatelessWidget {
  final bool available;
  const _StatusBadge({required this.available});

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.success : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        available ? 'Avail' : 'Rented',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
