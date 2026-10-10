import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_colors.dart';
import '../services/review_service.dart';

/// NFR-05: read-only review list for an equipment listing.
class EquipmentReviewsSection extends StatelessWidget {
  final String equipmentId;
  final Color textColor;
  final Color subColor;
  final Color cardBg;
  final Color borderColor;

  const EquipmentReviewsSection({
    super.key,
    required this.equipmentId,
    required this.textColor,
    required this.subColor,
    required this.cardBg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ReviewService().reviewsForEquipment(equipmentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return Text(
            'No renter reviews yet. Reviews appear after completed rentals.',
            style: TextStyle(fontSize: 13, color: subColor, height: 1.35),
          );
        }
        return Column(
          children: [
            for (final r in reviews.take(8))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final rating = (r['rating'] as num?)?.toInt() ?? 0;
                          return Icon(
                            i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 16,
                            color: AppColors.warning,
                          );
                        }),
                        const Spacer(),
                        Text(
                          _formatDate(r['created_at']),
                          style: TextStyle(fontSize: 11, color: subColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r['comment']?.toString() ?? '',
                      style: TextStyle(fontSize: 13.5, color: textColor, height: 1.35),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    DateTime? dt;
    if (raw is Timestamp) dt = raw.toDate();
    if (raw is DateTime) dt = raw;
    dt ??= DateTime.tryParse(raw.toString());
    if (dt == null) return '';
    return DateFormat('MMM d, yyyy').format(dt);
  }
}
