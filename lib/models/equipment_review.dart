import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model representing a review saved in the database.
///
/// Entity Relationship (1-to-N):
/// - A review belongs to exactly ONE piece of equipment ([equipmentId]).
/// - A piece of equipment can have MANY reviews.
///
/// Database collection: `equipment_reviews`
/// Document schema:
/// - id: String
/// - equipment_id: String (Foreign key to equipment table/collection)
/// - owner_id: String (Equipment host ID)
/// - author_id: String (Renter user ID)
/// - author_name: String (Renter display name)
/// - rating: int (1 to 5)
/// - comment: String
/// - created_at: Timestamp / DateTime
/// - updated_at: Timestamp / DateTime (optional)
/// - rental_request_id: String? (optional)
/// - equipment_name: String? (snapshot of equipment title)
class EquipmentReview {
  final String id;

  /// Foreign key: A review belongs to exactly ONE piece of equipment.
  final String equipmentId;

  /// Host / Owner ID of the equipment.
  final String ownerId;

  /// User ID of the reviewer (renter).
  final String authorId;

  /// Display name of the reviewer.
  final String authorName;

  /// Star rating between 1 and 5.
  final int rating;

  /// Detailed textual review.
  final String comment;

  /// When the review was submitted.
  final DateTime createdAt;

  /// When the review was last updated (if applicable).
  final DateTime? updatedAt;

  /// Optional rental request ID this review was made for.
  final String? rentalRequestId;

  /// Snapshot of the equipment title for display convenience.
  final String? equipmentName;

  const EquipmentReview({
    required this.id,
    required this.equipmentId,
    required this.ownerId,
    required this.authorId,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    this.rentalRequestId,
    this.equipmentName,
  });

  /// Serializes model to a database map for Firestore persistence.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipment_id': equipmentId,
      'owner_id': ownerId,
      'author_id': authorId,
      'author_name': authorName,
      'rating': rating.clamp(1, 5),
      'comment': comment.trim(),
      'created_at': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updated_at': Timestamp.fromDate(updatedAt!),
      if (rentalRequestId != null) 'rental_request_id': rentalRequestId,
      if (equipmentName != null) 'equipment_name': equipmentName,
    };
  }

  /// Deserializes model from database map or Firestore document.
  factory EquipmentReview.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return EquipmentReview(
      id: docId ?? (map['id']?.toString() ?? ''),
      equipmentId: (map['equipment_id']?.toString() ?? '').trim(),
      ownerId: (map['owner_id']?.toString() ?? 'owner_default').trim(),
      authorId: (map['author_id']?.toString() ?? 'guest_renter').trim(),
      authorName: (map['author_name']?.toString() ?? 'Verified Renter').trim(),
      rating: ((map['rating'] as num?)?.toInt() ?? 5).clamp(1, 5),
      comment: (map['comment']?.toString() ?? '').trim(),
      createdAt: parseDate(map['created_at']),
      updatedAt: map['updated_at'] != null ? parseDate(map['updated_at']) : null,
      rentalRequestId: map['rental_request_id']?.toString(),
      equipmentName: map['equipment_name']?.toString(),
    );
  }

  EquipmentReview copyWith({
    String? id,
    String? equipmentId,
    String? ownerId,
    String? authorId,
    String? authorName,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? rentalRequestId,
    String? equipmentName,
  }) {
    return EquipmentReview(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      ownerId: ownerId ?? this.ownerId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rentalRequestId: rentalRequestId ?? this.rentalRequestId,
      equipmentName: equipmentName ?? this.equipmentName,
    );
  }
}
