import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/models/equipment_review.dart';
import 'package:geargo/models/gear_item.dart';
import 'package:geargo/screens/owner/public_owner_profile_screen.dart';
import 'package:geargo/screens/renter/renter_equipment_details_screen.dart';
import 'package:geargo/services/database_seeder_service.dart';
import 'package:geargo/services/review_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleBike = GearItem(
    name: 'Specialized Stumpjumper EVO Comp Bike',
    owner: 'Marcus Vance',
    category: 'Cycling',
    image: 'assets/images/gear_bike_red.jpg',
    rating: 4.9,
    reviews: 42,
    distanceKm: 1.2,
    pricePerDay: 45,
    available: true,
    verified: true,
    listingId: 'gear_specialized_stumpjumper',
    ownerId: 'owner_default',
    description:
        'Mechanically perfect, freshly tuned, cleaned after every rental.',
  );

  group('Owner Profile & Equipment Reviews Journey Tests', () {
    testWidgets(
        'Equipment Details Screen shows owner avatar/card and reviews for equipment',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        MaterialApp(
          home: RenterEquipmentDetailsScreen.fromGearItem(sampleBike),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Owner details on Equipment Details page
      expect(find.text('Marcus Vance'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsWidgets);
      expect(find.textContaining('4.9 (42 rentals)'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);

      // Verify Condition & Availability Preview
      expect(find.text('Equipment Condition'), findsOneWidget);
      expect(find.text('Excellent / Like New'), findsOneWidget);
      expect(find.text('Availability Preview'), findsOneWidget);
      expect(find.text('Full Calendar'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);

      // Scroll to reviews section
      await tester.scrollUntilVisible(find.text('+ Write'), 300);
      await tester.pumpAndSettle();

      // Verify equipment-specific reviews section
      expect(find.textContaining('Reviews'), findsWidgets);
      expect(find.text('+ Write'), findsOneWidget);
      expect(find.text('Sarah K.'), findsWidgets);
      expect(
          find.text(
              'Perfect bike for the Duthie Hill trails! Marcus was great at setup. Highly recommend.'),
          findsOneWidget);
    });

    testWidgets(
        'Tapping owner card on Equipment Details navigates to Public Owner Profile',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        MaterialApp(
          home: RenterEquipmentDetailsScreen.fromGearItem(sampleBike),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure owner card is visible and tap it
      final ownerCardFinder = find.text('Marcus Vance');
      expect(ownerCardFinder, findsOneWidget);
      await tester.ensureVisible(ownerCardFinder);
      await tester.tap(ownerCardFinder);
      await tester.pumpAndSettle();

      // Verify on Public Owner Profile Screen
      expect(find.byType(PublicOwnerProfileScreen), findsOneWidget);
      expect(find.text('Owner Profile'), findsOneWidget);
      expect(find.text('Member since April 2021'), findsOneWidget);
      expect(find.text('Items Listed'), findsOneWidget);
      expect(find.text('Total Rentals'), findsOneWidget);
      expect(find.text('Response Rate'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      // Verify TabBar
      expect(find.textContaining('Listings'), findsOneWidget);
      expect(find.textContaining('Reviews'), findsOneWidget);

      // Verify equipment listings in 2-column grid
      expect(find.text('Specialized Stumpjumper EVO Comp Bike'), findsWidgets);
      expect(find.text('Rs. 45 / day'), findsWidgets);
    });

    testWidgets(
        'Owner Profile Screen toggles to Reviews tab and shows host reviews',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        const MaterialApp(
          home: PublicOwnerProfileScreen(
            ownerId: 'owner_default',
            ownerName: 'Marcus Vance',
            ownerVerified: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Reviews tab
      final reviewsTabFinder = find.textContaining('Reviews');
      expect(reviewsTabFinder, findsOneWidget);
      await tester.tap(reviewsTabFinder);
      await tester.pumpAndSettle();

      // Verify reviews are shown
      expect(find.text('Sarah K.'), findsOneWidget);
      expect(
          find.text(
              'Perfect bike for the Duthie Hill trails! Marcus was great at setup. Highly recommend.'),
          findsOneWidget);
    });

    testWidgets('Renter can write and submit a review for specific equipment',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        MaterialApp(
          home: RenterEquipmentDetailsScreen.fromGearItem(sampleBike),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to + Write button and tap it
      final writeButton = find.text('+ Write');
      await tester.scrollUntilVisible(writeButton, 300);
      await tester.pumpAndSettle();
      await tester.tap(writeButton);
      await tester.pumpAndSettle();

      // Verify Write Review Bottom Sheet is presented
      expect(find.text('Review Equipment'), findsOneWidget);
      expect(find.text('5 of 5 Stars'), findsOneWidget);
      expect(find.text('Submit Review'), findsOneWidget);

      // Enter review comment
      final commentField = find.byType(TextField).last;
      await tester.enterText(
          commentField, 'Awesome ride! The bike was immaculate.');
      await tester.pumpAndSettle();

      // Tap Submit Review
      await tester.tap(find.text('Submit Review'));
      await tester.pumpAndSettle();

      // Scroll to ensure reviews are visible
      await tester.scrollUntilVisible(
          find.text('Awesome ride! The bike was immaculate.'), 300);
      await tester.pumpAndSettle();

      // Verify review submitted and displayed
      expect(
          find.text('Awesome ride! The bike was immaculate.'), findsOneWidget);
    });

    test('ReviewService correctly scopes reviews to equipment and owner',
        () async {
      final service = ReviewService();

      // Stream reviews for specialized stumpjumper
      final equipReviews = await service
          .reviewsForEquipment('gear_specialized_stumpjumper')
          .first;
      expect(equipReviews.isNotEmpty, true);
      expect(
        equipReviews.any((r) => r['author_name'] == 'Sarah K.'),
        true,
      );

      // Stream reviews for owner
      final ownerReviews = await service
          .reviewsForOwner('owner_default', ownerName: 'Marcus Vance')
          .first;
      expect(ownerReviews.isNotEmpty, true);
      expect(
        ownerReviews.any((r) => r['owner_name'] == 'Marcus Vance'),
        true,
      );
    });

    test(
        'Database Entity Relationship: A review belongs to one piece of equipment, equipment can have many reviews',
        () async {
      final service = ReviewService();
      const targetEquipmentId = 'test_eq_mountain_bike_99';

      // 1. Create first review belonging to targetEquipmentId
      final review1 = EquipmentReview(
        id: 'rev_test_01',
        equipmentId: targetEquipmentId,
        ownerId: 'owner_test_1',
        authorId: 'renter_alex',
        authorName: 'Alex R.',
        rating: 5,
        comment: 'Top quality suspension and brakes.',
        createdAt: DateTime.now(),
        equipmentName: 'Test Mountain Bike',
      );

      final saved1 = await service.saveReviewToDatabase(review1);
      expect(saved1.equipmentId, targetEquipmentId);
      expect(saved1.rating, 5);

      // 2. Create second review belonging to the same equipmentId (1 equipment -> many reviews)
      final review2 = EquipmentReview(
        id: 'rev_test_02',
        equipmentId: targetEquipmentId,
        ownerId: 'owner_test_1',
        authorId: 'renter_clara',
        authorName: 'Clara M.',
        rating: 3,
        comment: 'Good bike, chain needed a bit of lube.',
        createdAt: DateTime.now(),
        equipmentName: 'Test Mountain Bike',
      );

      final saved2 = await service.saveReviewToDatabase(review2);
      expect(saved2.equipmentId, targetEquipmentId);
      expect(saved2.rating, 3);

      // 3. Create a review belonging to a DIFFERENT equipment
      const otherEquipmentId = 'test_eq_road_bike_88';
      final otherReview = EquipmentReview(
        id: 'rev_test_03',
        equipmentId: otherEquipmentId,
        ownerId: 'owner_test_2',
        authorId: 'renter_bob',
        authorName: 'Bob T.',
        rating: 4,
        comment: 'Nice road bike.',
        createdAt: DateTime.now(),
        equipmentName: 'Test Road Bike',
      );
      await service.saveReviewToDatabase(otherReview);

      // 4. Verify targetEquipmentId has exactly 2 reviews (belonging only to it)
      final targetReviews =
          await service.fetchReviewsForEquipment(targetEquipmentId);
      expect(targetReviews.length, 2);
      expect(targetReviews.every((r) => r.equipmentId == targetEquipmentId), true);
      expect(targetReviews.any((r) => r.id == 'rev_test_01'), true);
      expect(targetReviews.any((r) => r.id == 'rev_test_02'), true);

      // 5. Verify otherEquipmentId has only 1 review
      final otherReviews =
          await service.fetchReviewsForEquipment(otherEquipmentId);
      expect(otherReviews.length, 1);
      expect(otherReviews.first.id, 'rev_test_03');
      expect(otherReviews.first.equipmentId, otherEquipmentId);

      // 6. Verify review model toMap and fromMap database serialization
      final map = saved1.toMap();
      expect(map['equipment_id'], targetEquipmentId);
      expect(map['rating'], 5);
      expect(map['author_name'], 'Alex R.');

      final fromDb = EquipmentReview.fromMap(map, saved1.id);
      expect(fromDb.id, saved1.id);
      expect(fromDb.equipmentId, targetEquipmentId);
      expect(fromDb.comment, 'Top quality suspension and brakes.');
    });

    test('DatabaseSeederService seeds wireframe equipment items and 1-to-N reviews',
        () async {
      final seeder = DatabaseSeederService();

      // Verify sample equipment catalog exists
      expect(DatabaseSeederService.sampleEquipmentList.length, 6);
      expect(
        DatabaseSeederService.sampleEquipmentList
            .any((e) => e.id == 'gear_specialized_stumpjumper'),
        true,
      );

      // Verify sample reviews adhere strictly to 1-to-N constraint
      expect(DatabaseSeederService.sampleReviewsList.isNotEmpty, true);
      for (final rev in DatabaseSeederService.sampleReviewsList) {
        expect(rev.equipmentId.isNotEmpty, true);
        expect(
          DatabaseSeederService.sampleEquipmentList
              .any((e) => e.id == rev.equipmentId),
          true,
        );
      }

      // Execute seeding
      await seeder.seedEquipmentAndReviews();

      // Check reviews retrieved for Stumpjumper
      final reviewService = ReviewService();
      final stumpjumperReviews = await reviewService
          .fetchReviewsForEquipment('gear_specialized_stumpjumper');
      expect(stumpjumperReviews.length, greaterThanOrEqualTo(3));
      expect(
        stumpjumperReviews.any((r) => r.authorName == 'Sarah K.'),
        true,
      );
    });
  });
}
