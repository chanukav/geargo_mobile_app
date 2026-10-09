import 'package:flutter/material.dart';

/// Models an auto-saved in-progress booking draft (NFR-04).
class BookingDraft {
  const BookingDraft({
    required this.productId,
    required this.startDate,
    required this.endDate,
    required this.isDelivery,
    this.deliveryAddress,
    this.deliveryInstructions,
    this.deliveryWindow,
    this.lastSaved,
  });

  final String productId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isDelivery;
  final String? deliveryAddress;
  final String? deliveryInstructions;
  final String? deliveryWindow;
  final DateTime? lastSaved;

  BookingDraft copyWith({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isDelivery,
    String? deliveryAddress,
    String? deliveryInstructions,
    String? deliveryWindow,
  }) {
    return BookingDraft(
      productId: productId ?? this.productId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isDelivery: isDelivery ?? this.isDelivery,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      deliveryWindow: deliveryWindow ?? this.deliveryWindow,
      lastSaved: DateTime.now(),
    );
  }
}

/// In-memory reactive draft persistence service (NFR-04).
/// Ensures user inputs (dates, fulfillment choice, address, instructions)
/// are preserved across navigation steps without loss.
class BookingDraftService {
  BookingDraftService._();
  static final BookingDraftService instance = BookingDraftService._();

  BookingDraft? _currentDraft;

  BookingDraft? get draft => _currentDraft;
  bool get hasDraft => _currentDraft != null;

  void saveDraft({
    required String productId,
    required DateTimeRange range,
    required bool isDelivery,
    String? deliveryAddress,
    String? deliveryInstructions,
    String? deliveryWindow,
  }) {
    _currentDraft = BookingDraft(
      productId: productId,
      startDate: range.start,
      endDate: range.end,
      isDelivery: isDelivery,
      deliveryAddress: deliveryAddress,
      deliveryInstructions: deliveryInstructions,
      deliveryWindow: deliveryWindow,
      lastSaved: DateTime.now(),
    );
  }

  void clearDraft() {
    _currentDraft = null;
  }
}
