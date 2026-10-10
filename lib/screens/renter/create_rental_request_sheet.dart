import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_helper.dart';
import '../../models/rental_request.dart';
import '../../services/payment_service.dart';
import '../../services/rental_request_service.dart';
import '../../widgets/checkout_price_summary.dart';

/// Interactive modal sheet to submit a new Rental Request (CRUD 01 - Create).
class CreateRentalRequestSheet extends StatefulWidget {
  final String equipmentId;
  final String equipmentName;
  final String equipmentCategory;
  final String equipmentImage;
  final double dailyPrice;
  final String ownerId;
  final String ownerName;

  const CreateRentalRequestSheet({
    super.key,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentCategory,
    required this.equipmentImage,
    required this.dailyPrice,
    this.ownerId = 'owner_default',
    this.ownerName = 'Gear Owner',
  });

  /// Convenient helper to present this sheet with smooth bottom animation.
  static Future<RentalRequest?> show(
    BuildContext context, {
    required String equipmentId,
    required String equipmentName,
    required String equipmentCategory,
    required String equipmentImage,
    required double dailyPrice,
    String ownerId = 'owner_default',
    String ownerName = 'Gear Owner',
  }) {
    return showModalBottomSheet<RentalRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateRentalRequestSheet(
        equipmentId: equipmentId,
        equipmentName: equipmentName,
        equipmentCategory: equipmentCategory,
        equipmentImage: equipmentImage,
        dailyPrice: dailyPrice,
        ownerId: ownerId,
        ownerName: ownerName,
      ),
    );
  }

  @override
  State<CreateRentalRequestSheet> createState() => _CreateRentalRequestSheetState();
}

