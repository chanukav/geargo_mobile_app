import 'package:flutter/foundation.dart';

import '../models/equipment.dart';
import '../models/equipment_review.dart';
import 'equipment_service.dart';
import 'review_service.dart';
import 'user_service.dart';

/// Database Seeder Service.
/// Seeds and syncs sample equipment data into Cloud Firestore
/// with explicit 1-to-N equipment review relationships and persona users.
class DatabaseSeederService {
  static final DatabaseSeederService _instance =
      DatabaseSeederService._internal();
  factory DatabaseSeederService() => _instance;
  DatabaseSeederService._internal();

  final EquipmentService _equipmentService = EquipmentService();
  final ReviewService _reviewService = ReviewService();
  final UserService _userService = UserService();

  /// Initial sample equipment items to seed into the database.
  static final List<Equipment> sampleEquipmentList = [
    Equipment(
      id: 'gear_specialized_stumpjumper',
      ownerId: 'owner_default',
      name: 'Specialized Stumpjumper EVO Comp Bike',
      categoryId: 'mountain_bikes',
      description:
          'Mechanically perfect, freshly tuned, cleaned after every rental. FOX Float 36 Rhythm fork, SRAM NX Eagle 12-speed drivetrain with hydraulic 4-piston disc brakes.',
      price: 1850.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1576435728678-68d0fbf94e91?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      condition: 'Excellent / Like New',
      location: 'Colombo 07, Cinnamon Gardens',
      rating: 4.9,
      reviewsCount: 3,
    ),
    Equipment(
      id: 'gear_giro_manifest',
      ownerId: 'owner_default',
      name: 'Giro Manifest Spheric Helmet',
      categoryId: 'mountain_bikes',
      description:
          'MIPS Spheric technology trail helmet, size Medium. Superior ventilation and impact management, thoroughly sanitized after every ride.',
      price: 1100.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      condition: 'Like New',
      location: 'Colombo, Sri Lanka',
      rating: 4.9,
      reviewsCount: 2,
    ),
    Equipment(
      id: 'gear_north_face_tent',
      ownerId: 'owner_default',
      name: 'The North Face Wawona Tent',
      categoryId: 'camping',
      description:
          'Spacious 6-person car camping tent with massive vestibule, hybrid double-wall construction, and color-coded poles for 10-minute setup.',
      price: 1650.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      condition: 'Excellent',
      location: 'Kandy, Sri Lanka',
      rating: 4.7,
      reviewsCount: 2,
    ),
    Equipment(
      id: 'gear_babolat_pure_drive',
      ownerId: 'owner_default',
      name: 'Babolat Pure Drive Tennis Racket',
      categoryId: 'fitness',
      description:
          'Legendary power and spin racket with fresh Babolat RPM Blast 16G strings at 54 lbs tension. 4 3/8 grip size with new overgrip.',
      price: 1350.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1622279457486-62dcc4a431d6?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      condition: 'Very Good',
      location: 'Colombo, Sri Lanka',
      rating: 4.6,
      reviewsCount: 1,
    ),
    Equipment(
      id: 'gear_trekking_poles',
      ownerId: 'owner_default',
      name: 'Black Diamond Trekking Poles',
      categoryId: 'camping',
      description:
          'Trail Pro shock-absorbing carbon fiber hiking poles with FlickLock Pro adjustments and natural cork grips.',
      price: 1200.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1551632811-561732d1e306?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      condition: 'Excellent',
      location: 'Ella, Sri Lanka',
      rating: 4.8,
      reviewsCount: 1,
    ),
    Equipment(
      id: 'gear_specialized_rockhopper_comp',
      ownerId: 'owner_default',
      name: 'Specialized Rockhopper Comp',
      categoryId: 'mountain_bikes',
      description:
          'Lightweight A1 Premium aluminum hardtail mountain bike with Shimano Deore 1x10 drivetrain and SR Suntour XCM suspension fork.',
      price: 1700.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1485965120184-e220f721d03e?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      condition: 'Excellent',
      location: 'Galle, Sri Lanka',
      rating: 4.9,
      reviewsCount: 1,
    ),
    Equipment(
      id: 'gear_torq_surfboard',
      ownerId: 'user_shop_apex',
      name: 'Torq Mod Fun 7\'2" Surfboard',
      categoryId: 'surfing',
      description:
          'Versatile epoxy funboard shaped for mid-length wave cruising in Mirissa and Weligama. Includes thruster fins and 7ft leash.',
      price: 1800.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1502680390469-be75c86b636f?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      condition: 'Excellent',
      location: 'Mirissa, Sri Lanka',
      rating: 5.0,
      reviewsCount: 2,
    ),
    Equipment(
      id: 'gear_ss_ton_cricket_bat',
      ownerId: 'owner_default',
      name: 'SS Ton Professional English Willow Bat',
      categoryId: 'cricket',
      description:
          'Handcrafted Grade 1 English Willow cricket bat, professionally knocked-in with anti-scuff sheet and toe guard. Superb balance.',
      price: 1500.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1531415074868-036b107e775a?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      condition: 'Like New',
      location: 'Colombo 05 (Havelock), Sri Lanka',
      rating: 4.8,
      reviewsCount: 1,
    ),
    Equipment(
      id: 'gear_yonex_astrox_badminton',
      ownerId: 'user_shop_apex',
      name: 'Yonex Astrox 88D Pro Badminton Racket',
      categoryId: 'badminton',
      description:
          'Head-heavy offensive doubles racket, strung with Yonex BG80 at 26 lbs tension with cushioned overgrip.',
      price: 1400.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      condition: 'Like New',
      location: 'Negombo, Sri Lanka',
      rating: 4.9,
      reviewsCount: 1,
    ),
    Equipment(
      id: 'gear_adidas_match_ball',
      ownerId: 'owner_default',
      name: 'Adidas FIFA Pro Official Match Ball',
      categoryId: 'football',
      description:
          'Thermally bonded seamless construction for predictable flight trajectory and low water uptake on grass and turf pitches.',
      price: 1150.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
      condition: 'Brand New',
      location: 'Colombo 07, Sri Lanka',
      rating: 5.0,
      reviewsCount: 1,
    ),
    Equipment(
      id: 'gear_deuter_aircontact_backpack',
      ownerId: 'user_shop_apex',
      name: 'Deuter Aircontact Lite 50+10L Backpack',
      categoryId: 'hiking',
      description:
          'Ergonomic trekking backpack with adjustable back length, rain cover, and trekking pole loops. Perfect for Horton Plains or Ella hikes.',
      price: 1300.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      condition: 'Like New',
      location: 'Ella, Sri Lanka',
      rating: 4.9,
      reviewsCount: 1,
    ),
    Equipment(
      id: 'gear_kookaburra_cricket_kit',
      ownerId: 'user_shop_apex',
      name: 'Kookaburra Kahuna Complete Kit Bag',
      categoryId: 'cricket',
      description:
          'Full protective match kit including batting pads, gloves, thigh guard, inner pads, and certified cricket helmet.',
      price: 1950.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      condition: 'Very Good',
      location: 'Colombo 08 (Borella), Sri Lanka',
      rating: 4.8,
      reviewsCount: 1,
    ),
  ];

