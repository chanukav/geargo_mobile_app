import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Result object returned by payment processing gateways.
class PaymentResult {
  const PaymentResult({
    required this.isSuccess,
    required this.transactionId,
    required this.message,
    required this.timestamp,
  });

  final bool isSuccess;
  final String transactionId;
  final String message;
  final DateTime timestamp;
}

/// FR-03/FR-04 and Shop Transactions: Handles security deposit holds & rental payments.
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

  /// Process standard transaction payment.
  Future<PaymentResult> processPayment({
    required double amount,
    required String paymentMethod,
    required String bookingRef,
  }) {
    return const MockPaymentService().processPayment(
      amount: amount,
      paymentMethod: paymentMethod,
      bookingRef: bookingRef,
    );
  }
}

/// Simulated in-app payment service.
/// Satisfies NFR-02: payment execution is simulated safely; raw card
/// numbers and sensitive CVV codes are never stored, logged, or transmitted.
class MockPaymentService implements PaymentService {
  const MockPaymentService();

  @override
  Future<PaymentResult> processPayment({
    required double amount,
    required String paymentMethod,
    required String bookingRef,
  }) async {
    // Simulate brief network / processing delay (400ms)
    await Future<void>.delayed(const Duration(milliseconds: 400));

    // Generate safe masked transaction ID without logging any card numbers
    final randomSuffix = math.Random().nextInt(9000) + 1000;
    final txnId = 'SIM-TXN-$bookingRef-$randomSuffix';

    return PaymentResult(
      isSuccess: true,
      transactionId: txnId,
      message: 'Simulated payment of amount approved successfully.',
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<String> authorizeDepositHold({
    required double depositAmount,
    required String rentalRequestId,
    String currency = 'USD',
  }) async {
    return 'mock_hold_$rentalRequestId';
  }
}
