import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_helper.dart';
import '../../models/rental_request.dart';
import '../../services/rental_request_service.dart';
import 'create_rental_request_sheet.dart';
import 'edit_rental_request_dialog.dart';

/// Screen displaying the detailed lifecycle and breakdown of a Rental Request.
/// Enables editing, tracking, status transitions, and cancelling.
class RentalRequestDetailsScreen extends StatefulWidget {
  final RentalRequest request;

  const RentalRequestDetailsScreen({super.key, required this.request});

  @override
  State<RentalRequestDetailsScreen> createState() =>
      _RentalRequestDetailsScreenState();
}

class _RentalRequestDetailsScreenState extends State<RentalRequestDetailsScreen> {
  late RentalRequest _request;
  final _service = RentalRequestService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  Future<void> _handleEdit() async {
    final updated = await EditRentalRequestDialog.show(context, _request);
    if (updated != null && mounted) {
      setState(() => _request = updated);
    }
  }

  Future<void> _handleCancel() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Cancel Rental Request?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this request? The owner will be notified immediately.',
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason for cancellation (optional)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Request'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);
      try {
        final reason = reasonController.text.trim().isEmpty
            ? 'Cancelled by renter'
            : reasonController.text.trim();
        await _service.cancelRequest(_request.id, reason: reason);
        final fresh = await _service.getRequestById(_request.id);
        if (mounted && fresh != null) {
          setState(() {
            _request = fresh;
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rental request has been cancelled.'),
              backgroundColor: AppColors.deepNavy,
            ),
          );
        }
      } catch (e) {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleDeletePermanently() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Request Record?'),
        content: const Text(
          'This will permanently delete this booking history item from your account.',
          style: TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _service.deleteRequestPermanently(_request.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking record removed.'),
            backgroundColor: AppColors.deepNavy,
          ),
        );
      }
    }
  }

  Future<void> _handleCompleteReturn() async {
    setState(() => _isProcessing = true);
    await _service.updateStatus(_request.id, RentalStatus.completed);
    final fresh = await _service.getRequestById(_request.id);
    if (mounted && fresh != null) {
      setState(() {
        _request = fresh;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rental marked as returned and completed!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.deepNavy;
    final subText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderCol = isDark ? AppColors.borderDark : AppColors.borderLight;

    final dateFormat = DateFormat('EEEE, MMM d, yyyy');

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Booking Details',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          if (_request.canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Request',
              onPressed: _handleEdit,
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'edit') _handleEdit();
              if (value == 'cancel') _handleCancel();
              if (value == 'delete') _handleDeletePermanently();
            },
            itemBuilder: (context) => [
              if (_request.canEdit)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Reschedule / Edit'),
                    ],
                  ),
                ),
              if (_request.canCancel)
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Cancel Request'),
                    ],
                  ),
                ),
              if (_request.status == RentalStatus.completed ||
                  _request.status == RentalStatus.cancelled)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete Record'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _request.status.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _request.status.color.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _request.status.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _request.status.icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _request.status.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _request.status.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getStatusDescription(_request.status),
                          style: TextStyle(fontSize: 12.5, color: subText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stepper / Lifecycle Tracker
            _buildTimelineCard(cardBg, borderCol, textColor, subText),
            const SizedBox(height: 20),

            // Equipment Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderCol),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: EquipmentImageViewer(
                            imageSource: _request.equipmentImage,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _request.equipmentCategory.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _request.equipmentName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${_request.dailyPrice.toStringAsFixed(0)} / day',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Owner info row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.deepNavy,
                        child: Text(
                          _request.ownerName.isNotEmpty
                              ? _request.ownerName[0].toUpperCase()
                              : 'O',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Owner: ${_request.ownerName}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const Text(
                              'Verified GearGo Host',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Contacting ${_request.ownerName}...'),
                              backgroundColor: AppColors.deepNavy,
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: const Text('Message', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rental Schedule & Location
            _buildSectionHeader('Rental Schedule & Logistics', textColor),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                children: [
                  _detailRow(
                    Icons.event_available_rounded,
                    'Pickup / Start Date',
                    dateFormat.format(_request.startDate),
                    textColor,
                    subText,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  _detailRow(
                    Icons.event_busy_rounded,
                    'Return / End Date',
                    dateFormat.format(_request.endDate),
                    textColor,
                    subText,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  _detailRow(
                    Icons.timelapse_rounded,
                    'Duration',
                    '${_request.totalDays} ${_request.totalDays == 1 ? 'Day' : 'Days'}',
                    textColor,
                    subText,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  _detailRow(
                    _request.isDelivery
                        ? Icons.local_shipping_rounded
                        : Icons.storefront_rounded,
                    'Handover Option',
                    _request.isDelivery ? 'Home Delivery' : 'Self Pickup',
                    textColor,
                    subText,
                  ),
                  if (_request.deliveryAddress.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1),
                    ),
                    _detailRow(
                      Icons.place_outlined,
                      'Location / Address',
                      _request.deliveryAddress,
                      textColor,
                      subText,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notes / Special Instructions
            if (_request.renterNotes.isNotEmpty) ...[
              _buildSectionHeader('Note to Owner', textColor),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Text(
                  _request.renterNotes,
                  style: TextStyle(fontSize: 13.5, color: textColor, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Cancellation Reason if any
            if (_request.cancellationReason != null &&
                _request.cancellationReason!.isNotEmpty) ...[
              _buildSectionHeader('Cancellation Detail', textColor),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _request.cancellationReason!,
                        style: const TextStyle(fontSize: 13, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Payment & Financial Summary
            _buildSectionHeader('Financial Breakdown', textColor),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                children: [
                  _priceRow(
                    'Daily rate (\$${_request.dailyPrice.toStringAsFixed(0)} × ${_request.totalDays}d)',
                    '\$${(_request.dailyPrice * _request.totalDays).toStringAsFixed(2)}',
                    textColor,
                  ),
                  const SizedBox(height: 8),
                  _priceRow(
                    'GearGo Service Fee',
                    '\$${_request.serviceFee.toStringAsFixed(2)}',
                    textColor,
                  ),
                  const SizedBox(height: 8),
                  _priceRow(
                    'Refundable Security Deposit',
                    '\$${_request.depositAmount.toStringAsFixed(2)}',
                    textColor,
                    isNote: true,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Price',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '\$${_request.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Sticky Bottom Bar with Contextual Actions
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: _buildBottomActions(),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    if (_isProcessing) {
      return const Center(
        heightFactor: 1,
        child: CircularProgressIndicator(),
      );
    }

    switch (_request.status) {
      case RentalStatus.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _handleCancel,
                child: const Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _handleEdit,
                child: const Text('Edit / Reschedule', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );

      case RentalStatus.approved:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _handleCancel,
                child: const Text('Cancel Booking'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contacting owner to arrange handover meetup...'),
                      backgroundColor: AppColors.deepNavy,
                    ),
                  );
                },
                child: const Text('Arrange Pickup', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );

      case RentalStatus.active:
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _handleCompleteReturn,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Mark as Returned & Completed', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        );

      case RentalStatus.completed:
      case RentalStatus.cancelled:
      case RentalStatus.rejected:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _handleDeletePermanently,
                child: const Text('Delete Record'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  CreateRentalRequestSheet.show(
                    context,
                    equipmentId: _request.equipmentId,
                    equipmentName: _request.equipmentName,
                    equipmentCategory: _request.equipmentCategory,
                    equipmentImage: _request.equipmentImage,
                    dailyPrice: _request.dailyPrice,
                    ownerId: _request.ownerId,
                    ownerName: _request.ownerName,
                  );
                },
                child: const Text('Rent Again', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildTimelineCard(
    Color cardBg,
    Color borderCol,
    Color textColor,
    Color subText,
  ) {
    int activeStep = 0;
    if (_request.status == RentalStatus.approved) activeStep = 1;
    if (_request.status == RentalStatus.active) activeStep = 2;
    if (_request.status == RentalStatus.completed) activeStep = 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Progress Tracker',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stepNode(0, 'Requested', activeStep >= 0),
              _stepConnector(activeStep >= 1),
              _stepNode(1, 'Approved', activeStep >= 1),
              _stepConnector(activeStep >= 2),
              _stepNode(2, 'In Use', activeStep >= 2),
              _stepConnector(activeStep >= 3),
              _stepNode(3, 'Returned', activeStep >= 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepNode(int index, String title, bool reached) {
    final color = reached ? AppColors.primary : const Color(0xFFCBD5E1);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: reached ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              reached ? Icons.check_rounded : Icons.circle,
              size: 14,
              color: reached ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: reached ? FontWeight.w800 : FontWeight.w500,
              color: reached ? AppColors.deepNavy : const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _stepConnector(bool reached) {
    return Container(
      width: 22,
      height: 2.5,
      color: reached ? AppColors.primary : const Color(0xFFCBD5E1),
      margin: const EdgeInsets.only(bottom: 18),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color subText,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11.5, color: subText)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value, Color textColor, {bool isNote = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isNote ? AppColors.textSecondaryLight : textColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }

  String _getStatusDescription(RentalStatus status) {
    switch (status) {
      case RentalStatus.pending:
        return 'Waiting for owner confirmation';
      case RentalStatus.approved:
        return 'Owner confirmed! Coordinate handover';
      case RentalStatus.active:
        return 'Gear currently in your possession';
      case RentalStatus.completed:
        return 'Rental successfully completed and returned';
      case RentalStatus.cancelled:
        return 'Booking was cancelled';
      case RentalStatus.rejected:
        return 'Owner could not fulfill request';
    }
  }
}
