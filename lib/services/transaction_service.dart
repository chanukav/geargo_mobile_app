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
    if (product.ownerId == uid) {
      throw Exception('You cannot rent your own equipment listing.');
    }

    // ---------------- DOUBLE BOOKING CHECK ----------------
    // Query by productId ONLY to ensure no Firestore composite index is needed.
    // Filter status and date range overlaps in Dart.
    //
    // RACE CONDITION LIMITATION NOTE:
    // This client-side check queries existing bookings prior to document creation.
    // Under concurrent bookings for the last available item, two users could both
    // evaluate overlaps < product.quantity at the same time and both proceed to write.
    // In production, an atomic Firestore transaction or Cloud Function with server-side
    // locks/counters should be used to eliminate this race condition.
    final existingSnap = await _col
        .where('productId', isEqualTo: product.id)
        .get();

    int overlaps = 0;
    for (final doc in existingSnap.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '') as String;
      if (status != 'confirmed') continue;

      final existingStart = (data['startDate'] as Timestamp?)?.toDate();
      final existingEnd = (data['endDate'] as Timestamp?)?.toDate();
      if (existingStart != null && existingEnd != null) {
        // Two date ranges overlap if requested start is before existing end
        // and requested end is after existing start.
        if (start.isBefore(existingEnd) && end.isAfter(existingStart)) {
          overlaps++;
        }
      }
    }

    if (overlaps >= product.quantity) {
      throw Exception(
        'This equipment is fully booked for the selected dates. Please choose different dates.',
      );
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
      'dueNow': price.dueNow,
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
