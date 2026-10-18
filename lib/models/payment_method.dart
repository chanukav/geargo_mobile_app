import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment method stored in Firestore at `users/{uid}/payment_methods/{methodId}`.
/// Strictly holds only masked, PCI-safe metadata (no PAN, no CVV).
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.cardHolderName,
    this.isDefault = false,
    this.createdAt,
  });

  final String id;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final String cardHolderName;
  final bool isDefault;
  final DateTime? createdAt;

  /// Formatted title (e.g., "Visa •••• 4242").
  String get displayTitle => '$brand •••• $last4';

  /// Formatted expiry (e.g., "09/28").
  String get formattedExpiry {
    final m = expMonth.toString().padLeft(2, '0');
    final y = (expYear % 100).toString().padLeft(2, '0');
    return '$m/$y';
  }

  /// Whether the card's expiration date has passed.
  bool get isExpired {
    final expiryEndOfMonth = DateTime(expYear, expMonth + 1, 0, 23, 59, 59);
    return expiryEndOfMonth.isBefore(DateTime.now());
  }

  /// Deserializes a Firestore document snapshot.
  factory PaymentMethod.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return PaymentMethod(
      id: doc.id,
      brand: (d['brand'] ?? 'Other') as String,
      last4: (d['last4'] ?? '0000') as String,
      expMonth: (d['expMonth'] as num?)?.toInt() ?? 1,
      expYear: (d['expYear'] as num?)?.toInt() ?? 2026,
      cardHolderName: (d['cardHolderName'] ?? '') as String,
      isDefault: (d['isDefault'] ?? false) as bool,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Deserializes from a map.
  factory PaymentMethod.fromMap(String id, Map<String, dynamic> d) {
    return PaymentMethod(
      id: id,
      brand: (d['brand'] ?? 'Other') as String,
      last4: (d['last4'] ?? '0000') as String,
      expMonth: (d['expMonth'] as num?)?.toInt() ?? 1,
      expYear: (d['expYear'] as num?)?.toInt() ?? 2026,
      cardHolderName: (d['cardHolderName'] ?? '') as String,
      isDefault: (d['isDefault'] ?? false) as bool,
      createdAt: d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate()
          : (d['createdAt'] is String ? DateTime.tryParse(d['createdAt'] as String) : null),
    );
  }

  /// Serializes into the 7 safe fields strictly permitted by firestore.rules:
  /// ['brand','last4','expMonth','expYear','cardHolderName','isDefault','createdAt']
  Map<String, dynamic> toMap({bool useServerTimestamp = false}) {
    return {
      'brand': brand,
      'last4': last4,
      'expMonth': expMonth,
      'expYear': expYear,
      'cardHolderName': cardHolderName,
      'isDefault': isDefault,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : (createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp()),
    };
  }

  PaymentMethod copyWith({
    String? id,
    String? brand,
    String? last4,
    int? expMonth,
    int? expYear,
    String? cardHolderName,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      last4: last4 ?? this.last4,
      expMonth: expMonth ?? this.expMonth,
      expYear: expYear ?? this.expYear,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
