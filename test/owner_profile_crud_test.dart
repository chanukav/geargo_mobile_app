import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/models/owner_profile.dart';
import 'package:geargo/services/owner_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OwnerProfileService service;
  const testUserId = 'user_123';

  setUp(() {
    service = OwnerProfileService();
    // Clear local cache before each test to ensure isolated state
    service.invalidateCache(testUserId);
  });

  group('CRUD 02 - Owner Profile Service (Local Cache Fallback)', () {
    test('Create & Read profile', () async {
      // 1. Create a blank profile
      final blankProfile = OwnerProfile.blank(testUserId);
      final created = await service.createProfile(blankProfile);
      
      expect(created.id, testUserId);
      expect(created.userId, testUserId);
      expect(created.isComplete, false);

      // 2. Read it back
      final fetched = await service.getProfile(testUserId);
      expect(fetched, isNotNull);
      expect(fetched!.userId, testUserId);
      expect(fetched.name, '');
    });

    test('Update profile with business details', () async {
      // Create initial profile
      final initial = await service.createProfile(OwnerProfile.blank(testUserId));

      // Update with details
      final updatedDraft = initial.copyWith(
        name: 'Alex Johnson',
        phone: '+1 555-0192',
        address: '123 Main St, Denver, CO',
        businessName: 'Peak Gear Rentals',
      );

      final saved = await service.updateProfile(updatedDraft);
      expect(saved.name, 'Alex Johnson');
      expect(saved.isComplete, true); // has name, phone, address
      expect(saved.businessName, 'Peak Gear Rentals');

      // Verify it persists in cache
      final fetched = await service.getProfile(testUserId);
      expect(fetched?.businessName, 'Peak Gear Rentals');
    });

    test('Deactivate (Soft Delete) profile', () async {
      await service.createProfile(OwnerProfile.blank(testUserId));

      // Deactivate
      final deactivated = await service.deactivateProfile(testUserId);
      expect(deactivated?.isActive, false);

      // Fetch and verify
      final fetched = await service.getProfile(testUserId);
      expect(fetched?.isActive, false);

      // Reactivate
      final reactivated = await service.reactivateProfile(testUserId);
      expect(reactivated?.isActive, true);
    });

    test('Hard Delete profile', () async {
      await service.createProfile(OwnerProfile.blank(testUserId));
      
      // Ensure it exists
      var fetched = await service.getProfile(testUserId);
      expect(fetched, isNotNull);

      // Delete
      await service.deleteProfile(testUserId);

      // Ensure it's gone
      fetched = await service.getProfile(testUserId);
      expect(fetched, isNull);
    });

    test('Profile avatar initials formatting', () {
      final p1 = OwnerProfile.blank(testUserId).copyWith(name: 'Alex Johnson');
      expect(p1.initials, 'AJ');

      final p2 = OwnerProfile.blank(testUserId).copyWith(name: 'Sarah');
      expect(p2.initials, 'S');

      final p3 = OwnerProfile.blank(testUserId).copyWith(name: '   ');
      expect(p3.initials, '?');

      final p4 = OwnerProfile.blank(testUserId).copyWith(name: 'David Lee Smith');
      expect(p4.initials, 'DL'); // first two words
    });
  });
}
