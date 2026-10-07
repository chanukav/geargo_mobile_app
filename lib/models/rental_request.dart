import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';

/// Represents the lifecycle status of a rental request.
enum RentalStatus {
  pending,
  approved,
  active,
  completed,
  cancelled,
  rejected;

  String get key => name;

  static RentalStatus fromString(String? value) {
    if (value == null) return RentalStatus.pending;
    return RentalStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == value.toLowerCase().trim(),
      orElse: () => RentalStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case RentalStatus.pending:
        return 'Pending Review';
      case RentalStatus.approved:
        return 'Approved';
      case RentalStatus.active:
        return 'In Progress / Active';
      case RentalStatus.completed:
        return 'Completed';
      case RentalStatus.cancelled:
        return 'Cancelled';
      case RentalStatus.rejected:
        return 'Declined';
    }
  }

  Color get color {
    switch (this) {
      case RentalStatus.pending:
        return AppColors.warning;
      case RentalStatus.approved:
        return AppColors.info;
      case RentalStatus.active:
        return AppColors.success;
      case RentalStatus.completed:
        return const Color(0xFF6366F1);
      case RentalStatus.cancelled:
      case RentalStatus.rejected:
        return AppColors.error;
    }
  }

  IconData get icon {
    switch (this) {
      case RentalStatus.pending:
        return Icons.hourglass_top_rounded;
      case RentalStatus.approved:
        return Icons.check_circle_outline_rounded;
      case RentalStatus.active:
        return Icons.play_circle_outline_rounded;
      case RentalStatus.completed:
        return Icons.task_alt_rounded;
      case RentalStatus.cancelled:
        return Icons.cancel_outlined;
      case RentalStatus.rejected:
        return Icons.highlight_off_rounded;
    }
  }
}

/// Domain model representing a Rental Request (CRUD 01 - Rental Request Management).
/// Enables renters to request gear, manage dates, track approvals, and cancel requests.
class RentalRequest {
  final String id;
  final String renterId;
  final String renterName;
  final String renterEmail;
  final String renterPhone;

  final String equipmentId;
  final String equipmentName;
  final String equipmentCategory;
  final String equipmentImage;
  final double dailyPrice;

  final String ownerId;
  final String ownerName;

  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final double serviceFee;
  final double depositAmount;
  final double totalPrice;

  final String deliveryMethod; // 'pickup' or 'delivery'
  final String deliveryAddress;
  final String renterNotes;

  final RentalStatus status;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RentalRequest({
    required this.id,
    required this.renterId,
    required this.renterName,
    required this.renterEmail,
    required this.renterPhone,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentCategory,
    required this.equipmentImage,
    required this.dailyPrice,
    required this.ownerId,
    required this.ownerName,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.serviceFee,
    required this.depositAmount,
    required this.totalPrice,
    this.deliveryMethod = 'pickup',
    this.deliveryAddress = '',
    this.renterNotes = '',
    this.status = RentalStatus.pending,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDelivery => deliveryMethod.toLowerCase() == 'delivery';
  bool get canEdit => status == RentalStatus.pending;
  bool get canCancel =>
      status == RentalStatus.pending || status == RentalStatus.approved;

  String get dateRangeFormatted {
    final f = DateFormat('MMM d, yyyy');
    return '${f.format(startDate)} – ${f.format(endDate)}';
  }

  String get shortDateRange {
    final f = DateFormat('MMM d');
    final fy = DateFormat('MMM d, yyyy');
    if (startDate.year == endDate.year) {
      return '${f.format(startDate)} – ${fy.format(endDate)}';
    }
    return '${f.format(startDate)}, ${startDate.year} – ${fy.format(endDate)}';
  }

  RentalRequest copyWith({
    String? id,
    String? renterId,
    String? renterName,
    String? renterEmail,
    String? renterPhone,
    String? equipmentId,
    String? equipmentName,
    String? equipmentCategory,
    String? equipmentImage,
    double? dailyPrice,
    String? ownerId,
    String? ownerName,
    DateTime? startDate,
    DateTime? endDate,
    int? totalDays,
    double? serviceFee,
    double? depositAmount,
    double? totalPrice,
    String? deliveryMethod,
    String? deliveryAddress,
    String? renterNotes,
    RentalStatus? status,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RentalRequest(
      id: id ?? this.id,
      renterId: renterId ?? this.renterId,
      renterName: renterName ?? this.renterName,
      renterEmail: renterEmail ?? this.renterEmail,
      renterPhone: renterPhone ?? this.renterPhone,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      equipmentCategory: equipmentCategory ?? this.equipmentCategory,
      equipmentImage: equipmentImage ?? this.equipmentImage,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      serviceFee: serviceFee ?? this.serviceFee,
      depositAmount: depositAmount ?? this.depositAmount,
      totalPrice: totalPrice ?? this.totalPrice,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      renterNotes: renterNotes ?? this.renterNotes,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'renter_id': renterId,
      'renter_name': renterName,
      'renter_email': renterEmail,
      'renter_phone': renterPhone,
      'equipment_id': equipmentId,
      'equipment_name': equipmentName,
      'equipment_category': equipmentCategory,
      'equipment_image': equipmentImage,
      'daily_price': dailyPrice,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'total_days': totalDays,
      'service_fee': serviceFee,
      'deposit_amount': depositAmount,
      'total_price': totalPrice,
      'delivery_method': deliveryMethod,
      'delivery_address': deliveryAddress,
      'renter_notes': renterNotes,
      'status': status.name,
      'cancellation_reason': cancellationReason,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory RentalRequest.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    double parseNum(dynamic v, [double fallback = 0.0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    int parseInt(dynamic v, [int fallback = 1]) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    return RentalRequest(
      id: (docId != null && docId.isNotEmpty)
          ? docId
          : (map['id']?.toString() ?? ''),
      renterId: map['renter_id']?.toString() ?? '',
      renterName: map['renter_name']?.toString() ?? 'Renter',
      renterEmail: map['renter_email']?.toString() ?? '',
      renterPhone: map['renter_phone']?.toString() ?? '',
      equipmentId: map['equipment_id']?.toString() ?? '',
      equipmentName: map['equipment_name']?.toString() ?? 'Gear Listing',
      equipmentCategory: map['equipment_category']?.toString() ?? 'General',
      equipmentImage: map['equipment_image']?.toString() ?? '',
      dailyPrice: parseNum(map['daily_price']),
      ownerId: map['owner_id']?.toString() ?? '',
      ownerName: map['owner_name']?.toString() ?? 'Gear Owner',
      startDate: parseDate(map['start_date']),
      endDate: parseDate(map['end_date']),
      totalDays: parseInt(map['total_days'], 1),
      serviceFee: parseNum(map['service_fee'], 5.0),
      depositAmount: parseNum(map['deposit_amount'], 20.0),
      totalPrice: parseNum(map['total_price']),
      deliveryMethod: map['delivery_method']?.toString() ?? 'pickup',
      deliveryAddress: map['delivery_address']?.toString() ?? '',
      renterNotes: map['renter_notes']?.toString() ?? '',
      status: RentalStatus.fromString(map['status']?.toString()),
      cancellationReason: map['cancellation_reason']?.toString(),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }
}
