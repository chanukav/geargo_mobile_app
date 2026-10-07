import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/saved_equipment.dart';

/// Service managing Saved / Favourite Equipment CRUD operations (CRUD 02).
/// Supports Cloud Firestore synchronization with automatic local cache resilience.
class SavedEquipmentService {
  static final SavedEquipmentService _instance =
      SavedEquipmentService._internal();
  factory SavedEquipmentService() => _instance;
  SavedEquipmentService._internal();

  static const String collectionName = 'saved_equipment';

  // In-memory fallback cache for instant UI responsiveness and offline resilience.
  final Map<String, SavedEquipment> _localCache = {};
  final StreamController<List<SavedEquipment>> _cacheStreamController =
      StreamController<List<SavedEquipment>>.broadcast();

  FirebaseFirestore? get _safeFirestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _savedCollection {
    try {
      final fs = _safeFirestore;
      return fs?.collection(collectionName);
    } catch (_) {
      return null;
    }
  }

  /// TOGGLE: Toggles bookmark on/off for a given equipment item.
  /// Returns `true` if item is now saved, `false` if removed.
  Future<bool> toggleSaved({
    required String renterId,
    required String equipmentId,
    required String equipmentName,
    required String equipmentCategory,
    required String equipmentImage,
    required double dailyPrice,
    double rating = 4.9,
    int reviewsCount = 12,
    bool available = true,
    String collectionName = 'Favorites',
    String renterNote = '',
  }) async {
    final existing = _findSaved(renterId, equipmentId);
    if (existing != null) {
      await removeSavedItemById(existing.id);
      return false;
    } else {
      final item = SavedEquipment(
        id: 'saved_${DateTime.now().millisecondsSinceEpoch}_$equipmentId',
        renterId: renterId,
        equipmentId: equipmentId,
        equipmentName: equipmentName,
        equipmentCategory: equipmentCategory,
        equipmentImage: equipmentImage,
        dailyPrice: dailyPrice,
        rating: rating,
        reviewsCount: reviewsCount,
        available: available,
        collectionName: collectionName,
        renterNote: renterNote,
        savedAt: DateTime.now(),
      );
      await addSavedItem(item);
      return true;
    }
  }

  SavedEquipment? _findSaved(String renterId, String equipmentId) {
    for (final item in _localCache.values) {
      if (item.renterId == renterId && item.equipmentId == equipmentId) {
        return item;
      }
    }
    return null;
  }

