import 'dart:math' as math;

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

/// Abstract contract for payment processing gateways.
/// Enables seamless substitution of a real gateway (e.g. Stripe, FPX, PayPal)
/// in production without changing application UI code.
abstract class PaymentService {
  Future<PaymentResult> processPayment({
    required double amount,
    required String paymentMethod,
    required String bookingRef,
  });
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
}
