import 'package:cloud_firestore/cloud_firestore.dart';

/// A piece of equipment listed by a commercial shop (Firestore: `products`).
class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.description,
    required this.condition,
    required this.pricePerDay,
    required this.deposit,
    required this.quantity,
    required this.isAvailable,
    this.imageUrl = '',
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String category;
  final String description;
  final String condition; // Excellent | Good | Fair
  final double pricePerDay;
  final double deposit;
  final int quantity;
  final bool isAvailable;
  final String imageUrl;
  final DateTime? createdAt;

  factory ShopProduct.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return ShopProduct(
      id: doc.id,
      ownerId: (d['ownerId'] ?? '') as String,
      name: (d['name'] ?? '') as String,
      category: (d['category'] ?? 'Other') as String,
      description: (d['description'] ?? '') as String,
      condition: (d['condition'] ?? 'Good') as String,
      pricePerDay: (d['pricePerDay'] as num?)?.toDouble() ?? 0,
      deposit: (d['deposit'] as num?)?.toDouble() ?? 0,
      quantity: (d['quantity'] as num?)?.toInt() ?? 0,
      isAvailable: (d['isAvailable'] ?? true) as bool,
      imageUrl: (d['imageUrl'] ?? '') as String,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Editable fields. ownerId / createdAt are set by [ShopProductService].
  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'description': description,
        'condition': condition,
        'pricePerDay': pricePerDay,
        'deposit': deposit,
        'quantity': quantity,
        'isAvailable': isAvailable,
        'imageUrl': imageUrl,
      };
}
