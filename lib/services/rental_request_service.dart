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
      try {
        await col.doc(docId).set(newRequest.toMap());
        debugPrint('Rental request created in Firestore: $docId');
      } catch (e) {
        debugPrint('Firestore write warning (using cache): $e');
      }
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
      try {
        await col.doc(updated.id).update(updated.toMap());
        debugPrint('Rental request updated in Firestore: ${updated.id}');
      } catch (e) {
        debugPrint('Firestore update warning (using cache): $e');
      }
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
      try {
        await col.doc(id).delete();
        debugPrint('Rental request deleted from Firestore: $id');
      } catch (e) {
        debugPrint('Firestore delete warning: $e');
      }
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

    final now = DateTime.now();
    final samples = [
      RentalRequest(
        id: 'req_demo_01',
        renterId: renterId,
        renterName: renterName,
        renterEmail: renterEmail,
        renterPhone: '+94 77 123 4567',
        equipmentId: 'sample_bike_01',
        equipmentName: 'Specialized Stumpjumper EVO',
        equipmentCategory: 'Cycling',
        equipmentImage: 'assets/images/gear_bike_red.jpg',
        dailyPrice: 45.0,
        ownerId: 'owner_marcus',
        ownerName: 'Marcus Vance',
        startDate: now.add(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 5)),
        totalDays: 3,
        serviceFee: 6.75,
        depositAmount: 50.0,
        totalPrice: 191.75,
        deliveryMethod: 'pickup',
        deliveryAddress: 'Self-pickup at Marcus Garage, Colombo 03',
        renterNotes: 'Planning a trail trip to Knuckles. Will bring my own helmet.',
        status: RentalStatus.pending,
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      RentalRequest(
        id: 'req_demo_02',
        renterId: renterId,
        renterName: renterName,
        renterEmail: renterEmail,
        renterPhone: '+94 77 123 4567',
        equipmentId: 'sample_sup_02',
        equipmentName: 'Solitude Touring Paddleboard 11ft',
        equipmentCategory: 'Surfing',
        equipmentImage: 'assets/images/gear_sup.jpg',
        dailyPrice: 28.0,
        ownerId: 'owner_elena',
        ownerName: 'Elena Rostova',
        startDate: now.add(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 9)),
        totalDays: 2,
        serviceFee: 4.20,
        depositAmount: 30.0,
        totalPrice: 90.20,
        deliveryMethod: 'delivery',
        deliveryAddress: 'Bentota Beach Villa, Southern Highway',
        renterNotes: 'Please include the electric pump and ankle leash.',
        status: RentalStatus.approved,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 8)),
      ),
      RentalRequest(
        id: 'req_demo_03',
        renterId: renterId,
        renterName: renterName,
        renterEmail: renterEmail,
        renterPhone: '+94 77 123 4567',
        equipmentId: 'sample_pack_03',
        equipmentName: 'Osprey Atmos AG 65L Trekking Pack',
        equipmentCategory: 'Hiking',
        equipmentImage: 'assets/images/gear_backpack.jpg',
        dailyPrice: 15.0,
        ownerId: 'owner_dave',
        ownerName: 'Dave K.',
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.subtract(const Duration(days: 6)),
        totalDays: 4,
        serviceFee: 4.50,
        depositAmount: 25.0,
        totalPrice: 89.50,
        deliveryMethod: 'pickup',
        deliveryAddress: 'Pick up at Dave Outfitter Store',
        renterNotes: 'Used for Ella rock trek. Gear returned in immaculate condition.',
        status: RentalStatus.completed,
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 6)),
      ),
    ];

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
