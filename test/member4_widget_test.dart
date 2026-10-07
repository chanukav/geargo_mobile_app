import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geargo/member4/admin_screen.dart';
import 'package:geargo/member4/admin_evidence_screen.dart';
import 'package:geargo/member4/chat_screen.dart';
import 'package:geargo/member4/condition_screen.dart';
import 'package:geargo/member4/handover_screen.dart';
import 'package:geargo/member4/deposit_screen.dart';
import 'package:geargo/member4/models.dart';
import 'package:geargo/member4/repository.dart';
import 'package:geargo/member4/widgets.dart';

class TestRepository implements Member4Repository {
  bool failSend = false;
  int adminReads = 0;
  String? sent;
  final record = RentalRecord('rental', {
    'equipmentName': 'Test bicycle',
    'ownerId': 'owner',
    'renterId': 'renter',
    'ownerName': 'Owner',
    'renterName': 'Renter',
    'status': 'pending',
    'currency': 'USD',
    'startDate': '2026-10-15',
    'endDate': '2026-10-19',
    'dailyRate': 32,
    'rentalCharge': 128,
    'serviceFee': 12.8,
    'amountPaid': 140.8,
    'paymentStatus': 'Recorded',
    'meetup': {
      'name': 'Public park',
      'address': 'North entrance',
      'latitude': 6.9,
      'longitude': 79.8,
    },
    'checklists': {
      'pickup': {'identity': false, 'damage': false, 'accessories': false},
    },
    'conditions': {
      'pickup': {
        'status': 'draft',
        'photos': <String, String>{},
        'notes': '',
        'damageReported': false,
      },
    },
    'confirmations': {'pickup': <String, String>{}},
    'deposit': {'amount': 150, 'status': 'pending'},
  });
  @override
  String get uid => 'renter';
  @override
  Future<bool> isAdmin() async => false;
  @override
  Stream<List<RentalRecord>> rentals({bool all = false}) {
    if (all) adminReads++;
    return Stream.value([record]);
  }

  @override
  Stream<RentalRecord?> rental(String id) => Stream.value(record);
  @override
  Stream<List<Map<String, dynamic>>> messages(String id) => Stream.value([]);
  @override
  Stream<List<Map<String, dynamic>>> reviews(String kind) {
    adminReads++;
    return Stream.value([]);
  }

  @override
  String newMessageId() => 'message';
  @override
  Future<void> action(
    String rentalId,
    String action,
    Map<String, dynamic> values,
  ) async {}
  @override
  Future<void> send(
    String rentalId,
    String messageId,
    String text, {
    bool location = false,
  }) async {
    if (failSend) throw StateError('Offline');
    sent = text;
  }

  @override
  Future<void> upload(
    String rentalId,
    String phase,
    String angle,
    XFile file,
  ) async {}
  @override
  Future<Uint8List?> photo(String path) async => null;
  @override
  Future<void> review(
    String kind,
    String id,
    String status,
    String note,
  ) async {}
}

Future<void> app(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(theme: Member4Theme.theme, home: screen));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('M4-TC-17 direct admin evidence screen denies nonadmin access', (
    t,
  ) async {
    final repo = TestRepository();
    await app(t, AdminEvidenceScreen(repo: repo, rentalId: 'rental'));
    expect(find.text('Administrator access is required.'), findsOneWidget);
  });
  testWidgets(
    'M4-TC-01/03 handover shows progress and opens rental chat at phone width',
    (t) async {
      final repo = TestRepository();
      await app(t, HandoverScreen(repo: repo, rentalId: 'rental'));
      expect(find.text('0 of 4 steps completed'), findsOneWidget);
      await t.scrollUntilVisible(find.text('Message Owner'), 250);
      await t.tap(find.text('Message Owner'));
      await t.pumpAndSettle();
      expect(find.text('Rental Conversation'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('M4-TC-18 blank messages cannot be sent', (t) async {
    final repo = TestRepository();
    await app(t, ChatScreen(repo: repo, rentalId: 'rental'));
    await t.tap(find.byTooltip('Send message'));
    await t.pumpAndSettle();
    expect(find.text('Enter a message before sending.'), findsOneWidget);
    expect(repo.sent, isNull);
  });
  testWidgets(
    'M4-TC-04/20 failed message retains input and retries successfully',
    (t) async {
      final repo = TestRepository()..failSend = true;
      await app(t, ChatScreen(repo: repo, rentalId: 'rental'));
      await t.enterText(find.byType(TextField), 'Where is the north entrance?');
      await t.tap(find.byTooltip('Send message'));
      await t.pumpAndSettle();
      expect(find.text('Where is the north entrance?'), findsOneWidget);
      repo.failSend = false;
      await t.tap(find.byTooltip('Send message'));
      await t.pumpAndSettle();
      expect(repo.sent, 'Where is the north entrance?');
      expect(find.text('Where is the north entrance?'), findsNothing);
    },
  );
  testWidgets('M4-TC-07/19 incomplete condition evidence cannot be confirmed', (
    t,
  ) async {
    await app(
      t,
      ConditionScreen(
        repo: TestRepository(),
        rentalId: 'rental',
        phase: 'pickup',
      ),
      size: const Size(360, 800),
    );
    expect(find.text('Capture Front View'), findsNWidgets(2));
    await t.scrollUntilVisible(
      find.text('Confirm all four condition photos'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    final button = t.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm all four condition photos'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('4 required views remaining.'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'M4-TC-12 deposit separates rental payment from refundable funds',
    (t) async {
      await app(t, DepositScreen(repo: TestRepository(), rentalId: 'rental'));
      expect(find.text('USD 150.00'), findsOneWidget);
      await t.scrollUntilVisible(find.text('Amount Paid: USD 140.80'), 200);
      expect(find.text('Amount Paid: USD 140.80'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'M4-TC-17 direct admin screen denies access before data requests',
    (t) async {
      final repo = TestRepository();
      await app(t, AdminScreen(repo: repo));
      expect(find.text('Administrator access is required.'), findsOneWidget);
      expect(repo.adminReads, 0);
    },
  );
}
