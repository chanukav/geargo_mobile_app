import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/shop_product.dart';
import '../models/rental_transaction.dart';

/// CRUD for the `transactions` collection (Transaction/Payment Management).
/// Payment is simulated: no real gateway is called, the record is stored as paid.
class TransactionService {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('rental_transactions');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ---------------- CREATE ----------------
  Future<RentalTransaction> createBooking({
    required ShopProduct product,
    required DateTime start,
    required DateTime end,
    required bool delivery,
    required String address,
    required String instructions,
    required String window,
    required String paymentMethod,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('You must be signed in to book equipment.');
    }
    final days = math.max(1, end.difference(start).inDays);
    final price = PriceBreakdown.calculate(
      pricePerDay: product.pricePerDay,
      days: days,
      deposit: product.deposit,
      delivery: delivery,
    );
    final rand = math.Random();
    final ref = 'GG-${1000 + rand.nextInt(9000)}-${10 + rand.nextInt(90)}';

    final doc = await _col.add({
      'bookingRef': ref,
      'renterId': uid,
      'shopId': product.ownerId,
      'productId': product.id,
      'productName': product.name,
      'startDate': Timestamp.fromDate(start),
      'endDate': Timestamp.fromDate(end),
      'days': days,
      'fulfillment': delivery ? 'delivery' : 'pickup',
      'deliveryAddress': delivery ? address : '',
      'deliveryInstructions': delivery ? instructions : '',
      'deliveryWindow': delivery ? window : '',
      'rentalFee': price.rentalFee,
      'serviceFee': price.serviceFee,
      'deliveryFee': price.deliveryFee,
      'deposit': price.deposit,
      'total': price.total,
      'paymentMethod': paymentMethod,
      'paymentStatus': 'paid',
      'status': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return RentalTransaction.fromDoc(await doc.get());
  }

  // ---------------- READ ----------------
  /// Bookings made by the signed-in user as a renter.
  Stream<List<RentalTransaction>> streamMyBookings() => _stream('renterId');

  /// Orders received by the signed-in user as a shop.
  Stream<List<RentalTransaction>> streamShopOrders() => _stream('shopId');

  Stream<List<RentalTransaction>> _stream(String field) {
    final uid = _uid;
    if (uid == null) return Stream.value(<RentalTransaction>[]);
    return _col.where(field, isEqualTo: uid).snapshots().map((snap) {
      final now = DateTime.now();
      final list = snap.docs.map(RentalTransaction.fromDoc).toList();
      list.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
      return list;
    });
  }

  // ---------------- UPDATE ----------------
  Future<void> updateDelivery({
    required String id,
    required String address,
    required String instructions,
    required String window,
  }) {
    return _col.doc(id).update({
      'deliveryAddress': address,
      'deliveryInstructions': instructions,
      'deliveryWindow': window,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Shop marks the rental as returned; the deposit is released.
  Future<void> completeBooking(String id) {
    return _col.doc(id).update({
      'status': 'completed',
      'paymentStatus': 'deposit_refunded',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cancels a booking and marks the payment as refunded.
  Future<void> cancelBooking(String id) {
    return _col.doc(id).update({
      'status': 'cancelled',
      'paymentStatus': 'refunded',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------- DELETE ----------------
  /// Removes a booking record (used for cancelled bookings).
  Future<void> deleteBooking(String id) => _col.doc(id).delete();
}
