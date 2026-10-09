import '../../models/gear_item.dart';
import 'filter_screen.dart';

/// Shared filter logic for search tab and filter sheet live counts (UI-03).
int countFilteredGear({
  required List<GearItem> catalog,
  required GearFilters filters,
  String query = '',
}) {
  final q = query.trim().toLowerCase();
  return catalog.where((g) {
    final match = q.isEmpty ||
        g.name.toLowerCase().contains(q) ||
        g.category.toLowerCase().contains(q) ||
        (q.contains('bike') && g.category == 'Cycling');
    final inCategory =
        filters.categories.isEmpty || filters.categories.contains(g.category);
    final inPrice = g.pricePerDay >= filters.price.start &&
        (filters.priceUnbounded || g.pricePerDay <= filters.price.end);
    return match &&
        inCategory &&
        inPrice &&
        g.distanceKm <= filters.distanceKm &&
        (!filters.availableNow || g.available);
  }).length;
}
