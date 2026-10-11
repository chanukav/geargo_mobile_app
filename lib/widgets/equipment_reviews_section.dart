import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_colors.dart';
import '../services/review_service.dart';

/// Equipment Reviews Section matching wireframe.
/// Displays reviews strictly for this equipment, and enables renters to submit reviews.
class EquipmentReviewsSection extends StatefulWidget {
  final String equipmentId;
  final String equipmentName;
  final String ownerId;
  final Color textColor;
  final Color subColor;
  final Color cardBg;
  final Color borderColor;

  const EquipmentReviewsSection({
    super.key,
    required this.equipmentId,
    this.equipmentName = 'Equipment',
    this.ownerId = 'owner_default',
    required this.textColor,
    required this.subColor,
    required this.cardBg,
    required this.borderColor,
  });

  @override
  State<EquipmentReviewsSection> createState() =>
      _EquipmentReviewsSectionState();
}

class _EquipmentReviewsSectionState extends State<EquipmentReviewsSection> {
  final ReviewService _reviewService = ReviewService();

  void _openWriteReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WriteReviewBottomSheet(
        equipmentId: widget.equipmentId,
        equipmentName: widget.equipmentName,
        ownerId: widget.ownerId,
        textColor: widget.textColor,
        subColor: widget.subColor,
        cardBg: widget.cardBg,
        borderColor: widget.borderColor,
      ),
    );
  }

  void _openAllReviewsSheet(List<Map<String, dynamic>> reviews) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Reviews (${reviews.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: widget.textColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openWriteReviewSheet();
                  },
                  icon: const Icon(Icons.rate_review_outlined, size: 16),
                  label: const Text('Write Review'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: reviews.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _buildReviewCard(reviews[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _reviewService.reviewsForEquipment(widget.equipmentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final reviews = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header matching wireframe: Reviews (24) ... View All >
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Reviews (${reviews.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: widget.textColor,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _openWriteReviewSheet,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Text(
                          '+ Write',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    if (reviews.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _openAllReviewsSheet(reviews),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: widget.subColor,
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  size: 16, color: widget.subColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (reviews.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      'No reviews yet for this equipment.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: widget.subColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _openWriteReviewSheet,
                      icon: const Icon(Icons.star_outline_rounded, size: 16),
                      label: const Text('Be the first to review'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Show first review (or up to 3) matching the wireframe card
              Column(
                children: [
                  for (final r in reviews.take(3)) _buildReviewCard(r),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> r) {
    final author = (r['author_name'] ?? 'Sarah K.').toString();
    final rating = (r['rating'] as num?)?.toInt() ?? 5;
    final comment = (r['comment'] ?? '').toString();
    final dateStr = _formatDate(r['created_at']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Reviewer circular avatar matching wireframe
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE5E7EB),
                child: Text(
                  author.isNotEmpty ? author[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 14,
                            color: const Color(0xFFFFB400),
                          );
                        }),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.subColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment,
            style: TextStyle(
              fontSize: 13.5,
              color: widget.textColor,
              height: 1.4,
            ),
          ),
        ],
      ),
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

class _WriteReviewBottomSheet extends StatefulWidget {
  final String equipmentId;
  final String equipmentName;
  final String ownerId;
  final Color textColor;
  final Color subColor;
  final Color cardBg;
  final Color borderColor;

  const _WriteReviewBottomSheet({
    required this.equipmentId,
    required this.equipmentName,
    required this.ownerId,
    required this.textColor,
    required this.subColor,
    required this.cardBg,
    required this.borderColor,
  });

  @override
  State<_WriteReviewBottomSheet> createState() =>
      _WriteReviewBottomSheetState();
}

class _WriteReviewBottomSheetState extends State<_WriteReviewBottomSheet> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  final _nameController = TextEditingController(text: 'Sarah K.');
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your review comment.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ReviewService().submitEquipmentReview(
        equipmentId: widget.equipmentId,
        rating: _selectedRating,
        comment: comment,
        authorName: _nameController.text.trim(),
        ownerId: widget.ownerId,
        equipmentName: widget.equipmentName,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your review has been submitted.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Review Equipment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: widget.textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Share your rental experience for ${widget.equipmentName}',
                style: TextStyle(fontSize: 12.5, color: widget.subColor),
              ),
              const SizedBox(height: 16),

              // Star Rating Picker
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      iconSize: 36,
                      onPressed: () => setState(() => _selectedRating = star),
                      icon: Icon(
                        star <= _selectedRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFFFB400),
                      ),
                    );
                  }),
                ),
              ),
              Center(
                child: Text(
                  '$_selectedRating of 5 Stars',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Name Field
              Text(
                'Your Name',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: widget.textColor,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Sarah K.',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.borderColor),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Comment Field
              Text(
                'Your Review',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: widget.textColor,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'e.g. Perfect bike for the trails! Marcus was great at setup. Highly recommend.',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.borderColor),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Review',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
