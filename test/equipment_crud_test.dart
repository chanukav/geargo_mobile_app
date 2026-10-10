import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/models/equipment.dart';
import 'package:geargo/screens/owner/widgets/category_selector.dart';
import 'package:geargo/screens/owner/widgets/equipment_card.dart';
import 'package:geargo/services/equipment_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Equipment Model & Database Schema Tests', () {
    test('Correctly maps to and from Database Schema', () {
      final now = DateTime.now();
      final item = Equipment(
        id: 'eq_101',
        ownerId: 'owner_999',
        name: 'Trek Fuel EX 8 Gen 6',
        categoryId: 'mountain_bikes',
        description: 'Trail-ready mountain bike with upgraded rear shock.',
        price: 45.0,
        availability: true,
        image: 'https://example.com/trek.jpg',
        createdAt: now,
        updatedAt: now,
        condition: 'Excellent',
        location: 'Denver, CO',
        rating: 4.9,
        reviewsCount: 15,
      );

      // Verify toMap contains all database fields
      final map = item.toMap();
      expect(map['id'], 'eq_101');
      expect(map['owner_id'], 'owner_999');
      expect(map['name'], 'Trek Fuel EX 8 Gen 6');
      expect(map['category_id'], 'mountain_bikes');
      expect(map['description'], contains('Trail-ready'));
      expect(map['price'], 45.0);
      expect(map['availability'], true);
      expect(map['image'], 'https://example.com/trek.jpg');
      expect(map['condition'], 'Excellent');
      expect(map['location'], 'Denver, CO');

      // Verify deserialization fromMap
      final restored = Equipment.fromMap(map, 'eq_101');
      expect(restored.id, 'eq_101');
      expect(restored.ownerId, 'owner_999');
      expect(restored.name, 'Trek Fuel EX 8 Gen 6');
      expect(restored.categoryId, 'mountain_bikes');
      expect(restored.price, 45.0);
      expect(restored.availability, true);
      expect(restored.category.name, 'Mountain Bikes');
      expect(restored.category.icon, Icons.directions_bike_rounded);
    });

    test('copyWith updates individual fields while preserving others', () {
      final original = Equipment(
        id: 'eq_1',
        ownerId: 'owner_1',
        name: 'Original Bike',
        categoryId: 'mountain_bikes',
        description: 'Old description',
        price: 40.0,
        availability: true,
        image: 'image1.png',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = original.copyWith(
        price: 55.0,
        description: 'New tuned description',
        availability: false,
        image: 'image_new.png',
      );

      expect(updated.id, original.id);
      expect(updated.ownerId, original.ownerId);
      expect(updated.name, original.name);
      expect(updated.price, 55.0);
      expect(updated.description, 'New tuned description');
      expect(updated.availability, false);
      expect(updated.image, 'image_new.png');
    });

    test('Category resolver returns fallback for unknown category', () {
      final category = EquipmentCategory.findById('unknown_category');
      expect(category.name, 'General Gear');
      expect(category.icon, Icons.category_rounded);
    });
  });

  group('EquipmentService CRUD Operations Tests', () {
    final service = EquipmentService();
    const testOwnerId = 'owner_test_abc';

    test('Create: adds new equipment listing', () async {
      final newItem = Equipment(
        id: 'crud_test_01',
        ownerId: testOwnerId,
        name: 'Kayak Explorer K2',
        categoryId: 'water_sports',
        description: '2-person inflatable kayak with aluminum oars.',
        price: 35.0,
        availability: true,
        image: 'https://example.com/kayak.jpg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await service.createEquipment(newItem);
      expect(created.id, 'crud_test_01');
      expect(created.name, 'Kayak Explorer K2');

      // Read back
      final fetched = await service.getEquipmentById('crud_test_01');
      expect(fetched, isNotNull);
      expect(fetched!.price, 35.0);
      expect(fetched.categoryId, 'water_sports');
    });

    test('Update: updates price, description, image, and availability', () async {
      final existing = await service.getEquipmentById('crud_test_01');
      expect(existing, isNotNull);

      final modified = existing!.copyWith(
        price: 42.0,
        description: 'Updated kayak with extra life jacket included.',
        availability: false,
        image: 'https://example.com/kayak_v2.jpg',
      );

      final updated = await service.updateEquipment(modified);
      expect(updated.price, 42.0);
      expect(updated.description, contains('extra life jacket'));
      expect(updated.availability, false);
      expect(updated.image, 'https://example.com/kayak_v2.jpg');

      final fetchedAgain = await service.getEquipmentById('crud_test_01');
      expect(fetchedAgain!.price, 42.0);
      expect(fetchedAgain.availability, false);
    });

    test('Toggle availability updates status quickly', () async {
      await service.toggleAvailability('crud_test_01', true);
      final item = await service.getEquipmentById('crud_test_01');
      expect(item!.availability, true);

      await service.toggleAvailability('crud_test_01', false);
      final itemPaused = await service.getEquipmentById('crud_test_01');
      expect(itemPaused!.availability, false);
    });

    test('Delete: removes equipment from the system', () async {
      await service.deleteEquipment('crud_test_01');
      final fetched = await service.getEquipmentById('crud_test_01');
      expect(fetched, isNull);
    });
  });

  group('Equipment Widgets Tests', () {
    testWidgets('CategorySelector renders categories and handles selection',
        (tester) async {
      String selected = 'mountain_bikes';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CategorySelector(
                  selectedCategoryId: selected,
                  onCategoryChanged: (catId) {
                    setState(() => selected = catId);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Select Category'), findsOneWidget);
      expect(find.text('Mountain Bikes'), findsOneWidget);
      expect(find.text('Camping & Hiking'), findsOneWidget);
      expect(find.text('Water Sports'), findsOneWidget);

      // Tap Camping
      await tester.tap(find.text('Camping & Hiking'));
      await tester.pumpAndSettle();
      expect(selected, 'camping');
    });

    testWidgets('EquipmentCard displays gear data and responds to tap',
        (tester) async {
      bool tapped = false;
      bool edited = false;
      bool deleted = false;
      bool toggled = false;

      final item = Equipment(
        id: 'widget_eq_1',
        ownerId: 'owner_w',
        name: 'Specialized Stumpjumper',
        categoryId: 'mountain_bikes',
        description: 'Full suspension mountain bike.',
        price: 50.0,
        availability: true,
        image: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        location: 'Denver, CO',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EquipmentCard(
              equipment: item,
              onTap: () => tapped = true,
              onEdit: () => edited = true,
              onDelete: () => deleted = true,
              onToggleAvailability: (_) => toggled = true,
            ),
          ),
        ),
      );

      expect(find.text('Specialized Stumpjumper'), findsOneWidget);
      expect(find.text('\$50'), findsOneWidget);
      expect(find.text('Denver, CO'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);

      // Tap card
      await tester.tap(find.text('Specialized Stumpjumper'));
      expect(tapped, isTrue);

      // Tap edit button
      await tester.tap(find.byIcon(Icons.edit_outlined));
      expect(edited, isTrue);

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(deleted, isTrue);

      // Toggle switch
      await tester.tap(find.byType(Switch));
      expect(toggled, isTrue);
    });
  });
}
