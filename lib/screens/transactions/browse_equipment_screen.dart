import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/shop_theme.dart';
import '../../core/utils/format.dart';
import '../../models/shop_product.dart';
import '../../services/shop_product_service.dart';
import 'booking_details_screen.dart';

/// Simple equipment picker that starts the booking flow.
/// (The Renter module's search screen can call BookingDetailsScreen directly.)
class BrowseEquipmentScreen extends StatelessWidget {
  BrowseEquipmentScreen({super.key});

  final ShopProductService _service = ShopProductService();

  @override
  Widget build(BuildContext context) => ShopThemed(builder: _content);

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Choose equipment')),
      body: StreamBuilder<List<ShopProduct>>(
        stream: _service.streamAvailableProducts(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load equipment.\n${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!.where((p) => p.quantity > 0).toList();
          if (items.isEmpty) {
            return const Center(child: Text('No equipment available right now.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final p = items[i];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.sports_basketball_outlined,
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${p.category} • ${p.condition}'
                    '${p.ownerId == myUid ? ' • Your listing' : ''}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(money(p.pricePerDay),
                          style: theme.textTheme.titleMedium),
                      Text('/day', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingDetailsScreen(product: p),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
