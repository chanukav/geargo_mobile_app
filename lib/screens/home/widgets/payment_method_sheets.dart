import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/shop_theme.dart';
import '../../../core/utils/card_utils.dart';
import '../../../models/payment_method.dart';
import '../../../services/payment_method_service.dart';

/// Helper widget to render a brand icon / badge.
class CardBrandIcon extends StatelessWidget {
  const CardBrandIcon({
    super.key,
    required this.brand,
    this.size = 24,
  });

  final String brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final lower = brand.toLowerCase();
    Color bg = const Color(0xFFEFF6FF);
    Color fg = ShopPalette.blue;
    String label = 'CARD';

    if (lower.contains('visa')) {
      bg = const Color(0xFF1A1F71).withValues(alpha: 0.1);
      fg = const Color(0xFF1A1F71);
      label = 'VISA';
    } else if (lower.contains('mastercard')) {
      bg = const Color(0xFFEB001B).withValues(alpha: 0.1);
      fg = const Color(0xFFEB001B);
      label = 'MC';
    } else if (lower.contains('amex') || lower.contains('american')) {
      bg = const Color(0xFF006FCF).withValues(alpha: 0.1);
      fg = const Color(0xFF006FCF);
      label = 'AMEX';
    }

    return Container(
      width: size * 1.5,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.42,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Modal bottom sheet for adding a new card.
/// ZERO LEAKAGE: Controllers are strictly cleared and disposed.
/// Full PAN and CVV are never saved or logged.
class AddPaymentMethodSheet extends StatefulWidget {
  const AddPaymentMethodSheet({
    super.key,
    required this.service,
    this.onAdded,
  });

  final PaymentMethodService service;
  final ValueChanged<PaymentMethod>? onAdded;

  static Future<void> show(
    BuildContext context, {
    required PaymentMethodService service,
    ValueChanged<PaymentMethod>? onAdded,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPaymentMethodSheet(service: service, onAdded: onAdded),
    );
  }

  @override
  State<AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<AddPaymentMethodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  CardBrand _detectedBrand = CardBrand.other;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_onCardNumberChanged);
  }

  void _onCardNumberChanged() {
    final brand = CardUtils.detectBrand(_cardNumberController.text);
    if (brand != _detectedBrand) {
      setState(() => _detectedBrand = brand);
    }
  }

