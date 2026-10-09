import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/core/utils/product_validators.dart';

void main() {
  group('ProductValidators.requiredField', () {
    test('rejects null, empty, or whitespace-only values', () {
      expect(ProductValidators.requiredField(null), isNotNull);
      expect(ProductValidators.requiredField(''), isNotNull);
      expect(ProductValidators.requiredField('   '), isNotNull);
    });

    test('accepts non-empty text', () {
      expect(ProductValidators.requiredField('Trek Mountain Bike'), isNull);
      expect(ProductValidators.requiredField('Cricket Bat'), isNull);
    });
  });

  group('ProductValidators.money', () {
    test('rejects null, empty, or non-numeric strings', () {
      expect(ProductValidators.money(null), isNotNull);
      expect(ProductValidators.money(''), isNotNull);
      expect(ProductValidators.money('abc'), isNotNull);
      expect(ProductValidators.money('\$50'), isNotNull);
    });

    test('rejects negative numbers', () {
      expect(ProductValidators.money('-1'), isNotNull);
      expect(ProductValidators.money('-25.50'), isNotNull);
    });

    test('accepts zero and positive amounts', () {
      expect(ProductValidators.money('0'), isNull);
      expect(ProductValidators.money('0.00'), isNull);
      expect(ProductValidators.money('15.50'), isNull);
      expect(ProductValidators.money('120'), isNull);
    });
  });

  group('ProductValidators.quantity', () {
    test('rejects null, empty, or non-integer values', () {
      expect(ProductValidators.quantity(null), isNotNull);
      expect(ProductValidators.quantity(''), isNotNull);
      expect(ProductValidators.quantity('abc'), isNotNull);
      expect(ProductValidators.quantity('3.5'), isNotNull);
    });

    test('rejects negative numbers', () {
      expect(ProductValidators.quantity('-1'), isNotNull);
      expect(ProductValidators.quantity('-10'), isNotNull);
    });

    test('accepts zero and positive whole numbers', () {
      expect(ProductValidators.quantity('0'), isNull);
      expect(ProductValidators.quantity('1'), isNull);
      expect(ProductValidators.quantity('10'), isNull);
    });
  });
}
