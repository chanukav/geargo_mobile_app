import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rental_request.dart';

/// Service managing all Rental Request CRUD operations (CRUD 01).
/// Supports Cloud Firestore synchronization with automatic local cache resilience.
class RentalRequestService {
  static final RentalRequestService _instance = RentalRequestService._internal();
  factory RentalRequestService() => _instance;
  RentalRequestService._internal() {
    _loadPersistedDeletedIds();
  }

  static const String collectionName = 'rental_requests';

  FirebaseFirestore? _customFirestore;
  FirebaseAuth? _customAuth;
  String? _explicitUserId;

  @visibleForTesting
  void setCustomFirestore(FirebaseFirestore? fs) {
    _customFirestore = fs;
  }

  @visibleForTesting
  void setCustomAuth(FirebaseAuth? auth, {String? userId}) {
    _customAuth = auth;
    _explicitUserId = userId;
  }

  String? get _currentUserId {
    if (_explicitUserId != null) return _explicitUserId;
    try {
      return (_customAuth ?? FirebaseAuth.instance).currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  // In-memory fallback cache for instant UI responsiveness and offline resilience.
  final Map<String, RentalRequest> _localCache = {};
  final Set<String> _deletedIds = {};
  final StreamController<List<RentalRequest>> _cacheStreamController =
      StreamController<List<RentalRequest>>.broadcast();

  FirebaseFirestore? get _safeFirestore {
    if (_customFirestore != null) return _customFirestore;
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

    _deletedIds.remove(newRequest.id);
    _unpersistDeletedId(newRequest.id);
    _localCache[newRequest.id] = newRequest;
    _notifyCacheListeners(newRequest.renterId);

    if (col != null) {
      try {
        await col.doc(docId).set(newRequest.toMap()).timeout(
          const Duration(seconds: 10),
        );
      } catch (e) {
        debugPrint('Firestore write notice (saved to local cache): $e');
      }
    }

    return newRequest;
  }

  /// READ: Real-time stream of rental requests submitted by a specific renter.
  Stream<List<RentalRequest>> getRenterRequestsStream(String renterId) {
    final col = _requestsCollection;
    if (col == null) {
      return _localCacheStream(renterId);
    }

    try {
      return col
          .where('renter_id', isEqualTo: renterId)
          .snapshots()
          .map((snapshot) {
        final firestoreIds = <String>{};
        final items = <RentalRequest>[];

        for (final doc in snapshot.docs) {
          if (_deletedIds.contains(doc.id)) {
            continue;
          }
          final item = RentalRequest.fromMap(doc.data(), doc.id);
          _localCache[item.id] = item;
          firestoreIds.add(item.id);
          items.add(item);
        }

        // Include any newly created or updated items in local cache not yet in Firestore,
        // excluding any deleted items
        for (final cached in _localCache.values) {
          if (cached.renterId == renterId &&
              !firestoreIds.contains(cached.id) &&
              !_deletedIds.contains(cached.id)) {
            items.add(cached);
          }
        }

        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return items;
      }).handleError((error) {
        debugPrint('Firestore request stream error (using cache): $error');
        final cached = _localCache.values
            .where((r) => r.renterId == renterId && !_deletedIds.contains(r.id))
            .toList();
        cached.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return cached;
      });
    } catch (e) {
      debugPrint('Error creating request stream: $e');
      return _localCacheStream(renterId);
    }
  }

  Stream<List<RentalRequest>> _localCacheStream(String renterId) async* {
    List<RentalRequest> current() {
      final list = _localCache.values
          .where((r) => r.renterId == renterId && !_deletedIds.contains(r.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }

    yield current();
    yield* _cacheStreamController.stream.map((_) => current());
  }

  /// READ: Get single rental request by ID.
  Future<RentalRequest?> getRequestById(String id) async {
    if (_deletedIds.contains(id)) {
      return null;
    }

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
        await col.doc(updated.id).set(updated.toMap(), SetOptions(merge: true)).timeout(
          const Duration(seconds: 10),
        );
      } catch (e) {
        debugPrint('Firestore update notice (updated locally): $e');
      }
    }

    // Mirror status update to rental_transactions if applicable
    try {
      await _safeFirestore?.collection('rental_transactions').doc(updated.id).update({
        'status': updated.status.name,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      }).timeout(const Duration(seconds: 5));
    } catch (_) {}

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

  static const String _deletedIdsPrefsKey = 'deleted_booking_request_ids';

  void _loadPersistedDeletedIds() {
    try {
      SharedPreferences.getInstance().then((prefs) {
        final list = prefs.getStringList(_deletedIdsPrefsKey) ?? [];
        if (list.isNotEmpty) {
          _deletedIds.addAll(list);
          for (final id in list) {
            _localCache.remove(id);
          }
          if (_explicitUserId != null) {
            _notifyCacheListeners(_explicitUserId!);
          }
        }
      }).catchError((_) {});
    } catch (_) {}
  }

  void _persistDeletedId(String id) {
    try {
      SharedPreferences.getInstance().then((prefs) {
        final list = prefs.getStringList(_deletedIdsPrefsKey) ?? [];
        if (!list.contains(id)) {
          list.add(id);
          prefs.setStringList(_deletedIdsPrefsKey, list);
        }
      }).catchError((_) {});
    } catch (_) {}
  }

  void _unpersistDeletedId(String id) {
    try {
      SharedPreferences.getInstance().then((prefs) {
        final list = prefs.getStringList(_deletedIdsPrefsKey) ?? [];
        if (list.remove(id)) {
          prefs.setStringList(_deletedIdsPrefsKey, list);
        }
      }).catchError((_) {});
    } catch (_) {}
  }

  /// DELETE: Permanently deletes a booking record.
  /// Validation: Only cancelled bookings can be deleted. If a booking is Pending, Approved, or Active,
  /// only Cancel is allowed, and this delete method rejects it.
  Future<void> deleteBooking(String id) async {
    final existing = await getRequestById(id);
    if (existing == null) {
      throw Exception('Booking record not found.');
    }

    // Validation 1: Only cancelled requests may be permanently deleted.
    if (existing.status != RentalStatus.cancelled) {
      throw Exception('Only cancelled bookings can be deleted.');
    }

    // Validation 2: Ensure user can only delete their own booking records.
    final currentUserId = _currentUserId;
    if (currentUserId != null &&
        existing.renterId != currentUserId &&
        existing.renterId != 'guest_renter') {
      throw Exception('You can only delete your own booking records.');
    }

    _deletedIds.add(id);
    _persistDeletedId(id);

    final col = _requestsCollection;
    if (col != null) {
      try {
        await col.doc(id).delete().timeout(const Duration(seconds: 10));
      } on TimeoutException {
        _deletedIds.remove(id);
        _unpersistDeletedId(id);
        throw Exception('Delete operation timed out. Please check your internet connection.');
      } catch (e) {
        _deletedIds.remove(id);
        _unpersistDeletedId(id);
        debugPrint('Firestore delete error: $e');
        rethrow;
      }
    }

    // Mirror cleanup on rental_transactions collection if this was a mirrored booking
    try {
      await _safeFirestore?.collection('rental_transactions').doc(id).delete().timeout(const Duration(seconds: 5));
    } catch (_) {}

    _localCache.remove(id);
    _notifyCacheListeners(existing.renterId);
  }

  /// Alias for backward compatibility with existing calls.
  Future<void> deleteRequestPermanently(String id) => deleteBooking(id);

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
    final list = _localCache.values
        .where((r) => r.renterId == renterId && !_deletedIds.contains(r.id))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!_cacheStreamController.isClosed) {
      _cacheStreamController.add(list);
    }
  }

  @visibleForTesting
  void resetForTesting() {
    _localCache.clear();
    _deletedIds.clear();
    _customFirestore = null;
    _customAuth = null;
    _explicitUserId = null;
  }
}