  @override
  void dispose() {
    // Security compliance: clear raw sensitive text before disposing
    _nameController.clear();
    _cardNumberController.clear();
    _expiryController.clear();
    _cvvController.clear();

    _nameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final rawNumber = _cardNumberController.text;
      final last4 = CardUtils.extractLast4(rawNumber);
      final brandName = _detectedBrand.displayName;
      final expiry = CardUtils.parseExpiry(_expiryController.text);
      final holderName = _nameController.text.trim();

      // Clear the sensitive input controllers immediately
      _cardNumberController.clear();
      _cvvController.clear();

      final id = await widget.service.addPaymentMethod(
        brand: brandName,
        last4: last4,
        expMonth: expiry.month,
        expYear: expiry.year,
        cardHolderName: holderName,
      );

      final newMethod = PaymentMethod(
        id: id,
        brand: brandName,
        last4: last4,
        expMonth: expiry.month,
        expYear: expiry.year,
        cardHolderName: holderName,
        isDefault: true,
      );

      if (mounted) {
        widget.onAdded?.call(newMethod);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$brandName •••• $last4 added successfully.'),
            backgroundColor: const Color(0xFF137333),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textCol,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Reassurance security badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_outlined, size: 20, color: ShopPalette.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Demo only. Your full card number is never saved.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12.5, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 1. Card Holder Name
              Text(
                'CARDHOLDER NAME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Maya Fernando',
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Cardholder name is required';
                  }
                  if (val.trim().length < 2) {
                    return 'Name is too short';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2. Card Number
              Text(
                'CARD NUMBER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CardNumberInputFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: '4242 4242 4242 4242',
                  prefixIcon: const Icon(Icons.credit_card_rounded, size: 20),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CardBrandIcon(brand: _detectedBrand.displayName, size: 22),
                      ],
                    ),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Card number is required';
                  }
                  if (!CardUtils.hasValidLength(val)) {
                    return 'Invalid length for ${_detectedBrand.displayName}';
                  }
                  if (!CardUtils.isValidLuhn(val)) {
                    return 'Invalid card number checksum (Luhn check failed)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Expiry and CVV Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPIRY DATE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CardExpiryInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            hintText: 'MM/YY',
                            prefixIcon: const Icon(Icons.date_range_rounded, size: 20),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          validator: CardUtils.validateExpiry,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SECURITY CODE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(_detectedBrand == CardBrand.amex ? 4 : 3),
                          ],
                          decoration: InputDecoration(
                            hintText: _detectedBrand == CardBrand.amex ? '4 digits' : '3 digits',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          validator: (val) => CardUtils.validateCvv(val, _detectedBrand),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button (min 48px tap target)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _saving ? null : _handleSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save Payment Method',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

/// Modal bottom sheet for viewing and acting on an existing saved card.
class PaymentMethodDetailsSheet extends StatelessWidget {
  const PaymentMethodDetailsSheet({
    super.key,
    required this.method,
    required this.service,
    this.onChanged,
  });

  final PaymentMethod method;
  final PaymentMethodService service;
  final VoidCallback? onChanged;

  static Future<void> show(
    BuildContext context, {
    required PaymentMethod method,
    required PaymentMethodService service,
    VoidCallback? onChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentMethodDetailsSheet(
        method: method,
        service: service,
        onChanged: onChanged,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove ${method.displayTitle}?'),
        content: const Text(
          'This card will be removed from your saved payment methods. '
          'Active and upcoming bookings will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        Navigator.of(context).pop(); // Close sheet
        try {
          await service.deletePaymentMethod(method.id);
          onChanged?.call();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${method.displayTitle} removed.')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error removing card: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    });
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).pop(); // Close details sheet
    EditPaymentMethodSheet.show(
      context,
      method: method,
      service: service,
      onChanged: onChanged,
    );
  }

  Future<void> _handleSetDefault(BuildContext context) async {
    Navigator.of(context).pop(); // Close details sheet
    try {
      await service.setDefaultPaymentMethod(method.id);
      onChanged?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${method.displayTitle} set as default payment method.'),
            backgroundColor: const Color(0xFF137333),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set default: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CardBrandIcon(brand: method.brand, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayTitle,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textCol),
                    ),
                    Text(
                      'Expires ${method.formattedExpiry}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              if (method.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'DEFAULT',
                    style: TextStyle(
                      color: Color(0xFF137333),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
          const SizedBox(height: 8),

          // Cardholder Name row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cardholder', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                Text(
                  method.cardHolderName.isNotEmpty ? method.cardHolderName : '—',
                  style: TextStyle(fontWeight: FontWeight.w600, color: textCol, fontSize: 13.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Actions
          if (!method.isDefault) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Set as Default'),
                onPressed: () => _handleSetDefault(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ShopPalette.blue,
                  side: const BorderSide(color: ShopPalette.blue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Card'),
                    onPressed: () => _openEdit(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textCol,
                      side: BorderSide(color: isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete'),
                    onPressed: () => _confirmDelete(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Modal bottom sheet for editing an existing card's mutable fields.
class EditPaymentMethodSheet extends StatefulWidget {
  const EditPaymentMethodSheet({
    super.key,
    required this.method,
    required this.service,
    this.onChanged,
  });

  final PaymentMethod method;
  final PaymentMethodService service;
  final VoidCallback? onChanged;

  static Future<void> show(
    BuildContext context, {
    required PaymentMethod method,
    required PaymentMethodService service,
    VoidCallback? onChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPaymentMethodSheet(
        method: method,
        service: service,
        onChanged: onChanged,
      ),
    );
  }

  @override
  State<EditPaymentMethodSheet> createState() => _EditPaymentMethodSheetState();
}

class _EditPaymentMethodSheetState extends State<EditPaymentMethodSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _expiryController;
  late bool _isDefault;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.method.cardHolderName);
    _expiryController = TextEditingController(text: widget.method.formattedExpiry);
    _isDefault = widget.method.isDefault;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final expiry = CardUtils.parseExpiry(_expiryController.text);
      await widget.service.updatePaymentMethod(
        methodId: widget.method.id,
        cardHolderName: _nameController.text.trim(),
        expMonth: expiry.month,
        expYear: expiry.year,
        isDefault: _isDefault,
      );

      if (mounted) {
        widget.onChanged?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.method.displayTitle} updated.'),
            backgroundColor: const Color(0xFF137333),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Payment Method',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textCol),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Immutable card preview
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CardBrandIcon(brand: widget.method.brand, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      widget.method.displayTitle,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textCol),
                    ),
                    const Spacer(),
                    Text(
                      'Card number locked',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                const SizedBox(height: 10),
              ],

              // Cardholder name
              Text(
                'CARDHOLDER NAME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Cardholder name is required' : null,
              ),
              const SizedBox(height: 16),

              // Expiry Date
              Text(
                'EXPIRY DATE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _expiryController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CardExpiryInputFormatter(),
                ],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                validator: CardUtils.validateExpiry,
              ),
              const SizedBox(height: 16),

              // Set as default checkbox
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                title: const Text('Set as default payment method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                activeTrackColor: ShopPalette.blue,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _saving ? null : _handleSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
