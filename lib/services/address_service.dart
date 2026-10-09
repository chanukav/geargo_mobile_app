import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A delivery address saved by a user in Firestore at users/{uid}/addresses.
class UserAddress {
  const UserAddress({
    required this.id,
    required this.label,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String label;
  final String text;
  final DateTime? createdAt;

  factory UserAddress.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return UserAddress(
      id: doc.id,
      label: (d['label'] ?? '') as String,
      text: (d['text'] ?? '') as String,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// CRUD operations for delivery addresses saved in `users/{uid}/addresses`.
class AddressService {
  AddressService({
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

  CollectionReference<Map<String, dynamic>>? _userAddressesCol() {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('addresses');
  }

  /// Streams saved delivery addresses for the currently signed-in user.
  Stream<List<UserAddress>> streamAddresses() {
    final col = _userAddressesCol();
    if (col == null) return Stream.value(<UserAddress>[]);
    return col.snapshots().map((snap) {
      final now = DateTime.now();
      final list = snap.docs.map(UserAddress.fromDoc).toList();
      // Sorted in memory so no Firestore composite index is required.
      list.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
      return list;
    });
  }

  /// Adds a new delivery address to users/{uid}/addresses.
  Future<String> addAddress({
    required String label,
    required String text,
  }) async {
    final col = _userAddressesCol();
    if (col == null) {
      throw Exception('You must be signed in to save an address.');
    }
    final doc = await col.add({
      'label': label,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Deletes a saved address from users/{uid}/addresses.
  Future<void> deleteAddress(String id) async {
    final col = _userAddressesCol();
    if (col == null) {
      throw Exception('You must be signed in to delete an address.');
    }
    await col.doc(id).delete();
  }
}
