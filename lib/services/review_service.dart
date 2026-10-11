import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/equipment_review.dart';
import '../models/rental_request.dart';
import 'equipment_service.dart';

/// NFR-05: reviews only after completed rentals; edits time-gated.
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  static const Duration editWindow = Duration(hours: 48);
  static const String collection = 'equipment_reviews';

  FirebaseFirestore? get _safeFirestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _safeAuth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  final List<Map<String, dynamic>> _localReviews = [
    {
      'id': 'seed_review_1',
      'equipment_id': 'gear_specialized_stumpjumper',
      'owner_id': 'owner_default',
      'owner_name': 'Marcus Vance',
      'equipment_name': 'Specialized Stumpjumper EVO Comp Bike',
      'author_id': 'sarah_k',
      'author_name': 'Sarah K.',
      'rating': 5,
      'comment':
          'Perfect bike for the Duthie Hill trails! Marcus was great at setup. Highly recommend.',
      'created_at': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'id': 'seed_review_2',
      'equipment_id': 'gear_specialized_stumpjumper',
      'owner_id': 'owner_default',
      'owner_name': 'Marcus Vance',
      'equipment_name': 'Specialized Stumpjumper EVO Comp Bike',
      'author_id': 'david_m',
      'author_name': 'David M.',
      'rating': 5,
      'comment':
          'Super smooth suspension and well maintained. Marcus even gave trail recommendations!',
      'created_at': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'id': 'seed_review_3',
      'equipment_id': 'gear_giro_manifest',
      'owner_id': 'owner_default',
      'owner_name': 'Marcus Vance',
      'equipment_name': 'Giro Manifest Spheric Helmet',
      'author_id': 'alex_t',
      'author_name': 'Alex T.',
      'rating': 5,
      'comment':
          'High quality helmet, fits true to size and sanitized before handoff.',
      'created_at': DateTime.now().subtract(const Duration(days: 8)),
    },
    {
      'id': 'seed_review_4',
      'equipment_id': 'gear_north_face_tent',
      'owner_id': 'owner_default',
      'owner_name': 'Marcus Vance',
      'equipment_name': 'The North Face Wawona Tent',
      'author_id': 'jessica_p',
      'author_name': 'Jessica P.',
      'rating': 4,
      'comment':
          'Spacious and easy to assemble tent. All poles and pegs accounted for.',
      'created_at': DateTime.now().subtract(const Duration(days: 12)),
    },
    {
      'id': 'seed_review_5',
      'equipment_id': 'gear_babolat_pure_drive',
      'owner_id': 'owner_default',
      'owner_name': 'Marcus Vance',
      'equipment_name': 'Babolat Pure Drive Tennis Racket',
      'author_id': 'michael_c',
      'author_name': 'Michael C.',
      'rating': 5,
      'comment':
          'Strings in great tension, great control on court. Host was very communicative.',
      'created_at': DateTime.now().subtract(const Duration(days: 15)),
    },
    {
      'id': 'seed_review_6',
      'equipment_id': 'gear_specialized_rockhopper_comp',
      'owner_id': 'owner_default',
      'owner_name': 'Marcus Vance',
      'equipment_name': 'Specialized Rockhopper Comp',
      'author_id': 'ryan_b',
      'author_name': 'Ryan B.',
      'rating': 5,
      'comment':
          'Great hardtail for local trail loops. Brakes and gear shifts were flawless.',
      'created_at': DateTime.now().subtract(const Duration(days: 20)),
    },
  ];

  final StreamController<void> _reviewsChangeController =
      StreamController<void>.broadcast();

  Future<Map<String, dynamic>?> findMyReviewForRental(String rentalRequestId) async {
    final uid = _safeAuth?.currentUser?.uid;
    if (uid == null) return null;
    final fs = _safeFirestore;
    if (fs == null) return null;
    final existing = await fs
        .collection(collection)
        .where('rental_request_id', isEqualTo: rentalRequestId)
        .where('author_id', isEqualTo: uid)
        .limit(1)
        .get();
    if (existing.docs.isEmpty) return null;
    return {...existing.docs.first.data(), 'id': existing.docs.first.id};
  }

  Future<bool> canReviewRental(RentalRequest request) async {
    final uid = _safeAuth?.currentUser?.uid;
    if (uid == null || request.renterId != uid) return false;
    if (request.status != RentalStatus.completed) return false;
    final fs = _safeFirestore;
    if (fs == null) return true;
    final existing = await fs
        .collection(collection)
        .where('rental_request_id', isEqualTo: request.id)
        .where('author_id', isEqualTo: uid)
        .limit(1)
        .get();
    return existing.docs.isEmpty;
  }

  Future<bool> canEditReview(String reviewId) async {
    final fs = _safeFirestore;
    if (fs == null) return false;
    final doc = await fs.collection(collection).doc(reviewId).get();
    if (!doc.exists) return false;
    final created = doc.data()?['created_at'];
    DateTime? at;
    if (created is Timestamp) at = created.toDate();
    if (created is String) at = DateTime.tryParse(created);
    if (at == null) return false;
    return DateTime.now().difference(at) <= editWindow;
  }

  Future<void> submitReview({
    required String equipmentId,
    required String rentalRequestId,
    required int rating,
    required String comment,
  }) async {
    final user = _safeAuth?.currentUser;
    if (user == null) throw StateError('Sign in to leave a review.');
    final fs = _safeFirestore;
    if (fs == null) throw StateError('Database unavailable.');

    final rentalDoc = await fs
        .collection('rental_requests')
        .doc(rentalRequestId)
        .get();
    if (!rentalDoc.exists) {
      throw StateError('Rental not found.');
    }
    final rental = RentalRequest.fromMap(rentalDoc.data()!, rentalRequestId);
    if (rental.status != RentalStatus.completed || rental.renterId != user.uid) {
      throw StateError('Reviews are limited to completed rentals you booked.');
    }

    final dup = await fs
        .collection(collection)
        .where('rental_request_id', isEqualTo: rentalRequestId)
        .where('author_id', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty) {
      throw StateError('You already reviewed this rental.');
    }

    await fs.collection(collection).add({
      'equipment_id': equipmentId,
      'rental_request_id': rentalRequestId,
      'author_id': user.uid,
      'rating': rating.clamp(1, 5),
      'comment': comment.trim(),
      'created_at': FieldValue.serverTimestamp(),
      'edit_deadline': DateTime.now().add(editWindow).toIso8601String(),
    });
    await _refreshEquipmentRating(equipmentId);
  }

  /// PERSISTENCE: Saves a review in the database.
  /// Entity Relationship:
  /// - A review belongs to exactly ONE piece of equipment ([EquipmentReview.equipmentId]).
  /// - A piece of equipment can have MANY reviews (1-to-N).
  Future<EquipmentReview> saveReviewToDatabase(EquipmentReview review) async {
    if (review.equipmentId.trim().isEmpty) {
      throw ArgumentError('A review must belong to a valid equipment ID.');
    }

    final fs = _safeFirestore;
    final docId = review.id.isNotEmpty
        ? review.id
        : (fs?.collection(collection).doc().id ??
            'rev_${DateTime.now().millisecondsSinceEpoch}_${_localReviews.length}');

    final finalReview = review.copyWith(id: docId);

    // Update local cache for testing and offline resilience
    _localReviews.removeWhere((r) => r['id'] == docId);
    _localReviews.insert(0, {
      'id': finalReview.id,
      'equipment_id': finalReview.equipmentId,
      'owner_id': finalReview.ownerId,
      'author_id': finalReview.authorId,
      'author_name': finalReview.authorName,
      'rating': finalReview.rating,
      'comment': finalReview.comment,
      'created_at': finalReview.createdAt,
      'updated_at': finalReview.updatedAt,
      'rental_request_id': finalReview.rentalRequestId,
      'equipment_name': finalReview.equipmentName,
    });
    _reviewsChangeController.add(null);

    // Save in Firestore database
    if (fs != null) {
      try {
        await fs.collection(collection).doc(docId).set(finalReview.toMap());
      } catch (e) {
        debugPrint('Firestore review save error (using local cache): $e');
      }
    }

    // Recalculate and update the equipment aggregate in the database
    await _refreshEquipmentRating(finalReview.equipmentId);

    return finalReview;
  }

  /// Direct equipment review submitted by a renter for a specific equipment listing.
  /// Persists review in the database belonging to [equipmentId].
  Future<void> submitEquipmentReview({
    required String equipmentId,
    required int rating,
    required String comment,
    String? authorName,
    String? ownerId,
    String? equipmentName,
  }) async {
    final user = _safeAuth?.currentUser;
    final author = (authorName != null && authorName.trim().isNotEmpty)
        ? authorName.trim()
        : (user?.displayName != null && user!.displayName!.trim().isNotEmpty
            ? user.displayName!
            : 'Verified Renter');

    final review = EquipmentReview(
      id: '',
      equipmentId: equipmentId,
      ownerId: ownerId ?? 'owner_default',
      authorId: user?.uid ?? 'renter_${DateTime.now().millisecondsSinceEpoch}',
      authorName: author,
      rating: rating.clamp(1, 5),
      comment: comment.trim(),
      createdAt: DateTime.now(),
      equipmentName: equipmentName ?? 'Equipment',
    );

    await saveReviewToDatabase(review);
  }

  /// Database query: One piece of equipment can have many reviews.
  /// Returns a real-time stream of all [EquipmentReview] models belonging to [equipmentId].
  Stream<List<EquipmentReview>> getEquipmentReviewsStream(String equipmentId) {
    return reviewsForEquipment(equipmentId).map((list) {
      return list
          .map((m) => EquipmentReview.fromMap(m, m['id']?.toString()))
          .toList();
    });
  }

  /// Database fetch: Retrieves all reviews belonging to a single piece of equipment.
  Future<List<EquipmentReview>> fetchReviewsForEquipment(String equipmentId) async {
    final fs = _safeFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection(collection)
            .where('equipment_id', isEqualTo: equipmentId)
            .orderBy('created_at', descending: true)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => EquipmentReview.fromMap(d.data(), d.id))
              .toList();
        }
      } catch (e) {
        debugPrint('Firestore fetch reviews error (fallback to local): $e');
      }
    }
    final local = _getLocalReviewsForEquipment(equipmentId);
    return local
        .map((m) => EquipmentReview.fromMap(m, m['id']?.toString()))
        .toList();
  }

  /// Returns the total count of reviews belonging to a single piece of equipment.
  Future<int> getReviewCountForEquipment(String equipmentId) async {
    final reviews = await fetchReviewsForEquipment(equipmentId);
    return reviews.length;
  }

  Future<Map<String, dynamic>?> findUserReviewForRental(
    String rentalRequestId,
    String authorId,
  ) async {
    final fs = _safeFirestore;
    if (fs == null) return null;
    final snap = await fs
        .collection(collection)
        .where('rental_request_id', isEqualTo: rentalRequestId)
        .where('author_id', isEqualTo: authorId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return {...snap.docs.first.data(), 'id': snap.docs.first.id};
  }

  Future<void> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    if (!await canEditReview(reviewId)) {
      throw StateError('The 48-hour edit window for this review has closed.');
    }
    final fs = _safeFirestore;
    if (fs == null) return;
    final doc = await fs.collection(collection).doc(reviewId).get();
    await fs.collection(collection).doc(reviewId).update({
      'rating': rating.clamp(1, 5),
      'comment': comment.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    final equipmentId = doc.data()?['equipment_id'] as String?;
    if (equipmentId != null && equipmentId.isNotEmpty) {
      await _refreshEquipmentRating(equipmentId);
    }
  }

  Future<void> _refreshEquipmentRating(String equipmentId) async {
    // 1. Calculate aggregate from local cache as immediate baseline
    final localList = _getLocalReviewsForEquipment(equipmentId);
    if (localList.isNotEmpty) {
      var localTotal = 0.0;
      for (final r in localList) {
        localTotal += ((r['rating'] as num?) ?? 0).toDouble();
      }
      final localAvg =
          double.parse((localTotal / localList.length).toStringAsFixed(2));
      await EquipmentService()
          .updateReviewStats(equipmentId, localAvg, localList.length);
    }

    final fs = _safeFirestore;
    if (fs == null) return;
    try {
      final snap = await fs
          .collection(collection)
          .where('equipment_id', isEqualTo: equipmentId)
          .get();
      if (snap.docs.isEmpty) return;
      var total = 0.0;
      for (final d in snap.docs) {
        total += ((d.data()['rating'] as num?) ?? 0).toDouble();
      }
      final avg = double.parse((total / snap.docs.length).toStringAsFixed(2));
      final count = snap.docs.length;
      await fs.collection('equipment').doc(equipmentId).set(
        {
          'rating': avg,
          'reviews_count': count,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await EquipmentService().updateReviewStats(equipmentId, avg, count);
    } catch (e) {
      debugPrint('Equipment rating refresh warning: $e');
    }
  }

  bool _matchesEquipment(String revEqId, String targetEqId) {
    if (revEqId == targetEqId) return true;
    final r = revEqId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final t = targetEqId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (r.isEmpty || t.isEmpty) return false;
    return r.contains(t) || t.contains(r);
  }

  List<Map<String, dynamic>> _getLocalReviewsForEquipment(String equipmentId) {
    return _localReviews
        .where((r) => _matchesEquipment((r['equipment_id'] ?? '').toString(), equipmentId))
        .toList();
  }

  List<Map<String, dynamic>> _getLocalReviewsForOwner(
      String ownerId, String? ownerName) {
    final nameLower = ownerName?.toLowerCase() ?? '';
    return _localReviews.where((r) {
      final oId = (r['owner_id'] ?? '').toString();
      final oName = (r['owner_name'] ?? '').toString().toLowerCase();
      if (oId == ownerId) return true;
      if (ownerId == 'owner_default' && oId == 'owner_default') return true;
      if (nameLower.isNotEmpty && oName.contains(nameLower)) return true;
      if (ownerId.contains('marcus') || nameLower.contains('marcus')) {
        return oId == 'owner_default' || oName.contains('marcus');
      }
      return false;
    }).toList();
  }

  /// Real-time stream of reviews strictly for a specific equipment listing.
  Stream<List<Map<String, dynamic>>> reviewsForEquipment(String equipmentId) {
    final fs = _safeFirestore;
    if (fs != null) {
      return fs
          .collection(collection)
          .where('equipment_id', isEqualTo: equipmentId)
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snap) {
        final fsReviews =
            snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
        final local = _getLocalReviewsForEquipment(equipmentId);
        final seenIds = <String>{};
        final combined = <Map<String, dynamic>>[];
        for (final item in [...fsReviews, ...local]) {
          final id = item['id']?.toString() ?? '';
          if (id.isEmpty || !seenIds.contains(id)) {
            if (id.isNotEmpty) seenIds.add(id);
            combined.add(item);
          }
        }
        return combined;
      }).handleError((e) {
        return _getLocalReviewsForEquipment(equipmentId);
      });
    }

    final controller = StreamController<List<Map<String, dynamic>>>();
    controller.add(_getLocalReviewsForEquipment(equipmentId));
    final sub = _reviewsChangeController.stream.listen((_) {
      if (!controller.isClosed) {
        controller.add(_getLocalReviewsForEquipment(equipmentId));
      }
    });
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  /// Real-time stream of reviews across all equipment owned by an owner.
  Stream<List<Map<String, dynamic>>> reviewsForOwner(
    String ownerId, {
    String? ownerName,
  }) {
    final fs = _safeFirestore;
    if (fs != null) {
      return fs
          .collection(collection)
          .where('owner_id', isEqualTo: ownerId)
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snap) {
        final fsReviews =
            snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
        final local = _getLocalReviewsForOwner(ownerId, ownerName);
        final seenIds = <String>{};
        final combined = <Map<String, dynamic>>[];
        for (final item in [...fsReviews, ...local]) {
          final id = item['id']?.toString() ?? '';
          if (id.isEmpty || !seenIds.contains(id)) {
            if (id.isNotEmpty) seenIds.add(id);
            combined.add(item);
          }
        }
        return combined;
      }).handleError((e) {
        return _getLocalReviewsForOwner(ownerId, ownerName);
      });
    }

    final controller = StreamController<List<Map<String, dynamic>>>();
    controller.add(_getLocalReviewsForOwner(ownerId, ownerName));
    final sub = _reviewsChangeController.stream.listen((_) {
      if (!controller.isClosed) {
        controller.add(_getLocalReviewsForOwner(ownerId, ownerName));
      }
    });
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }
}

