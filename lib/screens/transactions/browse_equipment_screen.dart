import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/shop_theme.dart';
import '../../core/utils/format.dart';
import '../../models/shop_product.dart';
import '../../services/shop_product_service.dart';
import 'booking_details_screen.dart';

/// Equipment browse and search screen that starts the booking flow.
/// Features a search bar, category filter chips, and image thumbnails.
class BrowseEquipmentScreen extends StatefulWidget {
  const BrowseEquipmentScreen({super.key});

  @override
  State<BrowseEquipmentScreen> createState() => _BrowseEquipmentScreenState();
}

class _BrowseEquipmentScreenState extends State<BrowseEquipmentScreen> {
  final ShopProductService _service = ShopProductService();
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    'All',
    'Mountain Bikes',
    'Cricket',
    'Football',
    'Camping',
    'Gym',
    'Water Sports',
    'Racket Sports',
    'Other',
  ];

  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _placeholderThumbnail(ThemeData theme, bool isOwnListing) {
    return Center(
      child: Icon(
        Icons.sports_basketball_outlined,
        color: isOwnListing
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Equipment')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search equipment by name or keyword...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: _categories.map((c) {
                final isSelected = _selectedCategory == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = c);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Equipment List
          Expanded(
            child: StreamBuilder<List<ShopProduct>>(
              stream: _service.streamAvailableProducts(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load equipment.\n${snap.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final inStock =
                    snap.data!.where((p) => p.quantity > 0).toList();

                // Apply search and category filters
                final q = _searchQuery.toLowerCase();
                final items = inStock.where((p) {
                  final matchesCat =
                      _selectedCategory == 'All' || p.category == _selectedCategory;
                  final matchesSearch = q.isEmpty ||
                      p.name.toLowerCase().contains(q) ||
                      p.description.toLowerCase().contains(q);
                  return matchesCat && matchesSearch;
                }).toList();

                if (inStock.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No equipment available right now.'),
                    ),
                  );
                }

                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No equipment matches your search or category filter.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final p = items[i];
                    final isOwnListing = myUid != null && p.ownerId == myUid;

                    return Card(
                      color: isOwnListing
                          ? theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4)
                          : Colors.white,
                      child: ListTile(
                        enabled: !isOwnListing,
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 52,
                            height: 52,
                            color: isOwnListing
                                ? theme.colorScheme.surfaceContainerHighest
                                : theme.colorScheme.primaryContainer,
                            child: p.imageUrl.trim().isNotEmpty
                                ? Image.network(
                                    p.imageUrl.trim(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _placeholderThumbnail(theme, isOwnListing),
                                  )
                                : _placeholderThumbnail(theme, isOwnListing),
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text('${p.category} • ${p.condition}'),
                            if (isOwnListing)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Your listing (cannot rent own item)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              money(p.pricePerDay),
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text('/day', style: theme.textTheme.bodySmall),
                          ],
                        ),
                        onTap: isOwnListing
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        BookingDetailsScreen(product: p),
                                  ),
                                ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
