import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/screens/authentication/authenticate.dart';

void main() {
  group('email validation', () {
    test('requires a valid email address', () {
      expect(validateEmail(null), isNotNull);
      expect(validateEmail('  '), isNotNull);
      expect(validateEmail('not-an-email'), isNotNull);
      expect(validateEmail('rider@example.com'), isNull);
    });
  });

  group('password validation', () {
    test('requires at least six characters', () {
      expect(validatePassword(null), isNotNull);
      expect(validatePassword('12345'), isNotNull);
      expect(validatePassword('123456'), isNull);
    });
  });
}
