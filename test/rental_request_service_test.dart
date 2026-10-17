import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/models/rental_request.dart';
import 'package:geargo/screens/renter/rental_request_details_screen.dart';
import 'package:geargo/services/rental_request_service.dart';

void main() {
  group('RentalRequestService deleteBooking & Stream Lifecycle', () {
    late FakeFirebaseFirestore fakeFirestore;
    late RentalRequestService service;
    const testRenterId = 'renter_123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = RentalRequestService();
      service.resetForTesting();
      service.setCustomFirestore(fakeFirestore);
    });

    tearDown(() {
      service.resetForTesting();
    });

    RentalRequest sampleRequest({
      required String id,
      required RentalStatus status,
      String renterId = testRenterId,
      String equipmentId = 'eq_1',
      String equipmentName = 'Camping Tent',
      DateTime? startDate,
      DateTime? endDate,
    }) {
      return RentalRequest(
        id: id,
        renterId: renterId,
        renterName: 'Test Renter',
        renterEmail: 'renter@test.com',
        renterPhone: '0771234567',
        equipmentId: equipmentId,
        equipmentName: equipmentName,
        equipmentCategory: 'Camping',
        equipmentImage: '',
        dailyPrice: 25.0,
        ownerId: 'owner_1',
        ownerName: 'Test Owner',
        startDate: startDate ?? DateTime(2026, 10, 20),
        endDate: endDate ?? DateTime(2026, 10, 23),
        totalDays: 3,
        serviceFee: 5.0,
        depositAmount: 50.0,
        totalPrice: 80.0,
        status: status,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    test('CREATE and STREAM: Newly created requests appear in stream', () async {
      final req = sampleRequest(id: 'req_1', status: RentalStatus.pending);
      await service.createRequest(req);

      final stream = service.getRenterRequestsStream(testRenterId);
      final initialList = await stream.first;
      expect(initialList.length, 1);
      expect(initialList.first.id, 'req_1');
    });

    test('VALIDATION: Deleting a non-cancelled booking is rejected', () async {
      final pendingReq = sampleRequest(id: 'req_pending', status: RentalStatus.pending);
      final approvedReq = sampleRequest(id: 'req_approved', status: RentalStatus.approved);
      final activeReq = sampleRequest(id: 'req_active', status: RentalStatus.active);
      final completedReq = sampleRequest(id: 'req_completed', status: RentalStatus.completed);

      await service.createRequest(pendingReq);
      await service.createRequest(approvedReq);
      await service.createRequest(activeReq);
      await service.createRequest(completedReq);

      // Pending rejected
      expect(
        () => service.deleteBooking('req_pending'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Only cancelled bookings can be deleted'),
        )),
      );

      // Approved rejected
      expect(
        () => service.deleteBooking('req_approved'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Only cancelled bookings can be deleted'),
        )),
      );

      // Active rejected
      expect(
        () => service.deleteBooking('req_active'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Only cancelled bookings can be deleted'),
        )),
      );

      // Completed rejected
      expect(
        () => service.deleteBooking('req_completed'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Only cancelled bookings can be deleted'),
        )),
      );
    });

    test('VALIDATION: Cannot delete non-existent request', () async {
      expect(
        () => service.deleteBooking('req_non_existent'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Booking record not found'),
        )),
      );
    });

    test('DELETE: Deleting a cancelled booking removes only that booking, leaving similar bookings intact', () async {
      final start = DateTime(2026, 11, 1);
      final end = DateTime(2026, 11, 5);

      // Booking 1: Same item, same dates -> will be cancelled & deleted
      final req1 = sampleRequest(
        id: 'req_booking_1',
        status: RentalStatus.pending,
        equipmentId: 'eq_tent_same',
        equipmentName: 'Mountain Tent',
        startDate: start,
        endDate: end,
      );

      // Booking 2: Same item, same dates -> will remain active/pending
      final req2 = sampleRequest(
        id: 'req_booking_2',
        status: RentalStatus.pending,
        equipmentId: 'eq_tent_same',
        equipmentName: 'Mountain Tent',
        startDate: start,
        endDate: end,
      );

      await service.createRequest(req1);
      await service.createRequest(req2);

      // Both should appear in stream initially
      var list = await service.getRenterRequestsStream(testRenterId).first;
      expect(list.length, 2);

      // Cancel booking 1
      await service.cancelRequest('req_booking_1');
      final cancelled = await service.getRequestById('req_booking_1');
      expect(cancelled?.status, RentalStatus.cancelled);

      // Booking 2 is still pending
      final untouched = await service.getRequestById('req_booking_2');
      expect(untouched?.status, RentalStatus.pending);

      // Permanently delete booking 1 using deleteBooking
      await service.deleteBooking('req_booking_1');

      // Verify req_booking_1 is completely gone from cache & Firestore
      final afterDelete = await service.getRequestById('req_booking_1');
      expect(afterDelete, isNull);
      final firestoreDoc1 = await fakeFirestore.collection('rental_requests').doc('req_booking_1').get();
      expect(firestoreDoc1.exists, isFalse);

      // Verify req_booking_2 remains untouched in cache & Firestore
      final remaining = await service.getRequestById('req_booking_2');
      expect(remaining, isNotNull);
      expect(remaining!.id, 'req_booking_2');
      expect(remaining.equipmentName, 'Mountain Tent');
      final firestoreDoc2 = await fakeFirestore.collection('rental_requests').doc('req_booking_2').get();
      expect(firestoreDoc2.exists, isTrue);

      // Verify stream only contains req_booking_2
      list = await service.getRenterRequestsStream(testRenterId).first;
      expect(list.length, 1);
      expect(list.first.id, 'req_booking_2');
    });

    test('VALIDATION: User cannot delete someone else booking', () async {
      final req = sampleRequest(id: 'req_other', status: RentalStatus.cancelled, renterId: 'renter_victim');
      await service.createRequest(req);

      service.setCustomAuth(null, userId: 'renter_intruder');

      expect(
        () => service.deleteBooking('req_other'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('You can only delete your own booking records'),
        )),
      );
    });

    testWidgets('UI FLOW: RentalRequestDetailsScreen Cancel -> Confirmation Cancel / Delete flow', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sample = sampleRequest(id: 'req_ui_test', status: RentalStatus.pending);
      await service.createRequest(sample);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RentalRequestDetailsScreen(request: sample),
                      ),
                    );
                  },
                  child: const Text('Open Details'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Details'));
      await tester.pumpAndSettle();

      // Verify "Booking Details" and "Cancel Request"
      expect(find.text('Booking Details'), findsOneWidget);
      expect(find.text('Pending Review'), findsWidgets);
      expect(find.text('Cancel Request'), findsWidgets);

      // Tap "Cancel Request"
      await tester.tap(find.text('Cancel Request').first);
      await tester.pumpAndSettle();

      // Dialog appears with "Yes, Cancel"
      expect(find.text('Yes, Cancel'), findsOneWidget);
      await tester.tap(find.text('Yes, Cancel'));
      await tester.pumpAndSettle();

      // Status is now Cancelled and action button changed to "Delete Record"
      expect(find.text('Cancelled'), findsWidgets);
      expect(find.text('Delete Record'), findsWidgets);

      // Tap "Delete Record" -> confirmation dialog appears
      await tester.tap(find.text('Delete Record').first);
      await tester.pumpAndSettle();

      expect(find.text('Delete this booking record?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap "Cancel" -> confirmation is dismissed, booking NOT deleted
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      final recordStillExists = await service.getRequestById('req_ui_test');
      expect(recordStillExists, isNotNull);
      expect(recordStillExists?.status, RentalStatus.cancelled);

      // Tap "Delete Record" again -> tap "Delete"
      await tester.tap(find.text('Delete Record').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Record is permanently deleted
      final recordGone = await service.getRequestById('req_ui_test');
      expect(recordGone, isNull);
      expect(find.text('Booking record removed.'), findsOneWidget);
    });

    testWidgets('UI ERROR HANDLING: Deletion failure shows friendly message and does not pop', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sample = sampleRequest(id: 'req_err_test', status: RentalStatus.cancelled);
      await service.createRequest(sample);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RentalRequestDetailsScreen(request: sample),
                      ),
                    );
                  },
                  child: const Text('Open Details'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Details'));
      await tester.pumpAndSettle();

      // Change user to cause an ownership mismatch / permission rejection
      service.setCustomAuth(null, userId: 'intruder_renter');

      // Tap "Delete Record" -> dialog appears
      await tester.tap(find.text('Delete Record').first);
      await tester.pumpAndSettle();

      // Tap "Delete" in confirmation dialog
      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Friendly error message appears, not raw error
      expect(find.text("You don't have permission to delete this booking."), findsOneWidget);

      // Screen is still mounted and showing Booking Details
      expect(find.text('Booking Details'), findsOneWidget);
    });
  });
}
