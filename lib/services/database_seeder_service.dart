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
      price: 45.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1576435728678-68d0fbf94e91?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      condition: 'Excellent / Like New',
      location: 'Seattle, WA (Duthie Hill)',
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
      price: 8.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      condition: 'Like New',
      location: 'Seattle, WA',
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
      price: 28.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      condition: 'Excellent',
      location: 'Seattle, WA',
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
      price: 15.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1622279457486-62dcc4a431d6?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      condition: 'Very Good',
      location: 'Seattle, WA',
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
      price: 12.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1551632811-561732d1e306?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      condition: 'Excellent',
      location: 'Seattle, WA',
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
      price: 32.0,
      availability: true,
      image:
          'https://images.unsplash.com/photo-1485965120184-e220f721d03e?auto=format&fit=crop&w=1200&q=80',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      condition: 'Excellent',
      location: 'Seattle, WA',
      rating: 4.9,
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
  ];

  /// Seeds all sample equipment and reviews into Firestore database.
  /// If [force] is true, overwrites existing documents.
  Future<void> seedEquipmentAndReviews({bool force = false}) async {
    debugPrint('Starting DatabaseSeederService sync...');

    // 1. Seed Equipment into database
    for (final eq in sampleEquipmentList) {
      try {
        await _equipmentService.createEquipment(eq);
      } catch (e) {
        debugPrint('Equipment seed warning for ${eq.id}: $e');
      }
    }

    // 2. Seed Reviews into database (enforcing 1 review -> 1 equipment relationship)
    for (final rev in sampleReviewsList) {
      try {
        await _reviewService.saveReviewToDatabase(rev);
      } catch (e) {
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
    } catch (e) {
      debugPrint('Persona users seed warning: $e');
    }

    debugPrint('DatabaseSeederService completed successfully.');
  }
}
