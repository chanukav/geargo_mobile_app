import 'package:flutter/material.dart';

import '../core/theme/shop_theme.dart';
import 'shop/shop_products_screen.dart';
import 'transactions/browse_equipment_screen.dart';
import 'transactions/transactions_screen.dart';

/// Entry point for the Commercial Shop & Transaction Management module.
/// Open it from the app's home screen with:
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopTransactionsHome()));
class ShopTransactionsHome extends StatelessWidget {
  const ShopTransactionsHome({super.key});

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);

    Widget tile(IconData icon, String title, String subtitle, Widget screen) {
      return Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Shop & Transactions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          tile(Icons.inventory_2_outlined, 'Shop Inventory',
              'Add, edit, and remove your equipment', ShopProductsScreen()),
          const SizedBox(height: 12),
          tile(Icons.shopping_bag_outlined, 'Rent Equipment',
              'Book equipment with delivery or pickup', const BrowseEquipmentScreen()),
          const SizedBox(height: 12),
          tile(Icons.receipt_long_outlined, 'Transactions',
              'My bookings and shop orders', const TransactionsScreen()),
        ],
      ),
    );
  }
}
