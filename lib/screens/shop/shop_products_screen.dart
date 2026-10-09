import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/shop_theme.dart';
import '../../core/utils/format.dart';
import '../../models/shop_product.dart';
import '../../services/shop_product_service.dart';
import 'product_form_screen.dart';

/// Shop/ShopProduct Management: READ (list), UPDATE (availability switch, edit),
/// DELETE (trash icon). CREATE is the "Add equipment" button.
class ShopProductsScreen extends StatelessWidget {
  ShopProductsScreen({super.key});

  final ShopProductService _service = ShopProductService();

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Shop Inventory')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline,
                    size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text('Signed Out', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Please sign in to view and manage your shop inventory.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Shop Inventory')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add equipment'),
      ),
      body: StreamBuilder<List<ShopProduct>>(
        stream: _service.streamMyProducts(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load your inventory.\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 56, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('No equipment listed yet',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap "Add equipment" to list your first item.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _ProductCard(product: items[i], service: _service),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.service});

  final ShopProduct product;
  final ShopProductService service;

  Future<void> _confirmDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete equipment?'),
        content: Text('"${product.name}" will be removed from your inventory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await service.deleteProduct(product.id);
      messenger.showSnackBar(const SnackBar(content: Text('Equipment deleted')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 56,
                height: 56,
                color: theme.colorScheme.primaryContainer,
                child: product.imageUrl.trim().isNotEmpty
                    ? Image.network(
                        product.imageUrl.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(Icons.sports_basketball_outlined,
                              color: theme.colorScheme.onPrimaryContainer),
                        ),
                      )
                    : Center(
                        child: Icon(Icons.sports_basketball_outlined,
                            color: theme.colorScheme.onPrimaryContainer),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text('${product.category} • ${product.condition}',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    '${money(product.pricePerDay)}/day  •  '
                    'Deposit ${money(product.deposit)}  •  Qty ${product.quantity}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(product.isAvailable ? 'Available' : 'Unavailable',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(width: 8),
                      Switch(
                        value: product.isAvailable,
                        onChanged: (v) =>
                            service.setAvailability(product.id, v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductFormScreen(product: product),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
