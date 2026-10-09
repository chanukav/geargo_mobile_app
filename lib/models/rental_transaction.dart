import 'package:cloud_firestore/cloud_firestore.dart';

/// Fee calculation shared by checkout and the transaction details view.
class PriceBreakdown {
  const PriceBreakdown({
    required this.rentalFee,
    required this.serviceFee,
    required this.deliveryFee,
    required this.deposit,
  });

  static const double deliveryFlatFee = 15.0;
  static const double serviceRate = 0.08;

  final double rentalFee;
  final double serviceFee;
  final double deliveryFee;
  final double deposit;

  double get total => rentalFee + serviceFee + deliveryFee + deposit;

  factory PriceBreakdown.calculate({
    required double pricePerDay,
    required int days,
    required double deposit,
    required bool delivery,
  }) {
    final rental = pricePerDay * days;
    final service = double.parse((rental * serviceRate).toStringAsFixed(2));
    return PriceBreakdown(
      rentalFee: rental,
      serviceFee: service,
      deliveryFee: delivery ? deliveryFlatFee : 0,
      deposit: deposit,
    );
  }
}

/// A booking + payment record (Firestore: `transactions`).
/// Named RentalTransaction because cloud_firestore already exports `Transaction`.
class RentalTransaction {
  const RentalTransaction({
    required this.id,
    required this.bookingRef,
    required this.renterId,
    required this.shopId,
    required this.productId,
    required this.productName,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.fulfillment,
    required this.deliveryAddress,
    required this.deliveryInstructions,
    required this.deliveryWindow,
    required this.rentalFee,
    required this.serviceFee,
    required this.deliveryFee,
    required this.deposit,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String bookingRef;
  final String renterId;
  final String shopId;
  final String productId;
  final String productName;
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final String fulfillment; // pickup | delivery
  final String deliveryAddress;
  final String deliveryInstructions;
  final String deliveryWindow;
  final double rentalFee;
  final double serviceFee;
  final double deliveryFee;
  final double deposit;
  final double total;
  final String paymentMethod;
  final String paymentStatus; // paid | refunded | deposit_refunded
  final String status; // confirmed | completed | cancelled
  final DateTime? createdAt;

  bool get isDelivery => fulfillment == 'delivery';

  PriceBreakdown get breakdown => PriceBreakdown(
        rentalFee: rentalFee,
        serviceFee: serviceFee,
        deliveryFee: deliveryFee,
        deposit: deposit,
      );

  factory RentalTransaction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    double n(String k) => (d[k] as num?)?.toDouble() ?? 0;
    DateTime dt(String k) => (d[k] as Timestamp?)?.toDate() ?? DateTime.now();
    String s(String k, [String fallback = '']) => (d[k] ?? fallback) as String;

    return RentalTransaction(
      id: doc.id,
      bookingRef: s('bookingRef'),
      renterId: s('renterId'),
      shopId: s('shopId'),
      productId: s('productId'),
      productName: s('productName'),
      startDate: dt('startDate'),
      endDate: dt('endDate'),
      days: (d['days'] as num?)?.toInt() ?? 1,
      fulfillment: s('fulfillment', 'pickup'),
      deliveryAddress: s('deliveryAddress'),
      deliveryInstructions: s('deliveryInstructions'),
      deliveryWindow: s('deliveryWindow'),
      rentalFee: n('rentalFee'),
      serviceFee: n('serviceFee'),
      deliveryFee: n('deliveryFee'),
      deposit: n('deposit'),
      total: n('total'),
      paymentMethod: s('paymentMethod'),
      paymentStatus: s('paymentStatus', 'paid'),
      status: s('status', 'confirmed'),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
