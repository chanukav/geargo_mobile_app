import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/payment_method.dart';

/// CRUD operations for payment methods stored at `users/{uid}/payment_methods`.
/// Enforces PCI safety: raw card numbers (PAN) and CVV codes are NEVER passed or stored.
class PaymentMethodService {
  PaymentMethodService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String? userId,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _explicitUserId = userId;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final String? _explicitUserId;

  String? get _uid => _explicitUserId ?? _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? _userPaymentMethodsCol() {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('payment_methods');
  }

  /// Streams saved payment methods for the authenticated user.
  /// Automatically sorts the default card first, followed by most recently added.
  Stream<List<PaymentMethod>> streamPaymentMethods() {
    final col = _userPaymentMethodsCol();
    if (col == null) return Stream.value(<PaymentMethod>[]);

    return col.snapshots().map((snap) {
      final now = DateTime.now();
      final list = snap.docs.map(PaymentMethod.fromDoc).toList();

      list.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return (b.createdAt ?? now).compareTo(a.createdAt ?? now);
      });

      return list;
    });
  }

  /// Fetches saved payment methods once.
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final col = _userPaymentMethodsCol();
    if (col == null) return <PaymentMethod>[];

    final snap = await col.get();
    final now = DateTime.now();
    final list = snap.docs.map(PaymentMethod.fromDoc).toList();

    list.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return (b.createdAt ?? now).compareTo(a.createdAt ?? now);
    });

    return list;
  }

  /// Gets the default saved payment method for the current user.
  Future<PaymentMethod?> getDefaultPaymentMethod() async {
    final methods = await getPaymentMethods();
    if (methods.isEmpty) return null;
    try {
      return methods.firstWhere((m) => m.isDefault);
    } catch (_) {
      return methods.first;
    }
  }

  /// Adds a new payment method storing ONLY the 7 safe fields.
  /// If it is the user's first card, it is automatically marked as default.
  Future<String> addPaymentMethod({
    required String brand,
    required String last4,
    required int expMonth,
    required int expYear,
    required String cardHolderName,
    bool? isDefault,
  }) async {
    final col = _userPaymentMethodsCol();
    if (col == null) {
      throw StateError('You must be signed in to save a payment method.');
    }

    final existing = await col.get();
    final bool shouldBeDefault = isDefault ?? existing.docs.isEmpty;

    if (shouldBeDefault && existing.docs.isNotEmpty) {
      final batch = _db.batch();
      for (final doc in existing.docs) {
        if ((doc.data()['isDefault'] as bool?) == true) {
          batch.update(doc.reference, {'isDefault': false});
        }
      }
      await batch.commit();
    }

    final docRef = await col.add({
      'brand': brand,
      'last4': last4,
      'expMonth': expMonth,
      'expYear': expYear,
      'cardHolderName': cardHolderName.trim(),
      'isDefault': shouldBeDefault,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Updates an existing card's mutable fields: card holder name and expiry.
  /// Card number and brand are immutable.
  Future<void> updatePaymentMethod({
    required String methodId,
    required String cardHolderName,
    required int expMonth,
    required int expYear,
    bool? isDefault,
  }) async {
    final col = _userPaymentMethodsCol();
    if (col == null) {
      throw StateError('You must be signed in to update a payment method.');
    }

    if (isDefault == true) {
      await setDefaultPaymentMethod(methodId);
    }

    await col.doc(methodId).update({
      'cardHolderName': cardHolderName.trim(),
      'expMonth': expMonth,
      'expYear': expYear,
    });
  }

  /// Atomically sets the given card as default and unsets all other cards.
  Future<void> setDefaultPaymentMethod(String methodId) async {
    final col = _userPaymentMethodsCol();
    if (col == null) {
      throw StateError('You must be signed in to set a default payment method.');
    }

    final snap = await col.get();
    final batch = _db.batch();

    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == methodId});
    }

    await batch.commit();
  }

  /// Deletes a payment method.
  /// If the deleted card was default and others remain, makes the most recent
  /// remaining card default.
  Future<void> deletePaymentMethod(String methodId) async {
    final col = _userPaymentMethodsCol();
    if (col == null) {
      throw StateError('You must be signed in to delete a payment method.');
    }

    final snap = await col.get();
    final targetDoc = snap.docs.where((d) => d.id == methodId).firstOrNull;
    final bool wasDefault = targetDoc != null && (targetDoc.data()['isDefault'] as bool?) == true;

    final remaining = snap.docs.where((d) => d.id != methodId).toList();

    final batch = _db.batch();
    batch.delete(col.doc(methodId));

    if (wasDefault && remaining.isNotEmpty) {
      // Sort remaining by createdAt descending to pick the most recent
      final now = DateTime.now();
      remaining.sort((a, b) {
        final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? now;
        final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? now;
        return bTime.compareTo(aTime);
      });

      batch.update(remaining.first.reference, {'isDefault': true});
    }

    await batch.commit();
  }
}
