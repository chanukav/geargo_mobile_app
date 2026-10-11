import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/core/constants/supabase_config.dart';
import 'package:geargo/models/app_user.dart';
import 'package:geargo/services/database_seeder_service.dart';
import 'package:geargo/services/supabase_storage_service.dart';
import 'package:geargo/services/user_service.dart';
import 'package:geargo/widgets/profile_photo_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SupabaseStorageService.mockProfileStorage.clear();
  });

  group('Every Persona User Data in Database Tests', () {
    test('AppUser model serializes and deserializes all 4 personas correctly',
        () {
      // 1. Renter persona
      final renter = AppUser(
        uid: 'user_renter_01',
        email: 'renter@geargo.com',
        displayName: 'Maya Chen',
        photoUrl: 'https://cdn.example.com/maya.jpg',
        role: UserRole.renter,
        phoneNumber: '+1 555-0101',
        bio: 'Weekend camper & kayaker.',
        address: 'Vancouver, BC',
        isVerified: true,
      );
      final renterMap = renter.toMap();
      expect(renterMap['role'], 'renter');
      expect(renterMap['phone_number'], '+1 555-0101');
      expect(renterMap['bio'], 'Weekend camper & kayaker.');
      expect(renter.isRenter, isTrue);

      final fromRenter = AppUser.fromMap(renterMap, renter.uid);
      expect(fromRenter.role, UserRole.renter);
      expect(fromRenter.displayName, 'Maya Chen');
      expect(fromRenter.phoneNumber, '+1 555-0101');

      // 2. Gear Owner persona
      final owner = AppUser(
        uid: 'user_owner_01',
        email: 'owner@geargo.com',
        displayName: 'Marcus Vance',
        photoUrl: 'https://cdn.example.com/marcus.jpg',
        role: UserRole.owner,
        phoneNumber: '+1 555-0202',
        bio: 'Downhill mountain bike specialist.',
        address: 'Seattle, WA',
        businessName: 'Vance Trail Rentals',
        isVerified: true,
      );
      final ownerMap = owner.toMap();
      expect(ownerMap['role'], 'owner');
      expect(ownerMap['business_name'], 'Vance Trail Rentals');
      expect(owner.isOwner, isTrue);
      expect(owner.canManageListings, isTrue);

      final fromOwner = AppUser.fromMap(ownerMap, owner.uid);
      expect(fromOwner.role, UserRole.owner);
      expect(fromOwner.businessName, 'Vance Trail Rentals');

      // 3. Commercial Shop persona
      final shop = AppUser(
        uid: 'user_shop_01',
        email: 'commercial@apexgear.com',
        displayName: 'Apex Mountain Gear',
        photoUrl: 'https://cdn.example.com/shop.jpg',
        role: UserRole.commercialShop,
        phoneNumber: '+1 555-0303',
        bio: 'Commercial fleet rentals & repairs.',
        address: 'Whistler, BC',
        businessName: 'Apex Commercial Depot',
        isVerified: true,
      );
      final shopMap = shop.toMap();
      expect(shopMap['role'], 'commercial_shop');
      expect(shop.isCommercialShop, isTrue);
      expect(shop.canManageListings, isTrue);

      final fromShop = AppUser.fromMap(shopMap, shop.uid);
      expect(fromShop.role, UserRole.commercialShop);

      // 4. Platform Administrator persona
      final admin = AppUser(
        uid: 'user_admin_01',
        email: 'admin@geargo.com',
        displayName: 'Elena Rostova',
        photoUrl: 'https://cdn.example.com/admin.jpg',
        role: UserRole.admin,
        phoneNumber: '+1 555-0404',
        bio: 'Safety & Trust operations manager.',
        address: 'HQ - San Francisco, CA',
        isVerified: true,
      );
      final adminMap = admin.toMap();
      expect(adminMap['role'], 'admin');
      expect(admin.isPlatformAdmin, isTrue);

      final fromAdmin = AppUser.fromMap(adminMap, admin.uid);
      expect(fromAdmin.role, UserRole.admin);
      expect(fromAdmin.displayName, 'Elena Rostova');
    });

    test('UserService saves, retrieves, and streams every persona user data',
        () async {
      final userService = UserService();

      final renter = AppUser(
        uid: 'db_test_renter',
        email: 'db.renter@example.com',
        displayName: 'Liam Wilson',
        role: UserRole.renter,
        phoneNumber: '+1 202-555-0143',
        bio: 'Exploring trails in the Pacific Northwest.',
        address: 'Portland, OR',
      );

      // Save user data to database
      final saved = await userService.saveUserData(renter);
      expect(saved.uid, 'db_test_renter');
      expect(saved.role, UserRole.renter);

      // Read user data from database
      final read = await userService.getUserData('db_test_renter');
      expect(read, isNotNull);
      expect(read!.displayName, 'Liam Wilson');
      expect(read.phoneNumber, '+1 202-555-0143');
      expect(read.address, 'Portland, OR');

      // Update persona user data in database
      final updated = read.copyWith(
        bio: 'Updated bio with 50+ completed mountain bike rentals.',
        isVerified: true,
      );
      await userService.saveUserData(updated);

      final reRead = await userService.getUserData('db_test_renter');
      expect(reRead!.bio,
          'Updated bio with 50+ completed mountain bike rentals.');
      expect(reRead.isVerified, isTrue);

      // Stream user persona data
      final streamUser = await userService.getUserStream('db_test_renter').first;
      expect(streamUser, isNotNull);
      expect(streamUser!.uid, 'db_test_renter');
    });

    test('DatabaseSeederService seeds all 4 personas into database on startup',
        () async {
      final seeder = DatabaseSeederService();
      await seeder.seedEquipmentAndReviews();

      final userService = UserService();

      // Check Renter
      final renter = await userService.getUserData('user_renter_maya');
      expect(renter, isNotNull);
      expect(renter!.role, UserRole.renter);
      expect(renter.displayName, 'Maya Chen');

      // Check Gear Owner
      final owner = await userService.getUserData('owner_default');
      expect(owner, isNotNull);
      expect(owner!.role, UserRole.owner);
      expect(owner.displayName, 'Marcus Vance');

      // Check Commercial Shop
      final shop = await userService.getUserData('user_shop_apex');
      expect(shop, isNotNull);
      expect(shop!.role, UserRole.commercialShop);
      expect(shop.displayName, 'Apex Mountain Gear');

      // Check Administrator
      final admin = await userService.getUserData('user_admin_elena');
      expect(admin, isNotNull);
      expect(admin!.role, UserRole.admin);
      expect(admin.displayName, 'Elena Rostova');
    });
  });

  group('Supabase Storage Profile Image CRUD in folder "profile image"', () {
    test(
        'Upload (Create) profile image saves strictly in "profile image" folder and returns public CDN URL',
        () async {
      final testBytes = utf8.encode('fake_profile_image_binary_bytes_123');
      const userId = 'user_rider_777';

      final publicUrl = await SupabaseStorageService.uploadProfileImage(
        userId: userId,
        bytes: testBytes,
      );

      // Verify folder named 'profile image' is in the URL / storage path
      expect(publicUrl.contains(SupabaseConfig.profileImageFolder), isTrue);
      expect(publicUrl.contains('profile%20image') ||
              publicUrl.contains('profile image'),
          isTrue);
      expect(publicUrl.contains(userId), isTrue);
      expect(publicUrl.startsWith('http'), isTrue);

      // Verify mock storage has saved the object in folder 'profile image'
      expect(
        SupabaseStorageService.mockProfileStorage.keys.any(
            (k) => k.startsWith('${SupabaseConfig.profileImageFolder}/')),
        isTrue,
      );
    });

    test('Read profile image retrieves bytes and resolves public CDN URL',
        () async {
      final testBytes = utf8.encode('profile_image_read_test_content');
      const userId = 'user_reader_888';

      final publicUrl = await SupabaseStorageService.uploadProfileImage(
        userId: userId,
        bytes: testBytes,
      );

      // Read / get public URL
      final resolvedUrl = SupabaseStorageService.getProfileImageUrl(publicUrl);
      expect(resolvedUrl, equals(publicUrl));

      // Download / read binary bytes
      final downloadedBytes =
          await SupabaseStorageService.downloadProfileImage(publicUrl);
      expect(downloadedBytes, isNotNull);
      expect(downloadedBytes, equals(testBytes));
    });

    test(
        'Update profile image replaces old image in "profile image" folder and returns new URL',
        () async {
      final oldBytes = utf8.encode('old_avatar_bytes');
      const userId = 'user_updater_999';

      final initialUrl = await SupabaseStorageService.uploadProfileImage(
        userId: userId,
        bytes: oldBytes,
      );
      expect(initialUrl.isNotEmpty, isTrue);

      final newBytes = utf8.encode('new_high_res_avatar_bytes');
      final updatedUrl = await SupabaseStorageService.updateProfileImage(
        userId: userId,
        bytes: newBytes,
        oldUrl: initialUrl,
      );

      expect(updatedUrl.isNotEmpty, isTrue);
      expect(updatedUrl, isNot(equals(initialUrl)));
      expect(updatedUrl.contains(SupabaseConfig.profileImageFolder), isTrue);

      // Old entry should have been purged, new entry present
      expect(
        SupabaseStorageService.mockProfileStorage.values
            .contains(oldBytes),
        isFalse,
      );
      expect(
        SupabaseStorageService.mockProfileStorage.values
            .contains(newBytes),
        isTrue,
      );
    });

    test(
        'Delete profile image removes it from "profile image" folder in Supabase Storage',
        () async {
      final testBytes = utf8.encode('delete_me_avatar_bytes');
      const userId = 'user_to_delete_000';

      final publicUrl = await SupabaseStorageService.uploadProfileImage(
        userId: userId,
        bytes: testBytes,
      );
      expect(
        SupabaseStorageService.mockProfileStorage.values.contains(testBytes),
        isTrue,
      );

      // Delete image
      await SupabaseStorageService.deleteProfileImage(
        userId: userId,
        photoUrl: publicUrl,
      );

      // Verify removed from Supabase Storage
      expect(
        SupabaseStorageService.mockProfileStorage.values.contains(testBytes),
        isFalse,
      );
    });

    test(
        'UserService orchestrates profile photo Update and Delete with database synchronization',
        () async {
      final userService = UserService();
      const userId = 'user_sync_test_555';

      final initialUser = AppUser(
        uid: userId,
        email: 'sync.user@geargo.com',
        displayName: 'Sync Tester',
        role: UserRole.owner,
      );
      await userService.saveUserData(initialUser);

      // 1. Update photo: uploads to Supabase Storage ('profile image') and saves URL to database
      final photoBytes = utf8.encode('sync_tester_avatar_bytes');
      final userWithPhoto = await userService.updateProfilePhoto(
        userId: userId,
        bytes: photoBytes,
        currentUser: initialUser,
      );

      expect(userWithPhoto.photoUrl, isNotNull);
      expect(userWithPhoto.photoUrl!.contains(SupabaseConfig.profileImageFolder),
          isTrue);

      // Check database reflects the new Supabase Storage photoUrl
      final dbCheck1 = await userService.getUserData(userId);
      expect(dbCheck1!.photoUrl, equals(userWithPhoto.photoUrl));

      // 2. Delete photo: deletes from Supabase Storage ('profile image') and clears photoUrl in database
      final userAfterDelete = await userService.deleteProfilePhoto(
        userId: userId,
        currentUser: userWithPhoto,
      );

      expect(userAfterDelete.photoUrl, isEmpty);

      // Check database reflects the cleared photoUrl
      final dbCheck2 = await userService.getUserData(userId);
      expect(dbCheck2!.photoUrl == null || dbCheck2.photoUrl!.isEmpty, isTrue);
    });
  });

  group('ProfilePhotoModal Widget UI Tests', () {
    testWidgets(
        'ProfilePhotoModal displays persona badge, folder tag, and actions',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const user = AppUser(
        uid: 'ui_test_user',
        displayName: 'Sophia Loren',
        role: UserRole.commercialShop,
        photoUrl: 'https://cdn.example.com/avatar.jpg',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfilePhotoModal(user: user),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Modal Title & Persona
      expect(find.text('Profile Image'), findsOneWidget);
      expect(find.text('Persona: Commercial Rental Shop'), findsOneWidget);

      // Verify Supabase Storage folder tag
      expect(find.text(SupabaseConfig.profileImageFolder), findsOneWidget);

      // Verify Action buttons
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Update Photo'), findsOneWidget);
      expect(find.text('Delete Profile Photo'), findsOneWidget);
    });

    testWidgets(
        'ProfilePhotoModal without photo shows Upload Photo and hides Delete button',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const user = AppUser(
        uid: 'ui_no_photo_user',
        displayName: 'No Photo User',
        role: UserRole.renter,
        photoUrl: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfilePhotoModal(user: user),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upload Photo'), findsOneWidget);
      expect(find.text('Delete Profile Photo'), findsNothing);
      expect(find.text('NP'), findsOneWidget); // Initials
    });
  });
}
