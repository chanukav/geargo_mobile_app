import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// FR-03/FR-04: sandbox deposit pre-authorization (SetupIntent-style hold record).
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  static const String holdsCollection = 'payment_holds';

  /// Creates a sandbox hold document and returns a client reference id.
  Future<String> authorizeDepositHold({
    required double depositAmount,
    required String rentalRequestId,
    String currency = 'USD',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in to authorize the security deposit hold.');
    }

    final holdId =
        'hold_${rentalRequestId}_${DateTime.now().millisecondsSinceEpoch}';
    final payload = {
      'hold_id': holdId,
      'uid': user.uid,
      'rental_request_id': rentalRequestId,
      'amount': depositAmount,
      'currency': currency,
      'provider': 'stripe_sandbox',
      'intent_type': 'setup_intent',
      'status': 'requires_capture',
      'created_at': FieldValue.serverTimestamp(),
      'release_by': DateTime.now()
          .add(const Duration(hours: 48))
          .toIso8601String(),
    };

    try {
      await FirebaseFirestore.instance
          .collection(holdsCollection)
          .doc(holdId)
          .set(payload);
    } catch (e) {
      debugPrint('Payment hold write warning: $e');
    }

    return holdId;
  }
}
