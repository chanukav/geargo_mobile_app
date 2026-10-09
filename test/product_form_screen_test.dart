import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/models/shop_product.dart';
import 'package:geargo/screens/shop/product_form_screen.dart';
import 'package:geargo/services/shop_product_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ShopProductService testService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    testService = ShopProductService(
      firestore: fakeFirestore,
      userId: 'test-shop-owner',
    );
  });

  void setPhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('ProductFormScreen renders creation mode and validates blank inputs',
      (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ProductFormScreen(service: testService),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar title and initial button label
    expect(find.text('Add equipment'), findsOneWidget);
    expect(find.text('Add to inventory'), findsOneWidget);

    // Verify presence of input labels
    expect(find.text('Equipment name'), findsOneWidget);
    expect(find.text('Price per day'), findsOneWidget);
    expect(find.text('Refundable deposit'), findsOneWidget);
    expect(find.text('Quantity in stock'), findsOneWidget);

    // Clear quantity field (which defaults to '1') to test all validator triggers
    // Form fields order: 0: name, 1: description, 2: price, 3: deposit, 4: quantity, 5: imageUrl
    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(6));

    await tester.enterText(textFields.at(4), ''); // quantity
    await tester.pump();

    // Tap submit button without filling required fields
    final submitButton = find.text('Add to inventory');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify validation errors are shown
    expect(find.text('This field is required'), findsOneWidget); // Name
    expect(find.text('Enter a valid amount'), findsNWidgets(2)); // Price & Deposit
    expect(find.text('Enter a whole number'), findsOneWidget); // Quantity
  });

  testWidgets('ProductFormScreen accepts valid inputs and clears errors',
      (tester) async {
    setPhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ProductFormScreen(service: testService),
      ),
    );
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);

    // Fill valid data
    await tester.enterText(textFields.at(0), 'Pro Mountain Bike'); // name
    await tester.enterText(textFields.at(2), '35.00'); // price
    await tester.enterText(textFields.at(3), '100.00'); // deposit
    await tester.enterText(textFields.at(4), '4'); // quantity
    await tester.pump();

    // Trigger validation
    final submitButton = find.text('Add to inventory');
    await tester.tap(submitButton);
    await tester.pump();

    // Errors should not appear
    expect(find.text('This field is required'), findsNothing);
    expect(find.text('Enter a valid amount'), findsNothing);
    expect(find.text('Enter a whole number'), findsNothing);
  });

  testWidgets('ProductFormScreen renders edit mode with prefilled values',
      (tester) async {
    setPhoneSize(tester);
    const existingProduct = ShopProduct(
      id: 'p-456',
      ownerId: 'test-shop-owner',
      name: 'Yonex Badminton Racket',
      category: 'Racket Sports',
      description: 'Pre-strung carbon frame',
      condition: 'Excellent',
      pricePerDay: 15.0,
      deposit: 30.0,
      quantity: 6,
      isAvailable: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProductFormScreen(
          product: existingProduct,
          service: testService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Edit title and prefilled fields
    expect(find.text('Edit equipment'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.text('Yonex Badminton Racket'), findsOneWidget);
    expect(find.text('15.00'), findsOneWidget);
    expect(find.text('30.00'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });
}
