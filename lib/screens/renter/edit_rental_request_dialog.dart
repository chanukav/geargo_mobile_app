import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/rental_request.dart';
import '../../services/rental_request_service.dart';

/// Modal dialog allowing a renter to edit/reschedule an existing pending rental request (CRUD 01 - Update).
class EditRentalRequestDialog extends StatefulWidget {
  final RentalRequest request;

  const EditRentalRequestDialog({
    super.key,
    required this.request,
  });

  static Future<RentalRequest?> show(BuildContext context, RentalRequest request) {
    return showDialog<RentalRequest>(
      context: context,
      builder: (_) => EditRentalRequestDialog(request: request),
    );
  }

  @override
  State<EditRentalRequestDialog> createState() => _EditRentalRequestDialogState();
}

class _EditRentalRequestDialogState extends State<EditRentalRequestDialog> {
  final _service = RentalRequestService();
  late DateTime _startDate;
  late DateTime _endDate;
  late String _deliveryMethod;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  late TextEditingController _phoneController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.request.startDate;
    _endDate = widget.request.endDate;
    _deliveryMethod = widget.request.deliveryMethod;
    _addressController = TextEditingController(text: widget.request.deliveryAddress);
    _notesController = TextEditingController(text: widget.request.renterNotes);
    _phoneController = TextEditingController(text: widget.request.renterPhone);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int get _totalDays {
    final diff = _endDate.difference(_startDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get _subtotal => widget.request.dailyPrice * _totalDays;
  double get _serviceFee => (_subtotal * 0.05).clamp(4.0, 50.0);
  double get _depositAmount => widget.request.depositAmount;
  double get _totalPrice => _subtotal + _serviceFee + _depositAmount;

  Future<void> _selectDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final updated = widget.request.copyWith(
        startDate: _startDate,
        endDate: _endDate,
        totalDays: _totalDays,
        serviceFee: _serviceFee,
        totalPrice: _totalPrice,
        deliveryMethod: _deliveryMethod,
        deliveryAddress: _deliveryMethod == 'delivery'
            ? _addressController.text.trim()
            : 'Self-pickup arranged with owner',
        renterNotes: _notesController.text.trim(),
        renterPhone: _phoneController.text.trim(),
        updatedAt: DateTime.now(),
      );

      final saved = await _service.updateRequest(updated);

      if (mounted) {
        Navigator.of(context).pop(saved);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rental request updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.deepNavy;
    final subText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final f = DateFormat('EEE, MMM d');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_calendar_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Rental Request',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      Text(
                        widget.request.equipmentName,
                        style: TextStyle(fontSize: 12.5, color: subText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Scrollable fields
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reschedule Dates
                    Text(
                      'Reschedule Rental Period',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDates,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary, width: 1.4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range_rounded, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${f.format(_startDate)}  ➔  ${f.format(_endDate)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    'Duration: $_totalDays days • Subtotal: \$${_subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Delivery Method Toggle
                    Text(
                      'Handover Method',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'pickup',
                          label: Text('Self Pickup'),
                          icon: Icon(Icons.storefront_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: 'delivery',
                          label: Text('Delivery'),
                          icon: Icon(Icons.local_shipping_rounded, size: 18),
                        ),
                      ],
                      selected: {_deliveryMethod},
                      onSelectionChanged: (set) => setState(() => _deliveryMethod = set.first),
                    ),
                    const SizedBox(height: 14),

                    if (_deliveryMethod == 'delivery') ...[
                      Text(
                        'Delivery Address',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _addressController,
                        style: TextStyle(fontSize: 13.5, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Enter destination address',
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    Text(
                      'Contact Phone',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      style: TextStyle(fontSize: 13.5, color: textColor),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Note to Owner',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      style: TextStyle(fontSize: 13.5, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Any special instructions...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Updated Cost Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Updated Total:',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            '\$${_totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _handleSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
