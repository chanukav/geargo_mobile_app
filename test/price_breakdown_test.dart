import 'dart:math' as math;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/models/rental_transaction.dart';
import 'package:geargo/models/shop_product.dart';

void main() {
  group('PriceBreakdown.calculate & Date Days', () {
    test('scenario 1: pickup (no delivery fee), 1 day', () {
      final pb = PriceBreakdown.calculate(
        pricePerDay: 50.0,
        days: 1,
        deposit: 100.0,
        delivery: false,
      );

      expect(pb.rentalFee, 50.0);
      expect(pb.serviceFee, 4.0); // 8% of $50
      expect(pb.deliveryFee, 0.0);
      expect(pb.deposit, 100.0);
      expect(pb.dueNow, 54.0); // 50 + 4 + 0
      expect(pb.total, 154.0); // 54 + 100
    });

    test('scenario 2: delivery, 1 day', () {
      final pb = PriceBreakdown.calculate(
        pricePerDay: 50.0,
        days: 1,
        deposit: 100.0,
        delivery: true,
      );

      expect(pb.rentalFee, 50.0);
      expect(pb.serviceFee, 4.0); // 8% of $50
      expect(pb.deliveryFee, 15.0); // flat $15 delivery fee
      expect(pb.deposit, 100.0);
      expect(pb.dueNow, 69.0); // 50 + 4 + 15
      expect(pb.total, 169.0); // 69 + 100
    });

    test('scenario 3: pickup (no delivery fee), 4 days', () {
      final pb = PriceBreakdown.calculate(
        pricePerDay: 40.0,
        days: 4,
        deposit: 80.0,
        delivery: false,
      );

      expect(pb.rentalFee, 160.0); // 40 * 4
      expect(pb.serviceFee, 12.80); // 8% of $160
      expect(pb.deliveryFee, 0.0);
      expect(pb.deposit, 80.0);
      expect(pb.dueNow, 172.80); // 160 + 12.80 + 0
      expect(pb.total, 252.80); // 172.80 + 80
    });

    test('scenario 4: delivery, 4 days', () {
      final pb = PriceBreakdown.calculate(
        pricePerDay: 40.0,
        days: 4,
        deposit: 80.0,
        delivery: true,
      );

      expect(pb.rentalFee, 160.0); // 40 * 4
      expect(pb.serviceFee, 12.80); // 8% of $160
      expect(pb.deliveryFee, 15.0); // flat $15 delivery fee
      expect(pb.deposit, 80.0);
      expect(pb.dueNow, 187.80); // 160 + 12.80 + 15
      expect(pb.total, 267.80); // 187.80 + 80
    });

    test('date day difference calculation logic', () {
      final start = DateTime(2026, 10, 10);
      final end4Days = DateTime(2026, 10, 14);
      final days = math.max(1, end4Days.difference(start).inDays);
      expect(days, 4);

      // Same day selection falls back to 1 day minimum
      final sameDay = DateTime(2026, 10, 10);
      final singleDay = math.max(1, sameDay.difference(start).inDays);
      expect(singleDay, 1);
    });
  });

  group('ShopProduct Model Serialization', () {
    test('toMap produces correct editable map fields', () {
      const product = ShopProduct(
        id: 'p123',
        ownerId: 'owner456',
        name: 'Trek Marlin 7',
        category: 'Mountain Bikes',
        description: 'Hardtail trail mountain bike',
        condition: 'Excellent',
        pricePerDay: 45.0,
        deposit: 150.0,
        quantity: 3,
        isAvailable: true,
        imageUrl: 'https://example.com/bike.jpg',
      );

      final map = product.toMap();
      expect(map['name'], 'Trek Marlin 7');
      expect(map['category'], 'Mountain Bikes');
      expect(map['condition'], 'Excellent');
      expect(map['pricePerDay'], 45.0);
      expect(map['deposit'], 150.0);
      expect(map['quantity'], 3);
      expect(map['isAvailable'], true);
      expect(map['imageUrl'], 'https://example.com/bike.jpg');
    });

    test('fromDoc deserializes document fields properly', () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = await firestore.collection('shop_products').add({
        'ownerId': 'owner999',
        'name': 'Kookaburra Cricket Bat',
        'category': 'Cricket',
        'description': 'Grade 1 English willow',
        'condition': 'Good',
        'pricePerDay': 25.0,
        'deposit': 60.0,
        'quantity': 2,
        'isAvailable': true,
        'imageUrl': '',
      });

      final docSnap = await docRef.get();
      final model = ShopProduct.fromDoc(docSnap);

      expect(model.id, docRef.id);
      expect(model.ownerId, 'owner999');
      expect(model.name, 'Kookaburra Cricket Bat');
      expect(model.category, 'Cricket');
      expect(model.pricePerDay, 25.0);
      expect(model.deposit, 60.0);
      expect(model.quantity, 2);
      expect(model.isAvailable, true);
    });
  });

  group('RentalTransaction Model Serialization', () {
    test('fromDoc deserializes transaction fields and calculates dueNow', () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = await firestore.collection('rental_transactions').add({
        'bookingRef': 'GG-4521-12',
        'renterId': 'renter001',
        'shopId': 'shop002',
        'productId': 'prod003',
        'productName': 'Speedo Goggles',
        'startDate': DateTime(2026, 10, 10),
        'endDate': DateTime(2026, 10, 12),
        'days': 2,
        'fulfillment': 'delivery',
        'deliveryAddress': '123 Beach Rd',
        'deliveryInstructions': 'Ring bell',
        'deliveryWindow': 'Morning (9 AM - 12 PM)',
        'rentalFee': 20.0,
        'serviceFee': 1.6,
        'deliveryFee': 15.0,
        'deposit': 10.0,
        'dueNow': 36.6,
        'total': 46.6,
        'paymentMethod': 'Visa ending in 4242',
        'paymentStatus': 'paid',
        'status': 'confirmed',
      });

      final docSnap = await docRef.get();
      final txn = RentalTransaction.fromDoc(docSnap);

      expect(txn.bookingRef, 'GG-4521-12');
      expect(txn.renterId, 'renter001');
      expect(txn.shopId, 'shop002');
      expect(txn.days, 2);
      expect(txn.isDelivery, true);
      expect(txn.deliveryAddress, '123 Beach Rd');
      expect(txn.dueNow, 36.6);
      expect(txn.deposit, 10.0);
      expect(txn.total, 46.6);
      expect(txn.breakdown.rentalFee, 20.0);
      expect(txn.breakdown.dueNow, 36.6);
    });
  });
}
