import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/image_helper.dart';
import '../models/equipment.dart';

/// Service managing all Equipment Listing CRUD operations.
/// Interacts with Cloud Firestore with automatic local cache resilience.
class EquipmentService {
  static final EquipmentService _instance = EquipmentService._internal();
  factory EquipmentService() => _instance;
  EquipmentService._internal();

  static const String collectionName = 'equipment';

  // In-memory fallback cache to ensure smooth UX even if offline or Firebase rules are restricted.
  final Map<String, Equipment> _localCache = {};
  final StreamController<List<Equipment>> _cacheStreamController =
      StreamController<List<Equipment>>.broadcast();

  FirebaseFirestore? get _safeFirestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _equipmentCollection {
    try {
      final fs = _safeFirestore;
      return fs?.collection(collectionName);
    } catch (_) {
      return null;
    }
  }

  /// CREATE: Adds a new equipment item to the database.
  Future<Equipment> createEquipment(Equipment equipment) async {
    final col = _equipmentCollection;
    final docId = equipment.id.isNotEmpty
        ? equipment.id
        : (col?.doc().id ?? 'eq_${DateTime.now().millisecondsSinceEpoch}');

    var finalEquipment = equipment.copyWith(
      id: docId,
      createdAt: equipment.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      final resolvedImage = await ImageHelper.resolveEquipmentImageUrl(
        docId,
        finalEquipment.image,
      );
      finalEquipment = finalEquipment.copyWith(image: resolvedImage);
    } catch (e) {
      debugPrint('Equipment image upload warning: $e');
    }

    // Save to local cache first
    _localCache[finalEquipment.id] = finalEquipment;
    _notifyCacheListeners(finalEquipment.ownerId);

    if (col != null) {
      try {
        await col.doc(docId).set(finalEquipment.toMap());
        debugPrint('Equipment created in Firestore: $docId');
      } catch (e) {
        debugPrint('Firestore write warning (using cached data): $e');
      }
    }

    return finalEquipment;
  }

  /// READ: Real-time stream of equipment belonging to a specific owner.
  Stream<List<Equipment>> getOwnerEquipmentStream(String ownerId) {
    final col = _equipmentCollection;
    if (col == null) {
      final cached =
          _localCache.values.where((e) => e.ownerId == ownerId).toList();
      cached.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Stream.value(cached);
    }

    try {
      return col
          .where('owner_id', isEqualTo: ownerId)
          .snapshots()
          .map((snapshot) {
        final items = snapshot.docs.map((doc) {
          final item = Equipment.fromMap(doc.data(), doc.id);
          _localCache[item.id] = item;
          return item;
        }).toList();

        // Sort by updatedAt descending
        items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        // If firestore returned 0 items but local cache has items for owner, merge them
        if (items.isEmpty) {
          final cached = _localCache.values
              .where((e) => e.ownerId == ownerId)
              .toList();
          if (cached.isNotEmpty) {
            cached.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            return cached;
          }
        }
        return items;
      }).handleError((error) {
        debugPrint('Firestore stream error (falling back to cache): $error');
        final cached =
            _localCache.values.where((e) => e.ownerId == ownerId).toList();
        cached.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return cached;
      });
    } catch (e) {
      debugPrint('Error creating Firestore stream: $e');
      final cached =
          _localCache.values.where((e) => e.ownerId == ownerId).toList();
      cached.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Stream.value(cached);
    }
  }

