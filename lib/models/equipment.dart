import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'gear_item.dart';

/// Equipment category definition with display metadata.
class EquipmentCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const EquipmentCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<EquipmentCategory> allCategories = [
    EquipmentCategory(
      id: 'mountain_bikes',
      name: 'Mountain Bikes',
      icon: Icons.directions_bike_rounded,
      color: Color(0xFF2F80ED),
    ),
    EquipmentCategory(
      id: 'camping',
      name: 'Camping & Hiking',
      icon: Icons.forest_rounded,
      color: Color(0xFF10B981),
    ),
    EquipmentCategory(
      id: 'water_sports',
      name: 'Water Sports',
      icon: Icons.surfing_rounded,
      color: Color(0xFF0EA5E9),
    ),
    EquipmentCategory(
      id: 'winter_sports',
      name: 'Winter Sports',
      icon: Icons.downhill_skiing_rounded,
      color: Color(0xFF6366F1),
    ),
    EquipmentCategory(
      id: 'cameras',
      name: 'Cameras & Drones',
      icon: Icons.camera_alt_rounded,
      color: Color(0xFF8B5CF6),
    ),
    EquipmentCategory(
      id: 'tools',
      name: 'Tools & Hardware',
      icon: Icons.handyman_rounded,
      color: Color(0xFFFF8A3D),
    ),
    EquipmentCategory(
      id: 'fitness',
      name: 'Fitness & Sports',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFEC4899),
    ),
    EquipmentCategory(
      id: 'other',
      name: 'Other Gear',
      icon: Icons.category_rounded,
      color: Color(0xFF64748B),
    ),
  ];

  static EquipmentCategory findById(String id) {
    return allCategories.firstWhere(
      (c) => c.id.toLowerCase() == id.toLowerCase(),
      orElse: () => const EquipmentCategory(
        id: 'other',
        name: 'General Gear',
        icon: Icons.category_rounded,
        color: Color(0xFF64748B),
      ),
    );
  }
}

/// Domain model representing an Equipment listing.
///
/// Matches database table schema:
/// - id: String
/// - owner_id: String
/// - name: String
/// - category_id: String
/// - description: String
/// - price: double
/// - availability: bool
/// - image: String
/// - created_at: DateTime
/// - updated_at: DateTime
class Equipment {
  final String id;
  final String ownerId;
  final String name;
  final String categoryId;
  final String description;
  final double price;
  final bool availability;
  final String image;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional UX properties (optional with sensible defaults)
  final String condition;
  final String location;
  final double rating;
  final int reviewsCount;

  /// Commercial shop persona: optional tiered rates and logistics.
  final double? priceWeekly;
  final double? priceMonthly;
  final int stockUnits;
  final String? shopPickupLocation;
  final String? shopOpeningHours;
  final String? deliveryWindow;

  const Equipment({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.categoryId,
    required this.description,
    required this.price,
    required this.availability,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
    this.condition = 'Excellent',
    this.location = 'Denver, CO',
    this.rating = 4.9,
    this.reviewsCount = 12,
    this.priceWeekly,
    this.priceMonthly,
    this.stockUnits = 1,
    this.shopPickupLocation,
    this.shopOpeningHours,
    this.deliveryWindow,
  });

  /// Category metadata resolved from [categoryId].
  EquipmentCategory get category => EquipmentCategory.findById(categoryId);

  /// Status display label
  String get statusText => availability ? 'Available' : 'Unavailable';

  /// Serializes model to Firestore / Database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'category_id': categoryId,
      'description': description,
      'price': price,
      'availability': availability,
      'image': image,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'condition': condition,
      'location': location,
      'rating': rating,
      'reviews_count': reviewsCount,
      if (priceWeekly != null) 'price_weekly': priceWeekly,
      if (priceMonthly != null) 'price_monthly': priceMonthly,
      'stock_units': stockUnits,
      if (shopPickupLocation != null) 'shop_pickup_location': shopPickupLocation,
      if (shopOpeningHours != null) 'shop_opening_hours': shopOpeningHours,
      if (deliveryWindow != null) 'delivery_window': deliveryWindow,
    };
  }

  /// Deserializes map or Firestore DocumentSnapshot into [Equipment].
  factory Equipment.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    bool parseBool(dynamic value) {
      if (value == null) return true;
      if (value is bool) return value;
      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'available';
      }
      if (value is num) return value != 0;
      return true;
    }

    return Equipment(
      id: (docId != null && docId.isNotEmpty)
          ? docId
          : (map['id']?.toString() ?? ''),
      ownerId: map['owner_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Untitled Equipment',
      categoryId: map['category_id']?.toString() ?? 'other',
      description: map['description']?.toString() ?? '',
      price: parsePrice(map['price']),
      availability: parseBool(map['availability']),
      image: map['image']?.toString() ?? '',
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      condition: map['condition']?.toString() ?? 'Excellent',
      location: map['location']?.toString() ?? 'Denver, CO',
      rating: parsePrice(map['rating'] ?? 4.9),
      reviewsCount: (map['reviews_count'] is num)
          ? (map['reviews_count'] as num).toInt()
          : 0,
      priceWeekly: map['price_weekly'] != null
          ? parsePrice(map['price_weekly'])
          : null,
      priceMonthly: map['price_monthly'] != null
          ? parsePrice(map['price_monthly'])
          : null,
      stockUnits: (map['stock_units'] is num)
          ? (map['stock_units'] as num).toInt()
          : 1,
      shopPickupLocation: map['shop_pickup_location']?.toString(),
      shopOpeningHours: map['shop_opening_hours']?.toString(),
      deliveryWindow: map['delivery_window']?.toString(),
    );
  }

  /// Copies instance with optional overrides.
  Equipment copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? categoryId,
    String? description,
    double? price,
    bool? availability,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? condition,
    String? location,
    double? rating,
    int? reviewsCount,
    double? priceWeekly,
    double? priceMonthly,
    int? stockUnits,
    String? shopPickupLocation,
    String? shopOpeningHours,
    String? deliveryWindow,
  }) {
    return Equipment(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      price: price ?? this.price,
      availability: availability ?? this.availability,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      priceWeekly: priceWeekly ?? this.priceWeekly,
      priceMonthly: priceMonthly ?? this.priceMonthly,
      stockUnits: stockUnits ?? this.stockUnits,
      shopPickupLocation: shopPickupLocation ?? this.shopPickupLocation,
      shopOpeningHours: shopOpeningHours ?? this.shopOpeningHours,
      deliveryWindow: deliveryWindow ?? this.deliveryWindow,
    );
  }

  /// Maps a Firestore listing into discovery UI model.
  GearItem toGearItem({
    String ownerDisplay = 'GearGo Host',
    bool ownerVerified = false,
  }) {
    return GearItem(
      name: name,
      owner: ownerDisplay,
      category: category.name,
      image: image,
      rating: rating,
      reviews: reviewsCount,
      distanceKm: 2.0,
      pricePerDay: price.round(),
      available: availability,
      verified: ownerVerified,
      listingId: id,
      ownerId: ownerId,
      description: description,
    );
  }
}
