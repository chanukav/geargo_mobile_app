/// Rental listing shown on the Home and Search screens.
class GearItem {
  final String name;
  final String owner;
  final String category;
  final String image;
  final double rating;
  final int reviews;
  final double distanceKm;
  final int pricePerDay;
  final bool available;
  final bool verified;

  const GearItem({
    required this.name,
    required this.owner,
    required this.category,
    required this.image,
    required this.rating,
    required this.reviews,
    required this.distanceKm,
    required this.pricePerDay,
    this.available = true,
    this.verified = true,
  });
}

const List<String> gearCategories = [
  'All',
  'Cricket',
  'Badminton',
  'Cycling',
  'Surfing',
  'Hiking',
  'Skiing',
];

const List<GearItem> sampleGear = [
  GearItem(
    name: 'Kookaburra Pro Cricket Kit',
    owner: 'Kasun M.',
    category: 'Cricket',
    image: 'assets/images/gear_cricket_kit.jpg',
    rating: 4.9,
    reviews: 46,
    distanceKm: 1.8,
    pricePerDay: 35,
    available: true,
    verified: true,
  ),
  GearItem(
    name: 'Yonex Astrox Badminton Set',
    owner: 'Shanuka P.',
    category: 'Badminton',
    image: 'assets/images/gear_badminton_set.jpg',
    rating: 4.9,
    reviews: 32,
    distanceKm: 1.4,
    pricePerDay: 20,
    available: true,
    verified: true,
  ),
  GearItem(
    name: 'Kingsley Reserve Cricket Bat',
    owner: 'Mahesh D.',
    category: 'Cricket',
    image: 'assets/images/gear_cricket_bat.jpg',
    rating: 5.0,
    reviews: 28,
    distanceKm: 2.2,
    pricePerDay: 25,
    available: true,
    verified: true,
  ),
  GearItem(
    name: 'Specialized Stumpjumper',
    owner: 'Marcus V.',
    category: 'Cycling',
    image: 'assets/images/gear_bike_red.jpg',
    rating: 4.9,
    reviews: 38,
    distanceKm: 1.2,
    pricePerDay: 45,
  ),
  GearItem(
    name: 'Solitude Touring Paddleboard',
    owner: 'Elena R.',
    category: 'Surfing',
    image: 'assets/images/gear_sup.jpg',
    rating: 4.8,
    reviews: 54,
    distanceKm: 2.4,
    pricePerDay: 28,
  ),
  GearItem(
    name: 'Osprey Atmos 65 AG',
    owner: 'Dave K.',
    category: 'Hiking',
    image: 'assets/images/gear_backpack.jpg',
    rating: 4.7,
    reviews: 22,
    distanceKm: 0.8,
    pricePerDay: 15,
    available: false,
    verified: false,
  ),
  GearItem(
    name: 'Black Crows Camox Skis',
    owner: 'Sarah L.',
    category: 'Skiing',
    image: 'assets/images/gear_skis.jpg',
    rating: 4.9,
    reviews: 17,
    distanceKm: 3.1,
    pricePerDay: 50,
  ),
  GearItem(
    name: 'Specialized Rockhopper Comp',
    owner: 'Marcus V.',
    category: 'Cycling',
    image: 'assets/images/gear_bike_black.jpg',
    rating: 4.9,
    reviews: 38,
    distanceKm: 1.5,
    pricePerDay: 32,
  ),
  GearItem(
    name: 'Trek Roscoe 8 Trail Bike',
    owner: 'Elena R.',
    category: 'Cycling',
    image: 'assets/images/gear_bike_yellow.jpg',
    rating: 4.8,
    reviews: 54,
    distanceKm: 2.8,
    pricePerDay: 40,
  ),
  GearItem(
    name: 'Santa Cruz Hightower Carbon',
    owner: 'Dave K.',
    category: 'Cycling',
    image: 'assets/images/gear_bike_green.jpg',
    rating: 5.0,
    reviews: 12,
    distanceKm: 3.4,
    pricePerDay: 65,
    verified: false,
  ),
  GearItem(
    name: 'Giant Talon 2 Hardtail',
    owner: 'Sarah L.',
    category: 'Cycling',
    image: 'assets/images/gear_bike_blue.jpg',
    rating: 4.6,
    reviews: 22,
    distanceKm: 4.1,
    pricePerDay: 25,
  ),
];
