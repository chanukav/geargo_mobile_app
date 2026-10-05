import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/gear_item.dart';
import '../filter_screen.dart';
import 'home_tab.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _ctrl = TextEditingController();
  bool _distance = true;
  bool _rating = false;
  bool _availableNow = false;
  GearFilters _filters = const GearFilters(
    distanceKm: GearFilters.maxDistance,
  );

  Future<void> _openFilters() async {
    final result = await Navigator.of(context).push<GearFilters>(
      MaterialPageRoute(builder: (_) => FilterScreen(initial: _filters)),
    );
    if (result != null) {
      setState(() {
        _filters = result;
        _availableNow = result.availableNow;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<GearItem> get _results {
    final q = _ctrl.text.trim().toLowerCase();
    var list = sampleGear.where((g) {
      final match = q.isEmpty ||
          g.name.toLowerCase().contains(q) ||
          g.category.toLowerCase().contains(q) ||
          (q.contains('bike') && g.category == 'Cycling');
      final inCategory =
          _filters.categories.isEmpty || _filters.categories.contains(g.category);
      final inPrice = g.pricePerDay >= _filters.price.start &&
          (_filters.priceUnbounded || g.pricePerDay <= _filters.price.end);
      return match &&
          inCategory &&
          inPrice &&
          g.distanceKm <= _filters.distanceKm &&
          (!_availableNow || g.available);
    }).toList();
    if (_rating) {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_distance) {
      list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(children: [
              Expanded(
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 1.6),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: TextField(
                controller: _ctrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: kNavy),
                decoration: InputDecoration(
                  hintText: 'Search equipment...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _ctrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, color: kNavy),
                          onPressed: () => setState(_ctrl.clear),
                        ),
                ),
              ),
            ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _openFilters,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text('${results.length} items found nearby',
                      style: const TextStyle(
                          color: AppColors.textSecondaryLight, fontSize: 14)),
                ),
                Text('Sort: ${_rating ? 'Rating' : 'Nearest'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: kNavy)),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _chip('Distance', _distance && !_rating, () {
                  setState(() {
                    _distance = true;
                    _rating = false;
                  });
                }),
                _chip('Rating', _rating, () {
                  setState(() {
                    _rating = true;
                    _distance = false;
                  });
                }),
                _chip('Available Now', _availableNow,
                    () => setState(() => _availableNow = !_availableNow)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Text('No equipment found',
                        style: TextStyle(
                            color: AppColors.textSecondaryLight, fontSize: 16)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: results.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _ResultCard(item: results[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.borderLight,
                width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : kNavy)),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_rounded,
                    size: 16, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final GearItem item;
  const _ResultCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(20)),
            child: SizedBox(
              width: 118,
              height: double.infinity,
              child: Image.asset(item.image, fit: BoxFit.cover),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: kNavy)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text('by ${item.owner}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondaryLight)),
                      ),
                      if (item.verified) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded,
                                  size: 11, color: AppColors.primary),
                              SizedBox(width: 2),
                              Text('VERIFIED',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 17, color: Color(0xFFFFB400)),
                      const SizedBox(width: 3),
                      Text('${item.rating}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: kNavy)),
                      Text(' (${item.reviews})',
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondaryLight)),
                      const Spacer(),
                      Text('${item.distanceKm} km',
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondaryLight)),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text('\$${item.pricePerDay}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: AppColors.primary)),
                      const Text('/day',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight)),
                      const Spacer(),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: item.available
                              ? () => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content:
                                          Text('Booking ${item.name}...')))
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.borderLight,
                            elevation: 4,
                            shadowColor:
                                AppColors.secondary.withValues(alpha: 0.4),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            minimumSize: const Size(0, 36),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(item.available ? 'Book Now' : 'Rented',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                      ),
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