  /// Initial sample reviews where each review belongs to exactly one equipment item (1-to-N).
  static final List<EquipmentReview> sampleReviewsList = [
    // Reviews belonging to Specialized Stumpjumper (gear_specialized_stumpjumper)
    EquipmentReview(
      id: 'seed_review_stumpjumper_01',
      equipmentId: 'gear_specialized_stumpjumper',
      ownerId: 'owner_default',
      authorId: 'user_sarah_k',
      authorName: 'Sarah K.',
      rating: 5,
      comment:
          'Perfect bike for the Duthie Hill trails! Marcus was great at setup. Highly recommend.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      equipmentName: 'Specialized Stumpjumper EVO Comp Bike',
    ),
    EquipmentReview(
      id: 'seed_review_stumpjumper_02',
      equipmentId: 'gear_specialized_stumpjumper',
      ownerId: 'owner_default',
      authorId: 'user_david_m',
      authorName: 'David M.',
      rating: 5,
      comment:
          'Super smooth suspension and well maintained. Marcus even gave trail recommendations!',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      equipmentName: 'Specialized Stumpjumper EVO Comp Bike',
    ),
    EquipmentReview(
      id: 'seed_review_stumpjumper_03',
      equipmentId: 'gear_specialized_stumpjumper',
      ownerId: 'owner_default',
      authorId: 'user_liam_w',
      authorName: 'Liam W.',
      rating: 5,
      comment:
          'Immaculate condition, hydraulic disc brakes gripped flawlessly on downhill descents.',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      equipmentName: 'Specialized Stumpjumper EVO Comp Bike',
    ),

    // Reviews belonging to Giro Manifest Helmet (gear_giro_manifest)
    EquipmentReview(
      id: 'seed_review_giro_01',
      equipmentId: 'gear_giro_manifest',
      ownerId: 'owner_default',
      authorId: 'user_alex_t',
      authorName: 'Alex T.',
      rating: 5,
      comment:
          'High quality helmet, fits true to size and sanitized before handoff.',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      equipmentName: 'Giro Manifest Spheric Helmet',
    ),
    EquipmentReview(
      id: 'seed_review_giro_02',
      equipmentId: 'gear_giro_manifest',
      ownerId: 'owner_default',
      authorId: 'user_chris_b',
      authorName: 'Chris B.',
      rating: 5,
      comment: 'Very lightweight with MIPS protection. Friendly pickup.',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      equipmentName: 'Giro Manifest Spheric Helmet',
    ),

    // Reviews belonging to The North Face Tent (gear_north_face_tent)
    EquipmentReview(
      id: 'seed_review_tent_01',
      equipmentId: 'gear_north_face_tent',
      ownerId: 'owner_default',
      authorId: 'user_jessica_p',
      authorName: 'Jessica P.',
      rating: 4,
      comment:
          'Spacious and easy to assemble tent. All poles and pegs accounted for.',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      equipmentName: 'The North Face Wawona Tent',
    ),
    EquipmentReview(
      id: 'seed_review_tent_02',
      equipmentId: 'gear_north_face_tent',
      ownerId: 'owner_default',
      authorId: 'user_mark_d',
      authorName: 'Mark D.',
      rating: 5,
      comment: 'Waterproof held up great in thunderstorm. Highly recommended.',
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      equipmentName: 'The North Face Wawona Tent',
    ),

    // Reviews belonging to Babolat Pure Drive (gear_babolat_pure_drive)
    EquipmentReview(
      id: 'seed_review_babolat_01',
      equipmentId: 'gear_babolat_pure_drive',
      ownerId: 'owner_default',
      authorId: 'user_michael_c',
      authorName: 'Michael C.',
      rating: 5,
      comment:
          'Strings in great tension, great control on court. Host was very communicative.',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      equipmentName: 'Babolat Pure Drive Tennis Racket',
    ),

    // Reviews belonging to Trekking Poles (gear_trekking_poles)
    EquipmentReview(
      id: 'seed_review_poles_01',
      equipmentId: 'gear_trekking_poles',
      ownerId: 'owner_default',
      authorId: 'user_hannah_g',
      authorName: 'Hannah G.',
      rating: 5,
      comment: 'Sturdy carbon poles, saved my knees on the steep descent.',
      createdAt: DateTime.now().subtract(const Duration(days: 16)),
      equipmentName: 'Black Diamond Trekking Poles',
    ),

    // Reviews belonging to Rockhopper Comp (gear_specialized_rockhopper_comp)
    EquipmentReview(
      id: 'seed_review_rockhopper_01',
      equipmentId: 'gear_specialized_rockhopper_comp',
      ownerId: 'owner_default',
      authorId: 'user_ryan_b',
      authorName: 'Ryan B.',
      rating: 5,
      comment:
          'Great hardtail for local trail loops. Brakes and gear shifts were flawless.',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      equipmentName: 'Specialized Rockhopper Comp',
    ),

    // Reviews belonging to Torq Surfboard (gear_torq_surfboard)
    EquipmentReview(
      id: 'seed_review_surfboard_01',
      equipmentId: 'gear_torq_surfboard',
      ownerId: 'user_shop_apex',
      authorId: 'user_tariq_a',
      authorName: 'Tariq A.',
      rating: 5,
      comment:
          'Super fun board at Weligama bay! Responsive and buoyant, wax was fresh.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      equipmentName: 'Torq Mod Fun 7\'2" Surfboard',
    ),
    EquipmentReview(
      id: 'seed_review_surfboard_02',
      equipmentId: 'gear_torq_surfboard',
      ownerId: 'user_shop_apex',
      authorId: 'user_charlotte_w',
      authorName: 'Charlotte W.',
      rating: 5,
      comment:
          'Apex shop staff in Mirissa were very helpful and gave great swell tips.',
      createdAt: DateTime.now().subtract(const Duration(days: 11)),
      equipmentName: 'Torq Mod Fun 7\'2" Surfboard',
    ),

    // Reviews belonging to SS Ton Cricket Bat (gear_ss_ton_cricket_bat)
    EquipmentReview(
      id: 'seed_review_cricket_01',
      equipmentId: 'gear_ss_ton_cricket_bat',
      ownerId: 'owner_default',
      authorId: 'user_dinesh_p',
      authorName: 'Dinesh P.',
      rating: 5,
      comment:
          'Incredible ping and balanced pickup! Made our weekend match in Colombo a blast.',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      equipmentName: 'SS Ton Professional English Willow Bat',
    ),

    // Reviews belonging to Yonex Astrox Badminton Racket (gear_yonex_astrox_badminton)
    EquipmentReview(
      id: 'seed_review_badminton_01',
      equipmentId: 'gear_yonex_astrox_badminton',
      ownerId: 'user_shop_apex',
      authorId: 'user_kaveen_s',
      authorName: 'Kaveen S.',
      rating: 5,
      comment:
          'Strings had sharp bite and punchy smashes on indoor court. Clean grip.',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      equipmentName: 'Yonex Astrox 88D Pro Badminton Racket',
    ),

    // Reviews belonging to Adidas Match Ball (gear_adidas_match_ball)
    EquipmentReview(
      id: 'seed_review_football_01',
      equipmentId: 'gear_adidas_match_ball',
      ownerId: 'owner_default',
      authorId: 'user_samuel_k',
      authorName: 'Samuel K.',
      rating: 5,
      comment:
          'Authentic match ball with great flight and touch. Owner provided pump and needle.',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      equipmentName: 'Adidas FIFA Pro Official Match Ball',
    ),

    // Reviews belonging to Deuter Backpack (gear_deuter_aircontact_backpack)
    EquipmentReview(
      id: 'seed_review_deuter_01',
      equipmentId: 'gear_deuter_aircontact_backpack',
      ownerId: 'user_shop_apex',
      authorId: 'user_amaya_f',
      authorName: 'Amaya F.',
      rating: 5,
      comment:
          'Hiked Ella Rock with full load and the harness distributed weight like a dream.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      equipmentName: 'Deuter Aircontact Lite 50+10L Backpack',
    ),

    // Reviews belonging to Kookaburra Kit (gear_kookaburra_cricket_kit)
    EquipmentReview(
      id: 'seed_review_kookaburra_01',
      equipmentId: 'gear_kookaburra_cricket_kit',
      ownerId: 'user_shop_apex',
      authorId: 'user_malik_r',
      authorName: 'Malik R.',
      rating: 5,
      comment:
          'All pads, gloves, and helmet were clean and well-padded. Excellent value.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      equipmentName: 'Kookaburra Kahuna Complete Kit Bag',
    ),
  ];