class _CreateRentalRequestSheetState extends State<CreateRentalRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _service = RentalRequestService();

  late DateTime _startDate;
  late DateTime _endDate;
  String _deliveryMethod = 'pickup'; // 'pickup' or 'delivery'

  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;

  bool _isSubmitting = false;
  RentalRequest? _confirmedRequest;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    _endDate = _startDate.add(const Duration(days: 3));

    final user = FirebaseAuth.instance.currentUser;
    _addressController = TextEditingController(text: '74 Flower Road, Colombo 07');
    _phoneController = TextEditingController(
      text: user?.phoneNumber ?? '+94 77 555 8921',
    );
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _totalDays {
    final diff = _endDate.difference(_startDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get _subtotal => widget.dailyPrice * _totalDays;
  double get _serviceFee => (_subtotal * 0.05).clamp(4.0, 50.0);
  double get _deliveryFee => _deliveryMethod == 'delivery' ? 12.0 : 0.0;
  double get _depositAmount => (widget.dailyPrice * 0.8).clamp(25.0, 150.0);
  double get _dueNow => _subtotal + _serviceFee + _deliveryFee;
  double get _totalPrice => _dueNow + _depositAmount;

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.deepNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final renterId = user?.uid ?? 'guest_renter';
      final renterName = (user?.displayName != null && user!.displayName!.isNotEmpty)
          ? user.displayName!
          : (user?.email?.split('@').first ?? 'Guest Renter');
      final renterEmail = user?.email ?? 'renter@geargo.com';

      final request = RentalRequest(
        id: '',
        renterId: renterId,
        renterName: renterName,
        renterEmail: renterEmail,
        renterPhone: _phoneController.text.trim(),
        equipmentId: widget.equipmentId,
        equipmentName: widget.equipmentName,
        equipmentCategory: widget.equipmentCategory,
        equipmentImage: widget.equipmentImage,
        dailyPrice: widget.dailyPrice,
        ownerId: widget.ownerId,
        ownerName: widget.ownerName,
        startDate: _startDate,
        endDate: _endDate,
        totalDays: _totalDays,
        serviceFee: _serviceFee,
        deliveryFee: _deliveryFee,
        depositAmount: _depositAmount,
        totalPrice: _totalPrice,
        deliveryMethod: _deliveryMethod,
        deliveryAddress: _deliveryMethod == 'delivery'
            ? _addressController.text.trim()
            : 'Self-pickup arranged with owner',
        renterNotes: _notesController.text.trim(),
        status: RentalStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await _service.createRequest(request);
      final holdId = await PaymentService().authorizeDepositHold(
        depositAmount: _depositAmount,
        rentalRequestId: created.id,
      );
      final withHold = created.copyWith(depositHoldId: holdId);
      await _service.updateRequest(withHold);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _confirmedRequest = withHold;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rental request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildConfirmationView(BuildContext context, RentalRequest req) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.deepNavy;
    final subText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderCol = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 18),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: borderCol,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Animated checkmark
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Rental Request Confirmed!',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Your booking request has been sent to ${req.ownerName}. You can track it under Bookings.',
            style: TextStyle(fontSize: 13.5, color: subText, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Booking Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 58,
                        height: 58,
                        child: EquipmentImageViewer(imageSource: req.equipmentImage),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.equipmentName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Owner: ${req.ownerName}',
                            style: TextStyle(fontSize: 12.5, color: subText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _confirmDetailRow(Icons.calendar_month_rounded, 'Rental Period', req.shortDateRange, textColor, subText),
                const SizedBox(height: 8),
                _confirmDetailRow(
                  req.isDelivery ? Icons.local_shipping_outlined : Icons.storefront_outlined,
                  'Handover',
                  req.isDelivery ? 'Delivery' : 'Self Pickup',
                  textColor,
                  subText,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CheckoutPriceSummary(
            rentalSubtotal: req.rentalSubtotal,
            serviceFee: req.serviceFee,
            deliveryFee: req.deliveryFee,
            depositAmount: req.depositAmount,
            isDark: isDark,
            textColor: textColor,
          ),
          const SizedBox(height: 24),

          // Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.of(context).pop(req),
              child: const Text(
                'Great, View My Bookings',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _confirmDetailRow(IconData icon, String label, String value, Color valCol, Color subText, {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12.5, color: subText)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valCol,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_confirmedRequest != null) {
      return _buildConfirmationView(context, _confirmedRequest!);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.deepNavy;
    final subText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderCol = isDark ? AppColors.borderDark : AppColors.borderLight;

    final dateFormat = DateFormat('EEE, MMM d');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: borderCol,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request to Rent',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reserve gear directly from the owner',
                        style: TextStyle(fontSize: 13, color: subText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: textColor,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Equipment Preview Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: EquipmentImageViewer(
                                imageSource: widget.equipmentImage,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.equipmentName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        widget.equipmentCategory,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Owner: ${widget.ownerName}',
                                      style: TextStyle(fontSize: 12, color: subText),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${widget.dailyPrice.toStringAsFixed(0)} / day',
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
                    ),
                    const SizedBox(height: 20),

                    // Date Selection Picker Card
                    Text(
                      'Rental Dates',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDateRange,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${dateFormat.format(_startDate)}  ➔  ${dateFormat.format(_endDate)}',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total duration: $_totalDays ${_totalDays == 1 ? 'day' : 'days'}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.edit_calendar_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Handover Method Segment
                    Text(
                      'Handover Preference',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _methodOption(
                            key: 'pickup',
                            title: 'Self Pickup',
                            subtitle: 'Free at owner spot',
                            icon: Icons.storefront_rounded,
                            selected: _deliveryMethod == 'pickup',
                            borderCol: borderCol,
                            textColor: textColor,
                            subText: subText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _methodOption(
                            key: 'delivery',
                            title: 'Delivery',
                            subtitle: 'Drop-off at door',
                            icon: Icons.local_shipping_rounded,
                            selected: _deliveryMethod == 'delivery',
                            borderCol: borderCol,
                            textColor: textColor,
                            subText: subText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Delivery Address (if Delivery)
                    if (_deliveryMethod == 'delivery') ...[
                      Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _addressController,
                        style: TextStyle(fontSize: 14, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Enter street address, city, postal code',
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (_deliveryMethod == 'delivery' && (v == null || v.trim().isEmpty)) {
                            return 'Please enter delivery address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Phone Number
                    Text(
                      'Contact Phone Number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: '+94 77 123 4567',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Please enter a contact number' : null,
                    ),
                    const SizedBox(height: 16),

                    // Notes / Special Request
                    Text(
                      'Message to Owner (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      maxLength: 250,
                      style: TextStyle(fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Ask about sizing, accessories, or meetup times...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    CheckoutPriceSummary(
                      rentalSubtotal: _subtotal,
                      serviceFee: _serviceFee,
                      deliveryFee: _deliveryFee,
                      depositAmount: _depositAmount,
                      isDark: isDark,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.credit_card_outlined,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Submitting authorizes a sandbox deposit hold (SetupIntent-style) '
                              'for \$${_depositAmount.toStringAsFixed(2)} on your saved payment method. '
                              'Rental fees are charged separately as Due Now.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: bg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.secondary.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Submit Request · Due Now \$${_dueNow.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodOption({
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required Color borderCol,
    required Color textColor,
    required Color subText,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _deliveryMethod = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : borderCol,
            width: selected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : subText,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: subText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
