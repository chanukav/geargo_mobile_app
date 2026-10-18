import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/models/payment_method.dart';

void main() {
  group('PaymentMethod Model', () {
    test('instantiates with required fields and formats getters correctly', () {
      final card = PaymentMethod(
        id: 'pm-123',
        brand: 'Visa',
        last4: '4242',
        expMonth: 9,
        expYear: 2028,
        cardHolderName: 'Maya Fernando',
        isDefault: true,
        createdAt: DateTime(2026, 10, 18),
      );

      expect(card.id, 'pm-123');
      expect(card.brand, 'Visa');
      expect(card.last4, '4242');
      expect(card.displayTitle, 'Visa •••• 4242');
      expect(card.formattedExpiry, '09/28');
      expect(card.isDefault, isTrue);
      expect(card.isExpired, isFalse);
    });

    test('isExpired detects past expiration dates accurately', () {
      final expiredCard = PaymentMethod(
        id: 'pm-old',
        brand: 'Mastercard',
        last4: '5100',
        expMonth: 1,
        expYear: 2020,
        cardHolderName: 'Test User',
      );

      expect(expiredCard.isExpired, isTrue);
    });

    test('toMap strictly includes only the 7 safe fields matching firestore.rules', () {
      final card = PaymentMethod(
        id: 'pm-safe',
        brand: 'Visa',
        last4: '4242',
        expMonth: 12,
        expYear: 2029,
        cardHolderName: 'Elena Rostova',
        isDefault: false,
        createdAt: DateTime(2026, 10, 1),
      );

      final map = card.toMap();

      // Enforces firestore.rules whitelist:
      // request.resource.data.keys().hasOnly(['brand','last4','expMonth','expYear','cardHolderName','isDefault','createdAt'])
      final allowedKeys = {
        'brand',
        'last4',
        'expMonth',
        'expYear',
        'cardHolderName',
        'isDefault',
        'createdAt',
      };

      expect(map.keys.toSet(), allowedKeys);
      expect(map['brand'], 'Visa');
      expect(map['last4'], '4242');
      expect((map['last4'] as String).length, 4);
      expect(map['cardHolderName'], 'Elena Rostova');
      expect(map['isDefault'], isFalse);

      // Verify no sensitive keys leaked
      expect(map.containsKey('cardNumber'), isFalse);
      expect(map.containsKey('pan'), isFalse);
      expect(map.containsKey('cvv'), isFalse);
      expect(map.containsKey('cvc'), isFalse);
    });

    test('fromMap deserializes accurately', () {
      final map = {
        'brand': 'American Express',
        'last4': '0005',
        'expMonth': 4,
        'expYear': 2027,
        'cardHolderName': 'Amex Holder',
        'isDefault': true,
        'createdAt': '2026-10-18T00:00:00.000',
      };

      final card = PaymentMethod.fromMap('pm-amex', map);

      expect(card.id, 'pm-amex');
      expect(card.brand, 'American Express');
      expect(card.last4, '0005');
      expect(card.displayTitle, 'American Express •••• 0005');
      expect(card.formattedExpiry, '04/27');
      expect(card.cardHolderName, 'Amex Holder');
      expect(card.isDefault, isTrue);
    });
  });
}
