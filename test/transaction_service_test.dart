import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/models/shop_product.dart';
import 'package:geargo/services/transaction_service.dart';

void main() {
  group('TransactionService CRUD & Stock Transactions with fake_cloud_firestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    late TransactionService renterService;
    const testRenterId = 'renter-user-001';
    const testShopId = 'shop-owner-002';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      renterService = TransactionService(
        firestore: fakeFirestore,
        userId: testRenterId,
      );
    });

    test('CREATE: createBooking creates record and atomically decrements product stock', () async {
      // Setup product with quantity 2
      final prodDoc = await fakeFirestore.collection('shop_products').add({
        'name': 'Giant Mountain Bike',
        'ownerId': testShopId,
        'category': 'Mountain Bikes',
        'description': 'Hydraulic disc brakes',
        'condition': 'Excellent',
        'pricePerDay': 40.0,
        'deposit': 100.0,
        'quantity': 2,
        'isAvailable': true,
      });

      final product = ShopProduct.fromDoc(await prodDoc.get());
      final start = DateTime(2026, 10, 10);
      final end = DateTime(2026, 10, 13); // 3 days

      final txn = await renterService.createBooking(
        product: product,
        start: start,
        end: end,
        delivery: true,
        address: '45 Sunset Blvd',
        instructions: 'Gate code 1234',
        window: 'Morning (9 AM - 12 PM)',
        paymentMethod: 'Visa ending in 4242',
      );

      // Verify transaction properties
      expect(txn.renterId, testRenterId);
      expect(txn.shopId, testShopId);
      expect(txn.days, 3);
      expect(txn.rentalFee, 120.0); // 40 * 3
      expect(txn.serviceFee, 9.60); // 8% of 120
      expect(txn.deliveryFee, 15.0);
      expect(txn.deposit, 100.0);
      expect(txn.dueNow, 144.60); // 120 + 9.6 + 15
      expect(txn.status, 'confirmed');

      // Verify stock decrement in shop_products
      final updatedProductSnap = await prodDoc.get();
      expect(updatedProductSnap.data()?['quantity'], 1);
      expect(updatedProductSnap.data()?['isAvailable'], true);
    });

    test('CREATE: rejects booking if equipment quantity is 0 (out of stock)', () async {
      final prodDoc = await fakeFirestore.collection('shop_products').add({
        'name': 'Cricket Helmet',
        'ownerId': testShopId,
        'category': 'Cricket',
        'description': '',
        'condition': 'Good',
        'pricePerDay': 15.0,
        'deposit': 30.0,
        'quantity': 0,
        'isAvailable': false,
      });

      final product = ShopProduct.fromDoc(await prodDoc.get());
      final start = DateTime(2026, 10, 10);
      final end = DateTime(2026, 10, 11);

      expect(
        () => renterService.createBooking(
          product: product,
          start: start,
          end: end,
          delivery: false,
          address: '',
          instructions: '',
          window: '',
          paymentMethod: 'Mobile wallet',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('CREATE: rejects owner attempting to rent own equipment listing', () async {
      final prodDoc = await fakeFirestore.collection('shop_products').add({
        'name': 'My Own Racket',
        'ownerId': testRenterId, // Same as signed-in user
        'category': 'Racket Sports',
        'description': '',
        'condition': 'Good',
        'pricePerDay': 20.0,
        'deposit': 50.0,
        'quantity': 1,
        'isAvailable': true,
      });

      final product = ShopProduct.fromDoc(await prodDoc.get());
      expect(
        () => renterService.createBooking(
          product: product,
          start: DateTime.now(),
          end: DateTime.now().add(const Duration(days: 2)),
          delivery: false,
          address: '',
          instructions: '',
          window: '',
          paymentMethod: 'Visa',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('READ: streamMyBookings and streamShopOrders filter by respective role', () async {
      await fakeFirestore.collection('rental_transactions').add({
        'bookingRef': 'GG-1111-11',
        'renterId': testRenterId,
        'shopId': testShopId,
        'productName': 'Surfboard',
        'status': 'confirmed',
      });

      final myBookings = await renterService.streamMyBookings().first;
      expect(myBookings.length, 1);
      expect(myBookings.first.productName, 'Surfboard');

      final shopService = TransactionService(
        firestore: fakeFirestore,
        userId: testShopId,
      );
      final shopOrders = await shopService.streamShopOrders().first;
      expect(shopOrders.length, 1);
      expect(shopOrders.first.productName, 'Surfboard');
    });

    test('UPDATE: updateDelivery updates address and window', () async {
      final docRef = await fakeFirestore.collection('rental_transactions').add({
        'bookingRef': 'GG-2222-22',
        'renterId': testRenterId,
        'shopId': testShopId,
        'deliveryAddress': 'Old Address',
        'deliveryInstructions': '',
        'deliveryWindow': 'Morning (9 AM - 12 PM)',
        'status': 'confirmed',
      });

      await renterService.updateDelivery(
        id: docRef.id,
        address: 'New Villa, Street 9',
        instructions: 'Leave with reception',
        window: 'Evening (5 PM - 8 PM)',
      );

      final snap = await docRef.get();
      expect(snap.data()?['deliveryAddress'], 'New Villa, Street 9');
      expect(snap.data()?['deliveryInstructions'], 'Leave with reception');
      expect(snap.data()?['deliveryWindow'], 'Evening (5 PM - 8 PM)');
    });

    test('UPDATE: completeBooking marks completed and refunds deposit', () async {
      final docRef = await fakeFirestore.collection('rental_transactions').add({
        'bookingRef': 'GG-3333-33',
        'status': 'confirmed',
        'paymentStatus': 'paid',
      });

      await renterService.completeBooking(docRef.id);

      final snap = await docRef.get();
      expect(snap.data()?['status'], 'completed');
      expect(snap.data()?['paymentStatus'], 'deposit_refunded');
    });

    test('UPDATE: cancelBooking cancels order and restores product stock quantity', () async {
      // Product initially has 1 in stock
      final prodDoc = await fakeFirestore.collection('shop_products').add({
        'name': 'Football Boots',
        'ownerId': testShopId,
        'quantity': 1,
        'isAvailable': true,
      });

      final txnDoc = await fakeFirestore.collection('rental_transactions').add({
        'bookingRef': 'GG-4444-44',
        'productId': prodDoc.id,
        'status': 'confirmed',
        'paymentStatus': 'paid',
      });

      await renterService.cancelBooking(txnDoc.id);

      // Booking updated
      final txnSnap = await txnDoc.get();
      expect(txnSnap.data()?['status'], 'cancelled');
      expect(txnSnap.data()?['paymentStatus'], 'refunded');

      // Product quantity restored from 1 to 2
      final prodSnap = await prodDoc.get();
      expect(prodSnap.data()?['quantity'], 2);
      expect(prodSnap.data()?['isAvailable'], true);
    });

    test('DELETE: deleteBooking deletes the booking document', () async {
      final docRef = await fakeFirestore.collection('rental_transactions').add({
        'bookingRef': 'GG-5555-55',
        'status': 'cancelled',
      });

      await renterService.deleteBooking(docRef.id);

      final snap = await docRef.get();
      expect(snap.exists, false);
    });
  });
}
