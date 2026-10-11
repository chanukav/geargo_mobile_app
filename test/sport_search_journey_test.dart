import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geargo/models/gear_item.dart';
import 'package:geargo/screens/home/filter_screen.dart';
import 'package:geargo/screens/home/sport_search_results_screen.dart';
import 'package:geargo/screens/home/tabs/search_tab.dart';

const List<GearItem> testFootballGear = [
  GearItem(
    name: 'Football Size 5',
    owner: 'Ahmad F.',
    category: 'Football',
    image: 'assets/images/gear_football.jpg',
    rating: 4.8,
    reviews: 24,
    distanceKm: 1.2,
    pricePerDay: 10,
    available: true,
    verified: true,
  ),
  GearItem(
    name: 'Football Boots',
    owner: 'Danial H.',
    category: 'Football',
    image: 'assets/images/gear_football_boots.jpg',
    rating: 4.9,
    reviews: 19,
    distanceKm: 2.5,
    pricePerDay: 15,
    available: true,
    verified: true,
  ),
  GearItem(
    name: 'Goalkeeper Gloves',
    owner: 'Hakim R.',
    category: 'Football',
    image: 'assets/images/gear_gloves.jpg',
    rating: 4.6,
    reviews: 14,
    distanceKm: 3.0,
    pricePerDay: 12,
    available: false,
    verified: true,
  ),
  GearItem(
    name: 'Training Cones (Set)',
    owner: 'Subash T.',
    category: 'Football',
    image: 'assets/images/gear_cones.jpg',
    rating: 4.7,
    reviews: 31,
    distanceKm: 4.8,
    pricePerDay: 8,
    available: true,
    verified: true,
  ),
  GearItem(
    name: 'Football Jersey',
    owner: 'Zul K.',
    category: 'Football',
    image: 'assets/images/gear_jersey.jpg',
    rating: 4.8,
    reviews: 16,
    distanceKm: 4.9,
    pricePerDay: 12,
    available: true,
    verified: true,
  ),
];

void main() {
  testWidgets('Screen 1: Home / Search Screen renders all wireframe elements',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SearchTab()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify SportShare branding
    expect(find.text('SportShare'), findsOneWidget);
    expect(find.text('Rent • Play • Share'), findsOneWidget);

    // Verify search text field
    expect(find.text('What equipment do you need?'), findsOneWidget);

    // Verify location dropdown
    expect(find.text('Current Location'), findsOneWidget);

    // Verify Browse by Sport section
    expect(find.text('Browse by Sport'), findsOneWidget);

    // Verify the 6 sport tiles
    expect(find.text('Cricket'), findsOneWidget);
    expect(find.text('Football'), findsOneWidget);
    expect(find.text('Badminton'), findsOneWidget);
    expect(find.text('Cycling'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    // Verify Search Equipment CTA button
    expect(find.text('Search Equipment'), findsOneWidget);
  });

  testWidgets(
      'Screen 2 & 4: Search Results renders location banner, filter/sort, and item cards',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SportSearchResultsScreen(
          initialFilters: GearFilters(
            categories: {'Football'},
            distanceKm: 5.0,
            availableNow: false,
            location: 'Current Location',
          ),
          initialCatalog: testFootballGear,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify App Bar
    expect(find.text('Search Results'), findsOneWidget);

    // Verify Location info card
    expect(find.text('Football equipment near you'), findsOneWidget);
    expect(find.text('Within 5 km • Current Location'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);

    // Verify Filter and Sort buttons
    expect(find.text('Filter (1)'), findsOneWidget);
    expect(find.text('Sort'), findsOneWidget);

    // Verify items from wireframe
    expect(find.text('Football Size 5'), findsOneWidget);
    expect(find.text('Football Boots'), findsOneWidget);
    expect(find.text('Goalkeeper Gloves'), findsOneWidget);
    expect(find.text('Training Cones (Set)'), findsOneWidget);

    // Verify prices & status badges
    expect(find.text('RM 10 / day'), findsOneWidget);
    expect(find.text('RM 15 / day'), findsOneWidget);
    expect(find.text('RM 12 / day'), findsWidgets);
    expect(find.text('RM 8 / day'), findsOneWidget);

    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('Available Now'), findsWidgets);

    // Verify View Details action buttons
    expect(find.text('View Details'), findsWidgets);
  });

  testWidgets(
      'Screen 3: Filter Screen allows toggling sports, distances, availability',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: FilterScreen(
          initial: GearFilters(
            categories: {'Football'},
            distanceKm: 5.0,
            availableNow: true,
          ),
          catalog: testFootballGear,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Filter Screen sections
    expect(find.text('Filter Equipment'), findsOneWidget);
    expect(find.text('Sport / Activity'), findsOneWidget);
    expect(find.text('Location / Distance'), findsOneWidget);
    expect(find.text('Availability'), findsOneWidget);

    // Verify sports options
    expect(find.text('Cricket'), findsOneWidget);
    expect(find.text('Football'), findsOneWidget);
    expect(find.text('Badminton'), findsOneWidget);
    expect(find.text('Cycling'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);

    // Verify distance options
    expect(find.text('Within 1 km'), findsOneWidget);
    expect(find.text('Within 5 km'), findsOneWidget);
    expect(find.text('Within 10 km'), findsOneWidget);
    expect(find.text('Within 20 km'), findsOneWidget);

    // Verify availability options
    expect(find.text('Available Now'), findsOneWidget);
    expect(find.text('Available on Selected Date'), findsOneWidget);
    expect(find.text('Select Date'), findsOneWidget);

    // Verify action buttons
    expect(find.textContaining('Apply Filters'), findsOneWidget);
    expect(find.text('Clear All'), findsOneWidget);
  });
}
