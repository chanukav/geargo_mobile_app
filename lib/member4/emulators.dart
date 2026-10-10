import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Opt in explicitly. Android Emulator reaches the host through 10.0.2.2.
Future<void> configureMember4Emulators() async {
  const host = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
  if (host.isEmpty) return;
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8085);
  FirebaseFunctions.instanceFor(region: 'us-central1')
      .useFunctionsEmulator(host, 5001);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
}
