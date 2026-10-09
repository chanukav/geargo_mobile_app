import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/dummy_shop_data.dart';
import '../../core/theme/shop_theme.dart';
import '../../models/shop_product.dart';
import '../../services/shop_product_service.dart';
import 'booking_details_screen.dart';

/// Equipment browse and search screen that starts the booking flow.
/// Features a search bar, category filter chips, and rich card aesthetics.
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

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ShopPalette.text,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Rent Equipment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ShopPalette.text,
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ShopPalette.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search equipment by name or keyword...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: ShopPalette.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: ShopPalette.textMuted,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // 2. Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: _categories.map((c) {
                final isSelected = _selectedCategory == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: isSelected,
                    selectedColor: ShopPalette.blueTint,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? ShopPalette.blue
                          : ShopPalette.border,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? ShopPalette.blue
                          : ShopPalette.text,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = c);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // 3. Equipment Stream List
          Expanded(
            child: StreamBuilder<List<ShopProduct>>(
              stream: _service.streamAvailableProducts(),
              builder: (context, snap) {
                final firestoreProducts =
                    (snap.data ?? []).where((p) => p.quantity > 0).toList();

                // Ensure demo product (Trek Fuel EX 8 Gen 6) is available for viva/demo
                final hasDemoProduct = firestoreProducts.any((p) =>
                    p.name.toLowerCase().contains('trek') ||
                    p.id == DummyShopData.defaultProduct.id);

                final allProducts = List<ShopProduct>.from(firestoreProducts);
                if (!hasDemoProduct) {
                  allProducts.insert(0, DummyShopData.defaultProduct);
                }

                // Filter by search & category
                final q = _searchQuery.toLowerCase();
                final items = allProducts.where((p) {
                  final matchesCat = _selectedCategory == 'All' ||
                      p.category.toLowerCase() ==
                          _selectedCategory.toLowerCase();
                  final matchesSearch = q.isEmpty ||
                      p.name.toLowerCase().contains(q) ||
                      p.description.toLowerCase().contains(q);
                  return matchesCat && matchesSearch;
                }).toList();

                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No equipment matches your search or category filter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ShopPalette.textMuted),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final p = items[i];
                    final isOwnListing =
                        myUid != null && p.ownerId == myUid && myUid.isNotEmpty;
                    final img = p.imageUrl.trim().isNotEmpty
                        ? p.imageUrl.trim()
                        : DummyShopData.defaultHeroImage;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ShopPalette.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: isOwnListing
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          BookingDetailsScreen(product: p),
                                    ),
                                  ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Thumbnail Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    img,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 80,
                                      height: 80,
                                      color: const Color(0xFFF1F5F9),
                                      child: const Icon(
                                        Icons.directions_bike,
                                        color: ShopPalette.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Details Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Category Pill & Rating
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: ShopPalette.badgeBlue,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              p.category.toUpperCase(),
                                              style: const TextStyle(
                                                color: ShopPalette.badgeBlueText,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: const [
                                              Icon(
                                                Icons.star_rounded,
                                                size: 15,
                                                color: Color(0xFFF59E0B),
                                              ),
                                              SizedBox(width: 2),
                                              Text(
                                                '4.9',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: ShopPalette.text,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),

                                      // Equipment Name
                                      Text(
                                        p.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: ShopPalette.text,
                                        ),
                                      ),
                                      const SizedBox(height: 2),

                                      // Host name
                                      const Text(
                                        'by ${DummyShopData.shopName}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: ShopPalette.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // Price Row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.baseline,
                                            textBaseline:
                                                TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                '\$${p.pricePerDay.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: ShopPalette.blue,
                                                ),
                                              ),
                                              const Text(
                                                ' /day',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: ShopPalette.textMuted,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: ShopPalette.greenTint,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              p.condition.toUpperCase(),
                                              style: const TextStyle(
                                                color: ShopPalette.green,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
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
