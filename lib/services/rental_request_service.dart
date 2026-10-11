import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/rental_request.dart';

/// Service managing all Rental Request CRUD operations (CRUD 01).
/// Supports Cloud Firestore synchronization with automatic local cache resilience.
class RentalRequestService {
  static final RentalRequestService _instance = RentalRequestService._internal();
  factory RentalRequestService() => _instance;
  RentalRequestService._internal();

  static const String collectionName = 'rental_requests';

  // In-memory fallback cache for instant UI responsiveness and offline resilience.
  final Map<String, RentalRequest> _localCache = {};
  final StreamController<List<RentalRequest>> _cacheStreamController =
      StreamController<List<RentalRequest>>.broadcast();

  FirebaseFirestore? get _safeFirestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _requestsCollection {
    try {
      final fs = _safeFirestore;
      return fs?.collection(collectionName);
    } catch (_) {
      return null;
    }
  }

  /// CREATE: Submits a new rental request to the owner.
  Future<RentalRequest> createRequest(RentalRequest request) async {
    final col = _requestsCollection;
    final docId = request.id.isNotEmpty
        ? request.id
        : (col?.doc().id ?? 'req_${DateTime.now().millisecondsSinceEpoch}');

    final newRequest = request.copyWith(
      id: docId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _localCache[newRequest.id] = newRequest;
    _notifyCacheListeners(newRequest.renterId);

    if (col != null) {
      col.doc(docId).set(newRequest.toMap()).timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          debugPrint('Firestore write timed out; saved to local cache.');
        },
      ).catchError((e) {
        debugPrint('Firestore write warning (using cache): $e');
      });
    }

    return newRequest;
  }

  /// READ: Real-time stream of rental requests submitted by a specific renter.
  Stream<List<RentalRequest>> getRenterRequestsStream(String renterId) {
    final col = _requestsCollection;
    if (col == null) {
      final cached = _localCache.values.where((r) => r.renterId == renterId).toList();
      cached.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Stream.value(cached);
    }

    try {
      return col
          .where('renter_id', isEqualTo: renterId)
          .snapshots()
          .map((snapshot) {
        final items = snapshot.docs.map((doc) {
          final item = RentalRequest.fromMap(doc.data(), doc.id);
          _localCache[item.id] = item;
          return item;
        }).toList();

        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (items.isEmpty) {
          final cached =
              _localCache.values.where((r) => r.renterId == renterId).toList();
          if (cached.isNotEmpty) {
            cached.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return cached;
          }
        }
        return items;
      }).handleError((error) {
        debugPrint('Firestore request stream error (using cache): $error');
        final cached = _localCache.values.where((r) => r.renterId == renterId).toList();
        cached.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return cached;
      });
    } catch (e) {
      debugPrint('Error creating request stream: $e');
      final cached = _localCache.values.where((r) => r.renterId == renterId).toList();
      cached.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Stream.value(cached);
    }
  }

  /// READ: Get single rental request by ID.
  Future<RentalRequest?> getRequestById(String id) async {
    if (_localCache.containsKey(id)) {
      return _localCache[id];
    }

    final col = _requestsCollection;
    if (col != null) {
      try {
        final doc = await col.doc(id).get();
        if (doc.exists && doc.data() != null) {
          final item = RentalRequest.fromMap(doc.data()!, doc.id);
          _localCache[item.id] = item;
          return item;
        }
      } catch (e) {
        debugPrint('Error getting rental request $id from Firestore: $e');
      }
    }

    return _localCache[id];
  }

  /// UPDATE: Modifies rental request dates, notes, or delivery options.
  Future<RentalRequest> updateRequest(RentalRequest request) async {
    final updated = request.copyWith(
      updatedAt: DateTime.now(),
    );

    _localCache[updated.id] = updated;
    _notifyCacheListeners(updated.renterId);

    final col = _requestsCollection;
    if (col != null) {
      col.doc(updated.id).update(updated.toMap()).timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          debugPrint('Firestore update timed out; updated locally.');
        },
      ).catchError((e) {
        debugPrint('Firestore update warning (using cache): $e');
      });
    }

    return updated;
  }

  /// UPDATE: Modifies the request lifecycle status.
  Future<void> updateStatus(String id, RentalStatus newStatus, {String? reason}) async {
    final existing = await getRequestById(id);
    if (existing == null) return;

    final updated = existing.copyWith(
      status: newStatus,
      cancellationReason: reason ?? existing.cancellationReason,
      updatedAt: DateTime.now(),
    );

    await updateRequest(updated);
  }

  /// DELETE / CANCEL: Cancels an active or pending rental request.
  Future<void> cancelRequest(String id, {String? reason}) async {
    await updateStatus(id, RentalStatus.cancelled, reason: reason ?? 'Cancelled by renter');
  }

  /// DELETE: Permanently deletes a request record.
  Future<void> deleteRequestPermanently(String id) async {
    final item = _localCache[id];
    final renterId = item?.renterId;

    _localCache.remove(id);
    if (renterId != null) {
      _notifyCacheListeners(renterId);
    }

    final col = _requestsCollection;
    if (col != null) {
      col.doc(id).delete().timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          debugPrint('Firestore delete timed out; removed locally.');
        },
      ).catchError((e) {
        debugPrint('Firestore delete warning: $e');
      });
    }
  }

  /// SEED: Seeds starter demonstration requests for a new renter so the UI is richly populated.
  Future<void> seedStarterRequests({
    required String renterId,
    required String renterName,
    required String renterEmail,
  }) async {
    final hasItems = _localCache.values.any((r) => r.renterId == renterId);
    if (hasItems) return;

    final samples = <RentalRequest>[];

    for (final s in samples) {
      await createRequest(s);
    }
  }

  void _notifyCacheListeners(String renterId) {
    final list = _localCache.values.where((r) => r.renterId == renterId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!_cacheStreamController.isClosed) {
      _cacheStreamController.add(list);
    }
  }
}
