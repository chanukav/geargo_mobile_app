import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/models/rental_transaction.dart';

void main() {
  group('PriceBreakdown.calculate', () {
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
  });
}
