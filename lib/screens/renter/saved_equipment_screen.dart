import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_helper.dart';
import '../../models/saved_equipment.dart';
import '../../services/saved_equipment_service.dart';
import 'create_rental_request_sheet.dart';
import 'widgets/edit_saved_item_dialog.dart';

/// Screen managing Saved / Favourite Equipment (CRUD 02 - Read / Filter / Update / Delete).
/// Includes collection filtering, personal notes, grid/list toggle, and direct rental booking.
class SavedEquipmentScreen extends StatefulWidget {
  final VoidCallback? onExploreTap;

  const SavedEquipmentScreen({super.key, this.onExploreTap});

  @override
  State<SavedEquipmentScreen> createState() => _SavedEquipmentScreenState();
}

class _SavedEquipmentScreenState extends State<SavedEquipmentScreen> {
  final _service = SavedEquipmentService();
  final _searchController = TextEditingController();

  String _selectedCollection = 'All';
  String _searchQuery = '';
  bool _isGridView = false;

  String get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid ?? 'guest_renter';
  }

  @override
  void initState() {
    super.initState();
    _service.seedStarterSaved(_currentUserId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRemove(SavedEquipment item) async {
    await _service.removeSavedItemById(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.deepNavy,
          content: Text('Removed "${item.equipmentName}" from saved'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: AppColors.secondary,
            onPressed: () async {
              await _service.addSavedItem(item);
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Favourites?'),
        content: const Text(
          'Are you sure you want to remove all saved equipment items from your wishlist?',
          style: TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.clearAll(_currentUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.deepNavy;
    final subText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final borderCol = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Saved Equipment',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: textColor,
            ),
            tooltip: _isGridView ? 'List View' : 'Grid View',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) {
              if (val == 'clear') _handleClearAll();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Clear All Saved'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<SavedEquipment>>(
        stream: _service.getSavedStream(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allItems = snapshot.data ?? [];

          // Extract unique collection names
          final collections = <String>{'All'};
          for (final item in allItems) {
            if (item.collectionName.isNotEmpty) {
              collections.add(item.collectionName);
            }
          }

          // Filter by collection & search
          final filtered = allItems.where((item) {
            final matchCollection = _selectedCollection == 'All' ||
                item.collectionName.toLowerCase() ==
                    _selectedCollection.toLowerCase();
            final matchQuery = _searchQuery.isEmpty ||
                item.equipmentName.toLowerCase().contains(_searchQuery) ||
                item.equipmentCategory.toLowerCase().contains(_searchQuery) ||
                item.renterNote.toLowerCase().contains(_searchQuery);
            return matchCollection && matchQuery;
          }).toList();

          return CustomScrollView(
            slivers: [
              // Search & Collection filter header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search bar
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderCol),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) =>
                              setState(() => _searchQuery = v.trim().toLowerCase()),
                          style: TextStyle(fontSize: 14.5, color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Search within saved items or notes...',
                            hintStyle: TextStyle(fontSize: 13, color: subText),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Collections Filter Chips
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: collections.map((col) {
                            final selected = _selectedCollection == col;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedCollection = col),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary
                                        : (isDark ? AppColors.surfaceDark : Colors.white),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selected ? AppColors.primary : borderCol,
                                      width: selected ? 1.4 : 1.0,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    col,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight:
                                          selected ? FontWeight.w800 : FontWeight.w600,
                                      color: selected ? Colors.white : textColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Item count info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${filtered.length} saved ${filtered.length == 1 ? 'item' : 'items'}',
                            style: TextStyle(fontSize: 12.5, color: subText, fontWeight: FontWeight.w600),
                          ),
                          if (_selectedCollection != 'All')
                            GestureDetector(
                              onTap: () => setState(() => _selectedCollection = 'All'),
                              child: const Text(
                                'Clear filter',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Empty State
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(textColor, subText),
                )
              else if (_isGridView)
                // Grid View
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _SavedGridCard(
                        item: filtered[i],
                        cardBg: cardBg,
                        borderCol: borderCol,
                        textColor: textColor,
                        subText: subText,
                        isDark: isDark,
                        onRemove: () => _handleRemove(filtered[i]),
                        onEdit: () => EditSavedItemDialog.show(context, filtered[i]),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                )
              else
                // List View
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final item = filtered[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _SavedListCard(
                            item: item,
                            cardBg: cardBg,
                            borderCol: borderCol,
                            textColor: textColor,
                            subText: subText,
                            isDark: isDark,
                            onRemove: () => _handleRemove(item),
                            onEdit: () => EditSavedItemDialog.show(context, item),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subText) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_outline_rounded,
                size: 46,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching saved gear'
                  : 'Your wishlist is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching with different terms or reset collection filters.'
                  : 'Tap the heart icon on any equipment to save it here for quick access and bookings.',
              style: TextStyle(fontSize: 13.5, color: subText, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (widget.onExploreTap != null)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: widget.onExploreTap,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Discover Equipment', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}

class _SavedListCard extends StatelessWidget {
  final SavedEquipment item;
  final Color cardBg;
  final Color borderCol;
  final Color textColor;
  final Color subText;
  final bool isDark;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  const _SavedListCard({
    required this.item,
    required this.cardBg,
    required this.borderCol,
    required this.textColor,
    required this.subText,
    required this.isDark,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 86,
                    height: 86,
                    child: EquipmentImageViewer(imageSource: item.equipmentImage),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.equipmentCategory.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.available
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.available ? 'Available' : 'Rented',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: item.available ? AppColors.success : AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.equipmentName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB400)),
                          const SizedBox(width: 3),
                          Text(
                            '${item.rating}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
                          ),
                          Text(
                            ' (${item.reviewsCount})',
                            style: TextStyle(fontSize: 11.5, color: subText),
                          ),
                          const Spacer(),
                          Text(
                            '\$${item.dailyPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          Text('/day', style: TextStyle(fontSize: 11, color: subText)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Renter Personal Note preview (if any)
            if (item.renterNote.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.renterNote,
                        style: TextStyle(fontSize: 12, color: subText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: onEdit,
                      child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Bottom Buttons
            Row(
              children: [
                // Collection Tag pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: borderCol.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_outlined, size: 12, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text(
                        item.collectionName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  color: AppColors.primary,
                  tooltip: 'Edit Note & Collection',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_rounded, size: 20),
                  color: AppColors.error,
                  tooltip: 'Remove from Saved',
                  onPressed: onRemove,
                ),
                const SizedBox(width: 4),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    CreateRentalRequestSheet.show(
                      context,
                      equipmentId: item.equipmentId,
                      equipmentName: item.equipmentName,
                      equipmentCategory: item.equipmentCategory,
                      equipmentImage: item.equipmentImage,
                      dailyPrice: item.dailyPrice,
                    );
                  },
                  child: const Text('Rent Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedGridCard extends StatelessWidget {
  final SavedEquipment item;
  final Color cardBg;
  final Color borderCol;
  final Color textColor;
  final Color subText;
  final bool isDark;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  const _SavedGridCard({
    required this.item,
    required this.cardBg,
    required this.borderCol,
    required this.textColor,
    required this.subText,
    required this.isDark,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with heart & availability overlay
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: EquipmentImageViewer(imageSource: item.equipmentImage),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 6),
                      ],
                    ),
                    child: IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                      icon: const Icon(Icons.favorite_rounded, color: AppColors.error),
                      onPressed: onRemove,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.equipmentCategory,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.equipmentName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB400)),
                      const SizedBox(width: 2),
                      Text(
                        '${item.rating}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      const Spacer(),
                      Text(
                        '\$${item.dailyPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      Text('/d', style: TextStyle(fontSize: 10, color: subText)),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        CreateRentalRequestSheet.show(
                          context,
                          equipmentId: item.equipmentId,
                          equipmentName: item.equipmentName,
                          equipmentCategory: item.equipmentCategory,
                          equipmentImage: item.equipmentImage,
                          dailyPrice: item.dailyPrice,
                        );
                      },
                      child: const Text('Rent Now', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ),
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