  /// CREATE: Adds a saved equipment entry.
  Future<SavedEquipment> addSavedItem(SavedEquipment item) async {
    final col = _savedCollection;
    final docId = item.id.isNotEmpty
        ? item.id
        : (col?.doc().id ?? 'saved_${DateTime.now().millisecondsSinceEpoch}');

    final finalItem = item.copyWith(id: docId, savedAt: DateTime.now());
    _localCache[finalItem.id] = finalItem;
    _notifyCacheListeners(finalItem.renterId);

    if (col != null) {
      col.doc(docId).set(finalItem.toMap()).timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          debugPrint('Firestore save item timed out; stored locally.');
        },
      ).catchError((e) {
        debugPrint('Firestore save item warning: $e');
      });
    }

    return finalItem;
  }

  /// READ: Real-time stream of all saved equipment for a specific renter.
  Stream<List<SavedEquipment>> getSavedStream(String renterId) {
    final col = _savedCollection;
    if (col == null) {
      final cached =
          _localCache.values.where((s) => s.renterId == renterId).toList();
      cached.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return Stream.value(cached);
    }

    try {
      return col
          .where('renter_id', isEqualTo: renterId)
          .snapshots()
          .map((snapshot) {
        final items = snapshot.docs.map((doc) {
          final item = SavedEquipment.fromMap(doc.data(), doc.id);
          _localCache[item.id] = item;
          return item;
        }).toList();

        items.sort((a, b) => b.savedAt.compareTo(a.savedAt));

        if (items.isEmpty) {
          final cached =
              _localCache.values.where((s) => s.renterId == renterId).toList();
          if (cached.isNotEmpty) {
            cached.sort((a, b) => b.savedAt.compareTo(a.savedAt));
            return cached;
          }
        }
        return items;
      }).handleError((error) {
        debugPrint('Firestore saved stream error (using cache): $error');
        final cached =
            _localCache.values.where((s) => s.renterId == renterId).toList();
        cached.sort((a, b) => b.savedAt.compareTo(a.savedAt));
        return cached;
      });
    } catch (e) {
      debugPrint('Error creating saved stream: $e');
      final cached =
          _localCache.values.where((s) => s.renterId == renterId).toList();
      cached.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return Stream.value(cached);
    }
  }

  /// CHECK: Check whether a specific equipment item is saved by this renter.
  bool isSaved(String renterId, String equipmentId) {
    return _findSaved(renterId, equipmentId) != null;
  }

  /// UPDATE: Update collection name or personal notes for a saved item.
  Future<void> updateSavedDetails(
    String id, {
    String? collectionName,
    String? renterNote,
  }) async {
    final current = _localCache[id];
    if (current == null) return;

    final updated = current.copyWith(
      collectionName: collectionName ?? current.collectionName,
      renterNote: renterNote ?? current.renterNote,
    );

    _localCache[id] = updated;
    _notifyCacheListeners(updated.renterId);

    final col = _savedCollection;
    if (col != null) {
      col.doc(id).update(updated.toMap()).timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          debugPrint('Firestore update timed out; updated locally.');
        },
      ).catchError((e) {
        debugPrint('Firestore update saved warning: $e');
      });
    }
  }

  /// DELETE: Remove saved item by document ID.
  Future<void> removeSavedItemById(String id) async {
    final item = _localCache[id];
    final renterId = item?.renterId;

    _localCache.remove(id);
    if (renterId != null) {
      _notifyCacheListeners(renterId);
    }

    final col = _savedCollection;
    if (col != null) {
      col.doc(id).delete().timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          debugPrint('Firestore delete timed out; removed locally.');
        },
      ).catchError((e) {
        debugPrint('Firestore delete saved warning: $e');
      });
    }
  }

  /// DELETE: Remove saved item by equipment ID.
  Future<void> removeByEquipmentId(String renterId, String equipmentId) async {
    final existing = _findSaved(renterId, equipmentId);
    if (existing != null) {
      await removeSavedItemById(existing.id);
    }
  }

  /// DELETE: Clear all saved favorites for renter.
  Future<void> clearAll(String renterId) async {
    final toRemove = _localCache.values
        .where((s) => s.renterId == renterId)
        .map((s) => s.id)
        .toList();

    for (final id in toRemove) {
      await removeSavedItemById(id);
    }
  }

  /// SEED: Populate starter saved items for a great first-time impression.
  Future<void> seedStarterSaved(String renterId) async {
    final hasItems = _localCache.values.any((s) => s.renterId == renterId);
    if (hasItems) return;

    final now = DateTime.now();
    final samples = [
      SavedEquipment(
        id: 'saved_seed_01',
        renterId: renterId,
        equipmentId: 'sample_bike_01',
        equipmentName: 'Specialized Stumpjumper EVO',
        equipmentCategory: 'Cycling',
        equipmentImage: 'assets/images/gear_bike_red.jpg',
        dailyPrice: 45.0,
        rating: 4.9,
        reviewsCount: 38,
        available: true,
        collectionName: 'Weekend Trips',
        renterNote: 'Compare with Trek bike before renting for Knuckles trip.',
        savedAt: now.subtract(const Duration(hours: 14)),
      ),
      SavedEquipment(
        id: 'saved_seed_02',
        renterId: renterId,
        equipmentId: 'sample_skis_04',
        equipmentName: 'Black Crows Camox All-Terrain Skis',
        equipmentCategory: 'Skiing',
        equipmentImage: 'assets/images/gear_skis.jpg',
        dailyPrice: 50.0,
        rating: 4.9,
        reviewsCount: 17,
        available: true,
        collectionName: 'Winter Wishlist',
        renterNote: 'Awesome twin-tip design. Check binding size.',
        savedAt: now.subtract(const Duration(days: 2)),
      ),
      SavedEquipment(
        id: 'saved_seed_03',
        renterId: renterId,
        equipmentId: 'sample_pack_03',
        equipmentName: 'Osprey Atmos 65 AG Backpack',
        equipmentCategory: 'Hiking',
        equipmentImage: 'assets/images/gear_backpack.jpg',
        dailyPrice: 15.0,
        rating: 4.7,
        reviewsCount: 22,
        available: false,
        collectionName: 'Favorites',
        renterNote: 'Currently rented out. Rent as soon as back in stock.',
        savedAt: now.subtract(const Duration(days: 4)),
      ),
    ];

    for (final s in samples) {
      await addSavedItem(s);
    }
  }

  void _notifyCacheListeners(String renterId) {
    final list =
        _localCache.values.where((s) => s.renterId == renterId).toList();
    list.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    if (!_cacheStreamController.isClosed) {
      _cacheStreamController.add(list);
    }
  }
}
