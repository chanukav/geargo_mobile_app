import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model representing a Saved / Favorited Equipment listing (CRUD 02).
/// Enables renters to bookmark gear, categorize into collections, attach personal notes,
/// and quickly launch rental bookings.
class SavedEquipment {
  final String id;
  final String renterId;
  final String equipmentId;
  final String equipmentName;
  final String equipmentCategory;
  final String equipmentImage;
  final double dailyPrice;
  final double rating;
  final int reviewsCount;
  final bool available;
  final String collectionName;
  final String renterNote;
  final DateTime savedAt;

  const SavedEquipment({
    required this.id,
    required this.renterId,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentCategory,
    required this.equipmentImage,
    required this.dailyPrice,
    this.rating = 4.9,
    this.reviewsCount = 12,
    this.available = true,
    this.collectionName = 'Favorites',
    this.renterNote = '',
    required this.savedAt,
  });

  SavedEquipment copyWith({
    String? id,
    String? renterId,
    String? equipmentId,
    String? equipmentName,
    String? equipmentCategory,
    String? equipmentImage,
    double? dailyPrice,
    double? rating,
    int? reviewsCount,
    bool? available,
    String? collectionName,
    String? renterNote,
    DateTime? savedAt,
  }) {
    return SavedEquipment(
      id: id ?? this.id,
      renterId: renterId ?? this.renterId,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      equipmentCategory: equipmentCategory ?? this.equipmentCategory,
      equipmentImage: equipmentImage ?? this.equipmentImage,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      available: available ?? this.available,
      collectionName: collectionName ?? this.collectionName,
      renterNote: renterNote ?? this.renterNote,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'renter_id': renterId,
      'equipment_id': equipmentId,
      'equipment_name': equipmentName,
      'equipment_category': equipmentCategory,
      'equipment_image': equipmentImage,
      'daily_price': dailyPrice,
      'rating': rating,
      'reviews_count': reviewsCount,
      'available': available,
      'collection_name': collectionName,
      'renter_note': renterNote,
      'saved_at': Timestamp.fromDate(savedAt),
    };
  }

  factory SavedEquipment.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    double parseNum(dynamic v, [double fallback = 0.0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    int parseInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    bool parseBool(dynamic v) {
      if (v == null) return true;
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true' || v == '1';
      return true;
    }

    return SavedEquipment(
      id: (docId != null && docId.isNotEmpty)
          ? docId
          : (map['id']?.toString() ?? ''),
      renterId: map['renter_id']?.toString() ?? '',
      equipmentId: map['equipment_id']?.toString() ?? '',
      equipmentName: map['equipment_name']?.toString() ?? 'Equipment Item',
      equipmentCategory: map['equipment_category']?.toString() ?? 'General',
      equipmentImage: map['equipment_image']?.toString() ?? '',
      dailyPrice: parseNum(map['daily_price']),
      rating: parseNum(map['rating'], 4.9),
      reviewsCount: parseInt(map['reviews_count'], 12),
      available: parseBool(map['available']),
      collectionName: map['collection_name']?.toString() ?? 'Favorites',
      renterNote: map['renter_note']?.toString() ?? '',
      savedAt: parseDate(map['saved_at']),
    );
  }
}
