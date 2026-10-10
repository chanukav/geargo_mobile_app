import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'models.dart';

abstract class Member4Repository {
  String get uid;
  Future<bool> isAdmin();
  Stream<List<RentalRecord>> rentals({bool all = false});
  Stream<RentalRecord?> rental(String id);
  Stream<List<Map<String, dynamic>>> messages(String id);
  Stream<List<Map<String, dynamic>>> reviews(String kind);
  String newMessageId();
  Future<void> action(
    String rentalId,
    String action,
    Map<String, dynamic> values,
  );
  Future<void> send(
    String rentalId,
    String messageId,
    String text, {
    bool location = false,
  });
  Future<void> upload(String rentalId, String phase, String angle, XFile file);
  Future<Uint8List?> photo(String path);
  Future<void> review(String kind, String id, String status, String note);
  Stream<List<Map<String, dynamic>>> flaggedUsers();
  Future<void> adminDepositAction(String rentalId, String status, String note);
}

class FirebaseMember4Repository implements Member4Repository {
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseStorage storage;
  final FirebaseFunctions functions;
  FirebaseMember4Repository({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
  }) : auth = auth ?? FirebaseAuth.instance,
       db = db ?? FirebaseFirestore.instance,
       storage = storage ?? FirebaseStorage.instance,
       functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');
  @override
  String get uid => auth.currentUser!.uid;
  @override
  Future<bool> isAdmin() async {
    final claims =
        (await auth.currentUser!.getIdTokenResult(true)).claims?['admin'];
    if (claims == true) return true;
    final userDoc = await db.collection('users').doc(uid).get();
    return userDoc.data()?['role'] == 'admin';
  }
  @override
  Stream<List<RentalRecord>> rentals({bool all = false}) {
    Query<Map<String, dynamic>> query = db.collection('rentals');
    if (!all) query = query.where('participantIds', arrayContains: uid);
    return query.snapshots().map(
      (s) => s.docs.map(RentalRecord.fromDoc).toList(),
    );
  }

  @override
  Stream<RentalRecord?> rental(String id) => db
      .collection('rentals')
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? RentalRecord.fromDoc(s) : null);
  @override
  Stream<List<Map<String, dynamic>>> messages(String id) => db
      .collection('rentals')
      .doc(id)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  @override
  Stream<List<Map<String, dynamic>>> reviews(String kind) => db
      .collection(kind == 'verification' ? 'verifications' : 'disputes')
      .snapshots()
      .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  @override
  String newMessageId() => db.collection('rentals').doc().id;
  Future<void> _call(String name, Map<String, dynamic> data) async {
    await functions
        .httpsCallable(
          name,
          options: HttpsCallableOptions(timeout: const Duration(seconds: 25)),
        )
        .call<void>(data);
  }

  @override
  Future<void> action(
    String rentalId,
    String action,
    Map<String, dynamic> values,
  ) => _call('member4Handover', {
    ...values,
    'rentalId': rentalId,
    'action': action,
  });
  @override
  Future<void> send(
    String rentalId,
    String messageId,
    String text, {
    bool location = false,
  }) => _call('member4Message', {
    'rentalId': rentalId,
    'messageId': messageId,
    'text': text,
    'kind': location ? 'location' : 'text',
  });
  @override
  Future<void> upload(
    String rentalId,
    String phase,
    String angle,
    XFile file,
  ) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length >= 8 * 1024 * 1024) {
      throw StateError('Choose an image smaller than 8 MB.');
    }
    // Detect the actual file signature; filenames from cameras are not reliable.
    String? type;
    if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      type = 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71) {
      type = 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      type = 'image/webp';
    }
    if (type == null) throw StateError('Choose a JPEG, PNG or WebP image.');
    final path = 'condition/$rentalId/$phase/$uid/${newMessageId()}';
    await storage.ref(path).putData(bytes, SettableMetadata(contentType: type));
    await action(rentalId, 'photo', {
      'phase': phase,
      'angle': angle,
      'path': path,
    });
  }

  @override
  Future<Uint8List?> photo(String path) =>
      storage.ref(path).getData(8 * 1024 * 1024);
  @override
  Future<void> review(String kind, String id, String status, String note) =>
      _call('member4Admin', {
        'kind': kind,
        'id': id,
        'status': status,
        'note': note,
      });

  @override
  Stream<List<Map<String, dynamic>>> flaggedUsers() => db
      .collection('users')
      .where('flagged', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());

  @override
  Future<void> adminDepositAction(
    String rentalId,
    String status,
    String note,
  ) =>
      _call('member4Admin', {
        'kind': 'deposit',
        'rentalId': rentalId,
        'status': status,
        'note': note,
      });
}

String member4Error(Object error) {
  if (error is FirebaseFunctionsException) {
    return error.message ??
        'Unable to save. Check your connection and try again.';
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'This account does not have access to this record.';
  }
  return 'Unable to complete this action. Check your connection, then try again. Your input is retained.';
}
