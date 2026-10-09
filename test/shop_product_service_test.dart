import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/models/shop_product.dart';
import 'package:geargo/services/shop_product_service.dart';

void main() {
  group('ShopProductService CRUD with fake_cloud_firestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ShopProductService service;
    const testOwnerId = 'shop-owner-101';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = ShopProductService(
        firestore: fakeFirestore,
        userId: testOwnerId,
      );
    });

    test('CREATE: addProduct stores equipment in shop_products collection', () async {
      const p = ShopProduct(
        id: '',
        ownerId: '',
        name: 'Wilson Tennis Racket',
        category: 'Racket Sports',
        description: 'Pro staff carbon racket',
        condition: 'Excellent',
        pricePerDay: 30.0,
        deposit: 70.0,
        quantity: 5,
        isAvailable: true,
      );

      await service.addProduct(p);

      final snap = await fakeFirestore.collection('shop_products').get();
      expect(snap.docs.length, 1);

      final saved = snap.docs.first.data();
      expect(saved['name'], 'Wilson Tennis Racket');
      expect(saved['ownerId'], testOwnerId);
      expect(saved['pricePerDay'], 30.0);
      expect(saved['quantity'], 5);
      expect(saved['isAvailable'], true);
    });

    test('READ: streamMyProducts filters products by ownerId', () async {
      // Add product belonging to test owner
      await fakeFirestore.collection('shop_products').add({
        'name': 'Item A',
        'ownerId': testOwnerId,
        'category': 'Gym',
        'description': '',
        'condition': 'Good',
        'pricePerDay': 15.0,
        'deposit': 40.0,
        'quantity': 2,
        'isAvailable': true,
      });

      // Add product belonging to another owner
      await fakeFirestore.collection('shop_products').add({
        'name': 'Item B',
        'ownerId': 'other-owner-202',
        'category': 'Gym',
        'description': '',
        'condition': 'Good',
        'pricePerDay': 20.0,
        'deposit': 50.0,
        'quantity': 1,
        'isAvailable': true,
      });

      final myProducts = await service.streamMyProducts().first;
      expect(myProducts.length, 1);
      expect(myProducts.first.name, 'Item A');
      expect(myProducts.first.ownerId, testOwnerId);
    });

    test('READ: streamAvailableProducts filters only available equipment', () async {
      await fakeFirestore.collection('shop_products').add({
        'name': 'Available Bike',
        'ownerId': testOwnerId,
        'category': 'Mountain Bikes',
        'description': '',
        'condition': 'Excellent',
        'pricePerDay': 50.0,
        'deposit': 100.0,
        'quantity': 3,
        'isAvailable': true,
      });

      await fakeFirestore.collection('shop_products').add({
        'name': 'Unavailable Kayak',
        'ownerId': testOwnerId,
        'category': 'Water Sports',
        'description': '',
        'condition': 'Fair',
        'pricePerDay': 60.0,
        'deposit': 150.0,
        'quantity': 0,
        'isAvailable': false,
      });

      final available = await service.streamAvailableProducts().first;
      expect(available.length, 1);
      expect(available.first.name, 'Available Bike');
      expect(available.first.isAvailable, true);
    });

    test('UPDATE: updateProduct updates editable equipment fields', () async {
      final docRef = await fakeFirestore.collection('shop_products').add({
        'name': 'Initial Name',
        'ownerId': testOwnerId,
        'category': 'Football',
        'description': 'Match ball',
        'condition': 'Good',
        'pricePerDay': 10.0,
        'deposit': 20.0,
        'quantity': 4,
        'isAvailable': true,
      });

      final updatedModel = ShopProduct(
        id: docRef.id,
        ownerId: testOwnerId,
        name: 'Updated FIFA Ball',
        category: 'Football',
        description: 'Official match ball size 5',
        condition: 'Excellent',
        pricePerDay: 12.0,
        deposit: 25.0,
        quantity: 8,
        isAvailable: true,
      );

      await service.updateProduct(updatedModel);

      final snap = await docRef.get();
      expect(snap.data()?['name'], 'Updated FIFA Ball');
      expect(snap.data()?['pricePerDay'], 12.0);
      expect(snap.data()?['quantity'], 8);
      expect(snap.data()?['condition'], 'Excellent');
    });

    test('UPDATE: setAvailability toggles isAvailable boolean', () async {
      final docRef = await fakeFirestore.collection('shop_products').add({
        'name': 'Camping Tent',
        'ownerId': testOwnerId,
        'category': 'Camping',
        'description': '',
        'condition': 'Good',
        'pricePerDay': 40.0,
        'deposit': 90.0,
        'quantity': 2,
        'isAvailable': true,
      });

      await service.setAvailability(docRef.id, false);

      final snap = await docRef.get();
      expect(snap.data()?['isAvailable'], false);
    });

    test('DELETE: deleteProduct deletes the equipment document', () async {
      final docRef = await fakeFirestore.collection('shop_products').add({
        'name': 'Old Dumbbells',
        'ownerId': testOwnerId,
        'category': 'Gym',
        'description': '',
        'condition': 'Fair',
        'pricePerDay': 8.0,
        'deposit': 15.0,
        'quantity': 1,
        'isAvailable': true,
      });

      await service.deleteProduct(docRef.id);

      final snap = await docRef.get();
      expect(snap.exists, false);
    });
  });
}
