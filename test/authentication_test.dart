import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/core/utils/validators.dart';
import 'package:geargo/models/app_user.dart';

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

  group('name validation', () {
    test('requires name with at least two characters', () {
      expect(validateName(null), isNotNull);
      expect(validateName(''), isNotNull);
      expect(validateName('A'), isNotNull);
      expect(validateName('Alex'), isNull);
    });
  });

  group('confirm password validation', () {
    test('verifies matching passwords', () {
      expect(validateConfirmPassword(null, 'secret123'), isNotNull);
      expect(validateConfirmPassword('secret', 'secret123'), isNotNull);
      expect(validateConfirmPassword('secret123', 'secret123'), isNull);
    });
  });

  group('AppUser model', () {
    test('computes displayTitle and initials properly', () {
      const user = AppUser(
        uid: 'user123',
        displayName: 'John Doe',
        email: 'john@example.com',
      );
      expect(user.displayTitle, 'John Doe');
      expect(user.initials, 'JD');

      const guestUser = AppUser(
        uid: 'guest456',
        isAnonymous: true,
      );
      expect(guestUser.displayTitle, 'Guest Driver');
      expect(guestUser.initials, 'GD');
    });

    test('supports separate Renter and Owner personas', () {
      const renter = AppUser(
        uid: 'renter_1',
        email: 'user@geargo.com',
        displayName: 'Sam Wilson',
        role: UserRole.renter,
      );
      expect(renter.isRenter, isTrue);
      expect(renter.isOwner, isFalse);
      expect(renter.role.displayName, 'Renter');

      const owner = AppUser(
        uid: 'owner_1',
        email: 'owner@geargo.com',
        displayName: 'Marcus Vance',
        role: UserRole.owner,
      );
      expect(owner.isOwner, isTrue);
      expect(owner.isRenter, isFalse);
      expect(owner.role.displayName, 'Gear Owner & Lender');

      // Serialization to and from Map
      final map = owner.toMap();
      expect(map['role'], 'owner');
      final reconstructed = AppUser.fromMap(map, owner.uid);
      expect(reconstructed.isOwner, isTrue);
    });
  });
}
