import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/gear_item.dart';

const Color kNavy = Color(0xFF0F2A4A);
const Color kBg = Color(0xFFF6F8FB);

IconData categoryIcon(String c) {
  switch (c) {
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

  @override
  Widget build(BuildContext context) {
    final items = _category == 'All'
        ? sampleGear.take(4).toList()
        : sampleGear.where((g) => g.category == _category).toList();

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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Gear up today',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondaryLight)),
                            const SizedBox(height: 2),
                            Text('Hello, ${widget.name}! 👋',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: kNavy)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 16, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Colombo',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: kNavy)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_rounded,
                            color: AppColors.primary, size: 26),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Condition verified. All rentals are 100% insured against damage.',
                            style: TextStyle(
                                fontSize: 13.5, height: 1.35, color: kNavy),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: widget.onSearchTap,
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search_rounded,
                              color: AppColors.textSecondaryLight),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text('Search equipment...',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textMutedLight)),
                          ),
                          Icon(Icons.tune_rounded, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Browse by Sport',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kNavy)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: gearCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final c = gearCategories[i];
                  final sel = c == _category;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: sel ? kNavy : Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                            color: sel ? kNavy : AppColors.borderLight),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: kNavy.withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5))
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(categoryIcon(c),
                              size: 19, color: sel ? Colors.white : kNavy),
                          const SizedBox(width: 8),
                          Text(c,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: sel ? Colors.white : kNavy)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Rentals Near You',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kNavy)),
                  ),
                  Text('See All',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _GearCard(item: items[i]),
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
  }
}

class _GearCard extends StatelessWidget {
  final GearItem item;
  const _GearCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: kNavy.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                width: double.infinity,
                child: Image.asset(item.image, fit: BoxFit.cover),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: kNavy)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 17, color: Color(0xFFFFB400)),
                      const SizedBox(width: 3),
                      Text('${item.rating}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: kNavy)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${item.distanceKm} km away',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondaryLight)),
                  const Spacer(),
                  Row(
                    children: [
                      Text('\$${item.pricePerDay}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.primary)),
                      const Text('/day',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(available ? 'Avail' : 'Rented',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
