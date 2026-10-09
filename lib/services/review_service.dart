import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/rental_request.dart';

/// NFR-05: reviews only after completed rentals; edits time-gated.
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  static const Duration editWindow = Duration(hours: 48);
  static const String collection = 'equipment_reviews';

  Future<Map<String, dynamic>?> findMyReviewForRental(String rentalRequestId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final existing = await FirebaseFirestore.instance
        .collection(collection)
        .where('rental_request_id', isEqualTo: rentalRequestId)
        .where('author_id', isEqualTo: uid)
        .limit(1)
        .get();
    if (existing.docs.isEmpty) return null;
    return {...existing.docs.first.data(), 'id': existing.docs.first.id};
  }

  Future<bool> canReviewRental(RentalRequest request) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || request.renterId != uid) return false;
    if (request.status != RentalStatus.completed) return false;
    final existing = await FirebaseFirestore.instance
        .collection(collection)
        .where('rental_request_id', isEqualTo: request.id)
        .where('author_id', isEqualTo: uid)
        .limit(1)
        .get();
    return existing.docs.isEmpty;
  }

  Future<bool> canEditReview(String reviewId) async {
    final doc =
        await FirebaseFirestore.instance.collection(collection).doc(reviewId).get();
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to leave a review.');

    final rentalDoc = await FirebaseFirestore.instance
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

    final dup = await FirebaseFirestore.instance
        .collection(collection)
        .where('rental_request_id', isEqualTo: rentalRequestId)
        .where('author_id', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty) {
      throw StateError('You already reviewed this rental.');
    }

    await FirebaseFirestore.instance.collection(collection).add({
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

  Future<Map<String, dynamic>?> findUserReviewForRental(
    String rentalRequestId,
    String authorId,
  ) async {
    final snap = await FirebaseFirestore.instance
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
    final doc =
        await FirebaseFirestore.instance.collection(collection).doc(reviewId).get();
    await FirebaseFirestore.instance.collection(collection).doc(reviewId).update({
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
    try {
      final snap = await FirebaseFirestore.instance
          .collection(collection)
          .where('equipment_id', isEqualTo: equipmentId)
          .get();
      if (snap.docs.isEmpty) return;
      var total = 0.0;
      for (final d in snap.docs) {
        total += ((d.data()['rating'] as num?) ?? 0).toDouble();
      }
      final avg = total / snap.docs.length;
      await FirebaseFirestore.instance.collection('equipment').doc(equipmentId).set(
        {
          'rating': double.parse(avg.toStringAsFixed(2)),
          'reviews_count': snap.docs.length,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Equipment rating refresh warning: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> reviewsForEquipment(String equipmentId) {
    return FirebaseFirestore.instance
        .collection(collection)
        .where('equipment_id', isEqualTo: equipmentId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList())
        .handleError((e) {
      debugPrint('Review stream error: $e');
      return <Map<String, dynamic>>[];
    });
  }
}
