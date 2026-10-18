import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/core/utils/card_utils.dart';

void main() {
  group('CardUtils - Brand Detection', () {
    test('detects Visa correctly', () {
      expect(CardUtils.detectBrand('4242 4242 4242 4242'), CardBrand.visa);
      expect(CardUtils.detectBrand('4000000000000'), CardBrand.visa);
    });

    test('detects Mastercard correctly', () {
      expect(CardUtils.detectBrand('5105 1051 0510 5100'), CardBrand.mastercard);
      expect(CardUtils.detectBrand('5555 5555 5555 4444'), CardBrand.mastercard);
      expect(CardUtils.detectBrand('2221 0000 0000 0000'), CardBrand.mastercard);
    });

    test('detects American Express correctly', () {
      expect(CardUtils.detectBrand('3782 822463 10005'), CardBrand.amex);
      expect(CardUtils.detectBrand('3400 000000 00000'), CardBrand.amex);
    });

    test('detects Other correctly', () {
      expect(CardUtils.detectBrand('6011 0000 0000 0000'), CardBrand.other);
      expect(CardUtils.detectBrand(''), CardBrand.other);
    });
  });

  group('CardUtils - Luhn Algorithm', () {
    test('validates standard valid test card numbers', () {
      // 4242 4242 4242 4242 is standard test card
      expect(CardUtils.isValidLuhn('4242 4242 4242 4242'), isTrue);
      // Valid Amex test card
      expect(CardUtils.isValidLuhn('3782 822463 10005'), isTrue);
    });

    test('rejects card numbers with invalid checksum', () {
      expect(CardUtils.isValidLuhn('4242 4242 4242 4241'), isFalse);
      expect(CardUtils.isValidLuhn('1234 5678 9012 3456'), isFalse);
    });

    test('rejects card numbers with invalid lengths', () {
      expect(CardUtils.isValidLuhn('12345'), isFalse);
      expect(CardUtils.isValidLuhn('4242'), isFalse);
    });
  });

  group('CardUtils - Length Validation', () {
    test('validates lengths per brand', () {
      expect(CardUtils.hasValidLength('4242 4242 4242 4242'), isTrue); // Visa 16
      expect(CardUtils.hasValidLength('4242 4242 4242'), isFalse); // Visa 12
      expect(CardUtils.hasValidLength('3782 822463 10005'), isTrue); // Amex 15
      expect(CardUtils.hasValidLength('3782 822463 100055'), isFalse); // Amex 16
    });
  });

  group('CardUtils - Expiry Validation', () {
    test('accepts valid future expiry dates', () {
      expect(CardUtils.validateExpiry('12/28'), isNull);
      expect(CardUtils.validateExpiry('06/30'), isNull);
    });

    test('rejects expired dates', () {
      expect(CardUtils.validateExpiry('01/20'), 'Card has expired');
      expect(CardUtils.validateExpiry('12/23'), 'Card has expired');
    });

    test('rejects invalid month numbers', () {
      expect(CardUtils.validateExpiry('13/28'), 'Invalid month (01-12)');
      expect(CardUtils.validateExpiry('00/28'), 'Invalid month (01-12)');
    });

    test('rejects malformed inputs', () {
      expect(CardUtils.validateExpiry(''), 'Expiry date is required');
      expect(CardUtils.validateExpiry('12'), 'Use MM/YY format');
    });
  });

  group('CardUtils - CVV Validation', () {
    test('validates CVV according to brand', () {
      expect(CardUtils.validateCvv('123', CardBrand.visa), isNull);
      expect(CardUtils.validateCvv('12', CardBrand.visa), 'CVV must be 3 digits');
      expect(CardUtils.validateCvv('1234', CardBrand.visa), 'CVV must be 3 digits');

      expect(CardUtils.validateCvv('1234', CardBrand.amex), isNull);
      expect(CardUtils.validateCvv('123', CardBrand.amex), 'Amex CVV must be 4 digits');
    });
  });

  group('CardUtils - Helpers', () {
    test('extractLast4 works correctly', () {
      expect(CardUtils.extractLast4('4242 4242 4242 4242'), '4242');
      expect(CardUtils.extractLast4('3782 822463 10005'), '0005');
    });

    test('parseExpiry parses month and full year', () {
      final parsed = CardUtils.parseExpiry('09/28');
      expect(parsed.month, 9);
      expect(parsed.year, 2028);
    });
  });
}
