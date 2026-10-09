import 'package:flutter/material.dart';

import '../../../core/theme/shop_theme.dart';

/// Reusable segmented fulfillment toggle switch (Self Pickup vs Door Delivery).
class FulfillmentToggle extends StatelessWidget {
  const FulfillmentToggle({
    super.key,
    required this.isDelivery,
    required this.onChanged,
  });

  final bool isDelivery;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleOption(
              label: 'Self Pickup',
              icon: Icons.storefront_outlined,
              selected: !isDelivery,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _toggleOption(
              label: 'Door Delivery',
              icon: Icons.local_shipping_outlined,
              selected: isDelivery,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? ShopPalette.text : ShopPalette.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? ShopPalette.text : ShopPalette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