  /// READ: All available listings for renter discovery.
  Stream<List<Equipment>> getAvailableEquipmentStream() {
    final col = _equipmentCollection;
    if (col == null) {
      final cached =
          _localCache.values.where((e) => e.availability).toList();
      cached.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Stream.value(cached);
    }

    try {
      return col
          .where('availability', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        final items = snapshot.docs.map((doc) {
          final item = Equipment.fromMap(doc.data(), doc.id);
          _localCache[item.id] = item;
          return item;
        }).toList();
        items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return items;
      }).handleError((error) {
        debugPrint('Available equipment stream error: $error');
        return _localCache.values.where((e) => e.availability).toList();
      });
    } catch (e) {
      debugPrint('Error creating available equipment stream: $e');
      final cached =
          _localCache.values.where((e) => e.availability).toList();
      return Stream.value(cached);
    }
  }

  Future<List<Equipment>> getAvailableEquipment() async {
    final col = _equipmentCollection;
    if (col == null) {
      return _localCache.values.where((e) => e.availability).toList();
    }
    try {
      final snap = await col.where('availability', isEqualTo: true).get();
      return snap.docs.map((doc) {
        final item = Equipment.fromMap(doc.data(), doc.id);
        _localCache[item.id] = item;
        return item;
      }).toList();
    } catch (e) {
      debugPrint('Available equipment fetch error: $e');
      return _localCache.values.where((e) => e.availability).toList();
    }
  }

  /// READ: Get single equipment by ID.
  Future<Equipment?> getEquipmentById(String id) async {
    if (_localCache.containsKey(id)) {
      return _localCache[id];
    }

    final col = _equipmentCollection;
    if (col != null) {
      try {
        final doc = await col.doc(id).get();
        if (doc.exists && doc.data() != null) {
          final item = Equipment.fromMap(doc.data()!, doc.id);
          _localCache[item.id] = item;
          return item;
        }
      } catch (e) {
        debugPrint('Error getting equipment $id from Firestore: $e');
      }
    }

    return _localCache[id];
  }

  /// UPDATE: Modifies equipment details (price, description, availability, image, etc.)
  Future<Equipment> updateEquipment(Equipment equipment) async {
    var updatedItem = equipment.copyWith(
      updatedAt: DateTime.now(),
    );

    try {
      final resolvedImage = await ImageHelper.resolveEquipmentImageUrl(
        updatedItem.id,
        updatedItem.image,
      );
      updatedItem = updatedItem.copyWith(image: resolvedImage);
    } catch (e) {
      debugPrint('Equipment image upload warning: $e');
    }

    // Update local cache
    _localCache[updatedItem.id] = updatedItem;
    _notifyCacheListeners(updatedItem.ownerId);

    final col = _equipmentCollection;
    if (col != null) {
      try {
        await col
            .doc(updatedItem.id)
            .set(updatedItem.toMap(), SetOptions(merge: true));
        debugPrint('Equipment updated in Firestore: ${updatedItem.id}');
      } catch (e) {
        debugPrint('Firestore update warning (using cached data): $e');
      }
    }

    return updatedItem;
  }

  /// UPDATE: Quick toggle for availability state.
  Future<void> toggleAvailability(String id, bool isAvailable) async {
    final current = await getEquipmentById(id);
    if (current != null) {
      final updated = current.copyWith(
        availability: isAvailable,
        updatedAt: DateTime.now(),
      );
      await updateEquipment(updated);
    }
  }

  /// DELETE: Removes or unpublishes equipment permanently from the system.
  Future<void> deleteEquipment(String id) async {
    final item = _localCache[id];
    final ownerId = item?.ownerId;

    _localCache.remove(id);
    if (ownerId != null) {
      _notifyCacheListeners(ownerId);
    }

    final col = _equipmentCollection;
    if (col != null) {
      try {
        await col.doc(id).delete();
        debugPrint('Equipment deleted from Firestore: $id');
      } catch (e) {
        debugPrint('Firestore delete warning (removed from local cache): $e');
      }
    }
  }

  /// SEED: Creates starter demo equipment for an owner to test the CRUD instantly.
  Future<void> seedStarterEquipment(String ownerId) async {
    final samples = [
      Equipment(
        id: 'sample_bike_01',
        ownerId: ownerId,
        name: 'Trek Fuel EX 8 Gen 6',
        categoryId: 'mountain_bikes',
        description:
            'Extremely well-maintained. Light cosmetic scuffs on frame, mechanics are freshly tuned. Shocks serviced last month. Perfect for intermediate to advanced trail riding.',
        price: 45.0,
        availability: true,
        image:
            'https://images.unsplash.com/photo-1576435728678-68d0fbf94e91?auto=format&fit=crop&w=1200&q=80',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
        condition: 'Excellent',
        location: 'Denver, CO (Capitol Hill)',
        rating: 4.9,
        reviewsCount: 18,
      ),
      Equipment(
        id: 'sample_backpack_02',
        ownerId: ownerId,
        name: 'Osprey Aether Plus 70L Backpack',
        categoryId: 'camping',
        description:
            'Heavy-duty trekking pack with Custom Fit-on-the-Fly hipbelt, integrated raincover, and DayLid daypack. Great for multi-day expeditions in the backcountry.',
        price: 18.0,
        availability: true,
        image:
            'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=1200&q=80',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        condition: 'Like New',
        location: 'Boulder, CO',
        rating: 5.0,
        reviewsCount: 7,
      ),
      Equipment(
        id: 'sample_camera_03',
        ownerId: ownerId,
        name: 'Sony Alpha A7 IV + 24-70mm GM',
        categoryId: 'cameras',
        description:
            'Professional full-frame mirrorless camera paired with 24-70mm f/2.8 G Master lens. Includes 2 high-capacity batteries, 128GB V90 SD card, and Pelican hard case.',
        price: 85.0,
        availability: false,
        image:
            'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=1200&q=80',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        condition: 'Mint',
        location: 'Denver, CO (Downtown)',
        rating: 4.8,
        reviewsCount: 24,
      ),
    ];

    for (final sample in samples) {
      await createEquipment(sample);
    }
  }

  void _notifyCacheListeners(String ownerId) {
    final list = _localCache.values.where((e) => e.ownerId == ownerId).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (!_cacheStreamController.isClosed) {
      _cacheStreamController.add(list);
    }
  }
}
