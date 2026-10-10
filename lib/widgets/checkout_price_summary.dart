import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Milestone 02 UI-01: separates [dueNow] from refundable deposit hold.
class CheckoutPriceSummary extends StatelessWidget {
  final double rentalSubtotal;
  final double serviceFee;
  final double deliveryFee;
  final double depositAmount;
  final bool isDark;
  final Color? textColor;

  const CheckoutPriceSummary({
    super.key,
    required this.rentalSubtotal,
    required this.serviceFee,
    required this.deliveryFee,
    required this.depositAmount,
    this.isDark = false,
    this.textColor,
  });

  double get dueNow => rentalSubtotal + serviceFee + deliveryFee;

  @override
  Widget build(BuildContext context) {
    final title = textColor ??
        (isDark ? AppColors.textPrimaryDark : AppColors.deepNavy);
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardFill =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final holdFill =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Due Now',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: title,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rental fee, platform fee, and delivery (if selected)',
                style: TextStyle(fontSize: 12, color: sub),
              ),
              const SizedBox(height: 12),
              _row('Rental fee', rentalSubtotal, title),
              const SizedBox(height: 6),
              _row('Service fee', serviceFee, title),
              if (deliveryFee > 0) ...[
                const SizedBox(height: 6),
                _row('Delivery fee', deliveryFee, title),
              ],
              const Divider(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Due Now Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: title,
                    ),
                  ),
                  Text(
                    '\$${dueNow.toStringAsFixed(2)}',
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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: holdFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Refundable Security Hold',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: title,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${depositAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: title,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This amount is authorized temporarily on your card and '
                        'released within 48 hours after return without damage.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: title,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13.5, color: color)),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
