import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/shop_product.dart';

/// CRUD for the `products` collection (Shop/ShopProduct Management).
class ShopProductService {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('shop_products');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ---------------- CREATE ----------------
  Future<void> addProduct(ShopProduct p) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('You must be signed in to add equipment.');
    }
    await _col.add({
      ...p.toMap(),
      'ownerId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------- READ ----------------
  /// Products owned by the signed-in shop (newest first).
  Stream<List<ShopProduct>> streamMyProducts() {
    final uid = _uid;
    if (uid == null) return Stream.value(<ShopProduct>[]);
    return _col.where('ownerId', isEqualTo: uid).snapshots().map(_toSortedList);
  }

  /// All products currently available to rent (used by the booking flow).
  Stream<List<ShopProduct>> streamAvailableProducts() {
    return _col
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map(_toSortedList);
  }

  List<ShopProduct> _toSortedList(QuerySnapshot<Map<String, dynamic>> snap) {
    final now = DateTime.now();
    final list = snap.docs.map(ShopProduct.fromDoc).toList();
    // Sorted in memory so no Firestore composite index is required.
    list.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
    return list;
  }

  // ---------------- UPDATE ----------------
  Future<void> updateProduct(ShopProduct p) {
    return _col.doc(p.id).update({
      ...p.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setAvailability(String id, bool available) {
    return _col.doc(id).update({'isAvailable': available});
  }

  // ---------------- DELETE ----------------
  Future<void> deleteProduct(String id) => _col.doc(id).delete();
}
