import 'package:flutter/foundation.dart';

import '../models/equipment.dart';
import '../models/gear_item.dart';
import 'equipment_service.dart';
import 'identity_verification_service.dart';
import 'owner_profile_service.dart';

/// Merges demo catalog items with live Firestore listings for discovery (NFR-01).
class GearCatalogService {
  static final GearCatalogService _instance = GearCatalogService._internal();
  factory GearCatalogService() => _instance;
  GearCatalogService._internal();

  final _equipment = EquipmentService();
  final _identity = IdentityVerificationService();

  Stream<List<GearItem>> discoveryStream() {
    return _equipment.getAvailableEquipmentStream().asyncMap(_mergeCatalog);
  }

  Future<List<GearItem>> loadCatalog() async {
    final live = await _equipment.getAvailableEquipment();
    return _mergeCatalog(live);
  }

  Future<List<GearItem>> _mergeCatalog(List<Equipment> live) async {
    final liveItems = <GearItem>[];
    for (final e in live) {
      try {
        final verified = await _identity.isUserVerified(e.ownerId);
        final profile = await OwnerProfileService().getProfile(e.ownerId);
        liveItems.add(
          e.toGearItem(
            ownerDisplay: profile?.name ?? 'GearGo Host',
            ownerVerified: verified,
          ),
        );
      } catch (err) {
        debugPrint('Catalog verify skip ${e.id}: $err');
        liveItems.add(e.toGearItem());
      }
    }

    final liveNames = liveItems.map((g) => g.name.toLowerCase()).toSet();
    final samples = sampleGear
        .where((s) => !liveNames.contains(s.name.toLowerCase()))
        .toList();

    return [...liveItems, ...samples];
  }
}
