import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
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
    final priceLabel = '\$${_price.start.round()} – '
        '\$${_price.end.round()}${_price.end >= GearFilters.maxPrice ? '+' : ''}';

    return Scaffold(
      backgroundColor: kBg,
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
                      const Expanded(
                        child: Text('Filters',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: kNavy)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: kNavy),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                Expanded(
                  child: ListView(
                    children: [
                      _section(
                        title: 'Distance Radius',
                        trailing: '${_distance.round()} km',
                        child: _slider(
                          Slider(
                            value: _distance,
                            min: 1,
                            max: GearFilters.maxDistance,
                            onChanged: (v) => setState(() => _distance = v),
                          ),
                          '1 km',
                          '50 km',
                        ),
                      ),
                      _section(
                        title: 'Categories',
                        child: Column(
                          children: filterCategories.map((c) {
                            final on = _cats.contains(c);
                            return InkWell(
                              onTap: () => setState(
                                  () => on ? _cats.remove(c) : _cats.add(c)),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(c,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: kNavy)),
                                    ),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: on
                                            ? AppColors.primary
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(7),
                                        border: Border.all(
                                            color: on
                                                ? AppColors.primary
                                                : AppColors.borderLight),
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
                        title: 'Price Per Day',
                        trailing: priceLabel,
                        child: _slider(
                          RangeSlider(
                            values: _price,
                            min: 0,
                            max: GearFilters.maxPrice,
                            onChanged: (v) => setState(() => _price = v),
                          ),
                          '\$0',
                          '\$150+',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 18),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Available Now',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: kNavy)),
                                  SizedBox(height: 3),
                                  Text('Only show items ready to pick up today',
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          color:
                                              AppColors.textSecondaryLight)),
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
                const Divider(height: 1, color: AppColors.borderLight),
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
                      child: const Text('Apply Filters',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset All Filters',
                      style: TextStyle(
                          color: AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({required String title, String? trailing, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: kNavy)),
              ),
              if (trailing != null)
                Text(trailing,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _slider(Widget slider, String min, String max) {
    const style = TextStyle(fontSize: 12, color: AppColors.textSecondaryLight);
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.borderLight,
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
