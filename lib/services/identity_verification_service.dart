import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// FR-02 / NFR-02: government or student ID upload with private storage paths.
class IdentityVerificationService {
  static final IdentityVerificationService _instance =
      IdentityVerificationService._internal();
  factory IdentityVerificationService() => _instance;
  IdentityVerificationService._internal();

  final ImagePicker _picker = ImagePicker();
  final Map<String, VerificationStatus> _statusCache = {};

  Future<VerificationStatus> getStatus(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final map = doc.data();
      if (map == null) return VerificationStatus.none;
      final status =
          VerificationStatus.fromString(map['verification_status'] as String?);
      _statusCache[uid] = status;
      return status;
    } catch (e) {
      debugPrint('Verification status read failed: $e');
      return VerificationStatus.none;
    }
  }

  Future<bool> isUserVerified(String uid) async {
    if (_statusCache.containsKey(uid)) {
      return _statusCache[uid] == VerificationStatus.approved;
    }
    try {
      final ownerDoc =
          await FirebaseFirestore.instance.collection('owner_profile').doc(uid).get();
      if (ownerDoc.exists && ownerDoc.data()?['is_verified'] == true) {
        _statusCache[uid] = VerificationStatus.approved;
        return true;
      }
    } catch (e) {
      debugPrint('Owner profile verify read failed: $e');
    }
    final uidMatch = FirebaseAuth.instance.currentUser?.uid;
    if (uidMatch == uid) {
      return (await getStatus(uid)) == VerificationStatus.approved;
    }
    return false;
  }

  void invalidateCache([String? uid]) {
    if (uid == null) {
      _statusCache.clear();
    } else {
      _statusCache.remove(uid);
    }
  }

  Future<XFile?> pickIdDocument() => _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2000,
      );

  Future<void> submitVerification({
    required String documentType,
    required XFile idImage,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in to submit identity verification.');
    }

    final bytes = await idImage.readAsBytes();
    if (bytes.isEmpty || bytes.length > 4 * 1024 * 1024) {
      throw StateError('Choose an ID image under 4 MB.');
    }

    final storagePath = 'identity_docs/${user.uid}/id_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await FirebaseStorage.instance.ref(storagePath).putData(
          Uint8List.fromList(bytes),
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uid': user.uid,
              'document_type': documentType,
            },
          ),
        );

    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    batch.set(
      userRef,
      {
        'verification_status': 'pending',
        'verification_document_type': documentType,
        'verification_storage_path': storagePath,
        'verification_submitted_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    final reviewRef =
        FirebaseFirestore.instance.collection('verifications').doc(user.uid);
    batch.set(reviewRef, {
      'userId': user.uid,
      'summary': '$documentType submission for ${user.email ?? user.uid}',
      'status': 'pending',
      'storagePath': storagePath,
      'notes': [],
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
    await batch.commit();
  }
}

enum VerificationStatus {
  none,
  pending,
  approved,
  rejected;

  static VerificationStatus fromString(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'pending':
        return VerificationStatus.pending;
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.none;
    }
  }

  String get label => switch (this) {
        VerificationStatus.none => 'Not submitted',
        VerificationStatus.pending => 'Under review',
        VerificationStatus.approved => 'Verified',
        VerificationStatus.rejected => 'Rejected',
      };
}
