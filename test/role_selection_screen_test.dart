import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/models/app_user.dart';
import 'package:geargo/screens/authentication/role_selection_screen.dart';

void main() {
  testWidgets('RoleSelectionScreen displays Google user info and all 4 roles',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    UserRole? selectedResult;

    await tester.pumpWidget(
      MaterialApp(
        home: RoleSelectionScreen(
          displayName: 'Alex Traveler',
          email: 'alex.traveler@gmail.com',
          initialRole: UserRole.renter,
          onRoleSelected: (role) {
            selectedResult = role;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Google user header info
    expect(find.text('Alex Traveler'), findsOneWidget);
    expect(find.text('alex.traveler@gmail.com'), findsOneWidget);

    // Verify all 4 required roles are displayed
    expect(find.text('Renter'), findsOneWidget);
    expect(find.text('Gear Owner'), findsOneWidget);
    expect(find.text('Commercial Shop'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);

    // Verify role tags
    expect(find.text('Rent Equipment'), findsOneWidget);
    expect(find.text('Lend & Earn'), findsOneWidget);
    expect(find.text('Fleet & Inventory'), findsOneWidget);
    expect(find.text('Platform Ops'), findsOneWidget);

    // Initial role is Renter
    expect(find.text('Continue as Renter'), findsOneWidget);

    // Tap on "Gear Owner"
    await tester.tap(find.text('Gear Owner'));
    await tester.pumpAndSettle();

    // Verify button text updates
    expect(find.text('Continue as Gear Owner & Lender'), findsOneWidget);

    // Tap on "Commercial Shop"
    await tester.tap(find.text('Commercial Shop'));
    await tester.pumpAndSettle();

    // Verify button text updates
    expect(find.text('Continue as Commercial Rental Shop'), findsOneWidget);

    // Tap on "Administrator"
    await tester.tap(find.text('Administrator'));
    await tester.pumpAndSettle();

    // Verify button text updates
    expect(find.text('Continue as Platform Administrator'), findsOneWidget);

    // Tap confirm button
    await tester.tap(find.text('Continue as Platform Administrator'));
    await tester.pumpAndSettle();

    // Callback should receive UserRole.admin
    expect(selectedResult, equals(UserRole.admin));
  });

  testWidgets(
      'RoleSelectionScreen selecting Gear Owner triggers callback with UserRole.owner',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    UserRole? selectedResult;

    await tester.pumpWidget(
      MaterialApp(
        home: RoleSelectionScreen(
          displayName: 'Jane Doe',
          email: 'jane@gmail.com',
          initialRole: UserRole.renter,
          onRoleSelected: (role) {
            selectedResult = role;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on "Gear Owner"
    await tester.tap(find.text('Gear Owner'));
    await tester.pumpAndSettle();

    // Tap confirm button
    await tester.tap(find.text('Continue as Gear Owner & Lender'));
    await tester.pumpAndSettle();

    expect(selectedResult, equals(UserRole.owner));
  });
}
