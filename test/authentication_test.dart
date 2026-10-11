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

    test('supports all 4 roles: Renter, Gear Owner, Commercial Shop, Administrator', () {
      expect(UserRole.renter.displayName, 'Renter');
      expect(UserRole.owner.displayName, 'Gear Owner & Lender');
      expect(UserRole.commercialShop.displayName, 'Commercial Rental Shop');
      expect(UserRole.admin.displayName, 'Platform Administrator');

      expect(UserRole.renter.storageValue, 'renter');
      expect(UserRole.owner.storageValue, 'owner');
      expect(UserRole.commercialShop.storageValue, 'commercial_shop');
      expect(UserRole.admin.storageValue, 'admin');

      expect(UserRole.fromString('renter'), UserRole.renter);
      expect(UserRole.fromString('owner'), UserRole.owner);
      expect(UserRole.fromString('commercial_shop'), UserRole.commercialShop);
      expect(UserRole.fromString('commercialshop'), UserRole.commercialShop);
      expect(UserRole.fromString('admin'), UserRole.admin);

      const shopUser = AppUser(
        uid: 'shop_1',
        email: 'shop@gear.com',
        role: UserRole.commercialShop,
      );
      expect(shopUser.isCommercialShop, isTrue);
      expect(shopUser.canManageListings, isTrue);
      expect(shopUser.toMap()['role'], 'commercial_shop');

      const adminUser = AppUser(
        uid: 'admin_1',
        email: 'admin@geargo.com',
        role: UserRole.admin,
      );
      expect(adminUser.isPlatformAdmin, isTrue);
      expect(adminUser.toMap()['role'], 'admin');
    });
  });
}
