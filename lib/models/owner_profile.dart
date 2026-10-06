import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model for Owner Profile.
///
/// Database table schema: owner_profile
/// -------------------------
/// id             String (document ID)
/// user_id        String (Firebase Auth UID)
/// name           String (full display name)
/// phone          String (contact number)
/// address        String (physical / service address)
/// profile_image  String (URL, base64 data URI, or empty)
/// business_name  String (optional business / trade name)
/// created_at     DateTime
/// updated_at     DateTime
class OwnerProfile {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String address;
  final String profileImage;
  final String businessName;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Extra UX enrichment fields (persisted, with sensible defaults)
  final String bio;
  final String website;
  final bool isVerified;
  final bool isActive; // false = deactivated

  const OwnerProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.address,
    required this.profileImage,
    required this.businessName,
    required this.createdAt,
    required this.updatedAt,
    this.bio = '',
    this.website = '',
    this.isVerified = false,
    this.isActive = true,
  });

  /// Initials fallback for avatar widgets.
  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// Whether the profile has been filled in beyond defaults.
  bool get isComplete =>
      name.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      address.trim().isNotEmpty;

  /// Serialises to Firestore / database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'address': address,
      'profile_image': profileImage,
      'business_name': businessName,
      'bio': bio,
      'website': website,
      'is_verified': isVerified,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Deserialises from a Firestore document or plain map.
  factory OwnerProfile.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    bool parseBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      return defaultValue;
    }

    return OwnerProfile(
      id: (docId != null && docId.isNotEmpty)
          ? docId
          : (map['id']?.toString() ?? ''),
      userId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      profileImage: map['profile_image']?.toString() ?? '',
      businessName: map['business_name']?.toString() ?? '',
      bio: map['bio']?.toString() ?? '',
      website: map['website']?.toString() ?? '',
      isVerified: parseBool(map['is_verified']),
      isActive: parseBool(map['is_active'], defaultValue: true),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  /// Returns a copy with optional field overrides.
  OwnerProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? address,
    String? profileImage,
    String? businessName,
    String? bio,
    String? website,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OwnerProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      businessName: businessName ?? this.businessName,
      bio: bio ?? this.bio,
      website: website ?? this.website,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates a blank skeleton profile for a given user.
  factory OwnerProfile.blank(String userId) {
    final now = DateTime.now();
    return OwnerProfile(
      id: userId, // use userId as document ID for easy lookup
      userId: userId,
      name: '',
      phone: '',
      address: '',
      profileImage: '',
      businessName: '',
      createdAt: now,
      updatedAt: now,
    );
  }
}