  /// Seeds all sample equipment and reviews into Firestore database.
  /// If [force] is true, overwrites existing documents.
  Future<SeederResult> seedEquipmentAndReviews({bool force = false}) async {
    debugPrint('Starting DatabaseSeederService sync...');
    int eqCount = 0;
    int revCount = 0;
    int personaCount = 0;
    final List<String> warnings = [];

    // 1. Seed Equipment into database
    for (final eq in sampleEquipmentList) {
      try {
        await _equipmentService.createEquipment(eq);
        eqCount++;
      } catch (e) {
        warnings.add('Equipment ${eq.id}: $e');
        debugPrint('Equipment seed warning for ${eq.id}: $e');
      }
    }

    // 2. Seed Reviews into database (enforcing 1 review -> 1 equipment relationship)
    for (final rev in sampleReviewsList) {
      try {
        await _reviewService.saveReviewToDatabase(rev);
        revCount++;
      } catch (e) {
        warnings.add('Review ${rev.id}: $e');
        debugPrint('Review seed warning for ${rev.id}: $e');
      }
    }

    // 3. Sync aggregate rating and count for each equipment
    for (final eq in sampleEquipmentList) {
      final reviews = sampleReviewsList
          .where((r) => r.equipmentId == eq.id)
          .toList();
      if (reviews.isNotEmpty) {
        final total = reviews.fold<double>(
            0.0, (acc, curr) => acc + curr.rating.toDouble());
        final avg =
            double.parse((total / reviews.length).toStringAsFixed(2));
        await _equipmentService.updateReviewStats(eq.id, avg, reviews.length);
      }
    }

    // 4. Seed Persona Users into database (Renter, Gear Owner, Commercial Shop, Admin)
    try {
      await _userService.seedPersonaUsers();
      personaCount = 4;
    } catch (e) {
      warnings.add('Personas: $e');
      debugPrint('Persona users seed warning: $e');
    }

    final message = warnings.isEmpty
        ? 'Successfully seeded $eqCount equipment, $revCount reviews, and $personaCount personas to database.'
        : 'Seeded $eqCount items with warnings: ${warnings.join(", ")}';
    debugPrint('DatabaseSeederService: $message');

    return SeederResult(
      success: eqCount > 0,
      equipmentCount: eqCount,
      reviewCount: revCount,
      personaCount: personaCount,
      message: message,
    );
  }
}

/// Result of a database seeding operation.
class SeederResult {
  final bool success;
  final int equipmentCount;
  final int reviewCount;
  final int personaCount;
  final String message;

  const SeederResult({
    required this.success,
    required this.equipmentCount,
    required this.reviewCount,
    required this.personaCount,
    required this.message,
  });
}
