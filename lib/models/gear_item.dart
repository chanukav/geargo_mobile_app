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
  /// Firestore equipment document id when sourced from live listings.
  final String? listingId;
  final String? ownerId;
  final String? description;

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
    this.listingId,
    this.ownerId,
    this.description,
  });
}

const List<String> gearCategories = [
  'All',
  'Cricket',
  'Football',
  'Badminton',
  'Cycling',
  'Gym',
  'Surfing',
  'Hiking',
  'Skiing',
];

const List<GearItem> sampleGear = [];

