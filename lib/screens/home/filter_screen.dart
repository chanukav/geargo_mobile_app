import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/app_settings_service.dart';
import 'tabs/home_tab.dart';

/// Filter values chosen by the user on the [FilterScreen].
class GearFilters {
  static const double maxDistance = 50;
  static const double maxPrice = 150;

  final double distanceKm;
  final Set<String> categories;
  final RangeValues price;
  final bool availableNow;

  const GearFilters({
    this.distanceKm = 15,
    this.categories = const {},
    this.price = const RangeValues(0, maxPrice),
    this.availableNow = false,
  });

  /// True when price max is at the "$150+" end (no upper limit).
  bool get priceUnbounded => price.end >= maxPrice;
}

const List<String> filterCategories = [
  'Cricket',
  'Badminton',
  'Cycling',
  'Surfing',
  'Hiking',
  'Skiing',
  'Tennis',
  'Camping',
  'Fitness',
  'Water Sports',
];

class FilterScreen extends StatefulWidget {
  final GearFilters initial;
  const FilterScreen({super.key, required this.initial});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late double _distance = widget.initial.distanceKm;
  late Set<String> _cats = {...widget.initial.categories};
  late RangeValues _price = widget.initial.price;
  late bool _available = widget.initial.availableNow;

  void _reset() => setState(() {
        _distance = 15;
        _cats = {};
        _price = const RangeValues(0, GearFilters.maxPrice);
        _available = false;
      });

  void _apply() => Navigator.of(context).pop(GearFilters(
        distanceKm: _distance,
        categories: _cats,
        price: _price,
        availableNow: _available,
      ));

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textPrimaryDark : kNavy;
    final subColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final priceLabel = '\$${_price.start.round()} – '
        '\$${_price.end.round()}${_price.end >= GearFilters.maxPrice ? '+' : ''}';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          settings.tr('filter'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: titleColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderColor),
                Expanded(
                  child: ListView(
                    children: [
                      _section(
                        title: settings.tr('distance_radius'),
                        trailing: '${_distance.round()} km',
                        titleColor: titleColor,
                        borderColor: borderColor,
                        child: _slider(
                          Slider(
                            value: _distance,
                            min: 1,
                            max: GearFilters.maxDistance,
                            onChanged: (v) => setState(() => _distance = v),
                          ),
                          '1 km',
                          '50 km',
                          isDark,
                          borderColor,
                          subColor,
                        ),
                      ),
                      _section(
                        title: settings.tr('categories'),
                        titleColor: titleColor,
                        borderColor: borderColor,
                        child: Column(
                          children: filterCategories.map((c) {
                            final on = _cats.contains(c);
                            return InkWell(
                              onTap: () => setState(
                                  () => on ? _cats.remove(c) : _cats.add(c)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: titleColor,
                                        ),
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: on
                                            ? AppColors.primary
                                            : (isDark ? AppColors.surfaceDark : Colors.white),
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: on ? AppColors.primary : borderColor,
                                        ),
                                      ),
                                      child: on
                                          ? const Icon(Icons.check_rounded,
                                              size: 18, color: Colors.white)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      _section(
                        title: settings.tr('price_per_day'),
                        trailing: priceLabel,
                        titleColor: titleColor,
                        borderColor: borderColor,
                        child: _slider(
                          RangeSlider(
                            values: _price,
                            min: 0,
                            max: GearFilters.maxPrice,
                            onChanged: (v) => setState(() => _price = v),
                          ),
                          '\$0',
                          '\$150+',
                          isDark,
                          borderColor,
                          subColor,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    settings.tr('available_now'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    settings.tr('only_available_today'),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: subColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _available,
                              activeThumbColor: Colors.white,
                              activeTrackColor: AppColors.primary,
                              onChanged: (v) => setState(() => _available = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shadowColor:
                            AppColors.secondary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        settings.tr('apply_filters'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: Text(
                    settings.tr('reset_filters'),
                    style: TextStyle(
                      color: subColor,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    String? trailing,
    required Color titleColor,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _slider(
    Widget slider,
    String min,
    String max,
    bool isDark,
    Color borderColor,
    Color subColor,
  ) {
    final style = TextStyle(fontSize: 12, color: subColor);
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: borderColor,
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
            rangeThumbShape: const RoundRangeSliderThumbShape(),
          ),
          child: slider,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(min, style: style), Text(max, style: style)],
        ),
      ],
    );
  }
}
