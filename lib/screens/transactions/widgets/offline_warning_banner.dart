import 'package:flutter/material.dart';

/// Offline connection warning notice banner (NFR-04).
/// Informs the user when operating in offline mode or during connectivity interruptions.
class OfflineWarningBanner extends StatelessWidget {
  const OfflineWarningBanner({
    super.key,
    this.message = 'You are currently offline. Actions and drafts will sync when reconnected.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFFEF3C7),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 16,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
