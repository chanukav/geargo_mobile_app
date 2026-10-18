import 'package:flutter/services.dart';

/// Card brand detected from the Primary Account Number (PAN) prefix.
enum CardBrand {
  visa('Visa'),
  mastercard('Mastercard'),
  amex('American Express'),
  other('Other');

  const CardBrand(this.displayName);
  final String displayName;
}

/// Utility functions for credit/debit card validation, formatting, and brand detection.
/// Satisfies project security constraints: PAN and CVV are never stored or logged.
class CardUtils {
  CardUtils._();

  /// Detects the card brand based on standard IIN/BIN prefixes.
  static CardBrand detectBrand(String cardNumber) {
    final clean = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return CardBrand.other;

    // Visa: starts with 4
    if (clean.startsWith('4')) {
      return CardBrand.visa;
    }

    // Mastercard: starts with 51-55 or 2221-2720
    if (clean.length >= 2) {
      final prefix2 = int.tryParse(clean.substring(0, 2)) ?? 0;
      if (prefix2 >= 51 && prefix2 <= 55) {
        return CardBrand.mastercard;
      }
    }
    if (clean.length >= 4) {
      final prefix4 = int.tryParse(clean.substring(0, 4)) ?? 0;
      if (prefix4 >= 2221 && prefix4 <= 2720) {
        return CardBrand.mastercard;
      }
    }

    // American Express: starts with 34 or 37
    if (clean.startsWith('34') || clean.startsWith('37')) {
      return CardBrand.amex;
    }

    return CardBrand.other;
  }

  /// Validates a card number using the Luhn Algorithm (Mod 10).
  static bool isValidLuhn(String cardNumber) {
    final clean = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 13 || clean.length > 19) return false;

    int sum = 0;
    bool alternate = false;

    for (int i = clean.length - 1; i >= 0; i--) {
      int digit = int.parse(clean[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Validates whether the length of [cardNumber] matches the rules for its brand.
  static bool hasValidLength(String cardNumber) {
    final clean = cardNumber.replaceAll(RegExp(r'\D'), '');
    final brand = detectBrand(clean);

    switch (brand) {
      case CardBrand.amex:
        return clean.length == 15;
      case CardBrand.visa:
        return clean.length == 13 || clean.length == 16 || clean.length == 19;
      case CardBrand.mastercard:
        return clean.length == 16;
      case CardBrand.other:
        return clean.length >= 13 && clean.length <= 19;
    }
  }

  /// Validates an expiration date in MM/YY format.
  /// Returns null if valid, or an error message if invalid.
  static String? validateExpiry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expiry date is required';
    }

    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.length != 4) {
      return 'Use MM/YY format';
    }

    final month = int.tryParse(clean.substring(0, 2));
    final yearSuffix = int.tryParse(clean.substring(2, 4));

    if (month == null || month < 1 || month > 12) {
      return 'Invalid month (01-12)';
    }

    if (yearSuffix == null) {
      return 'Invalid year';
    }

    final fullYear = 2000 + yearSuffix;
    final now = DateTime.now();

    // The card is valid until the end of the specified expiration month.
    final expiryEndOfMonth = DateTime(fullYear, month + 1, 0, 23, 59, 59);

    if (expiryEndOfMonth.isBefore(now)) {
      return 'Card has expired';
    }

    // Reject dates more than 20 years in the future to avoid typos
    if (fullYear > now.year + 20) {
      return 'Invalid expiry year';
    }

    return null;
  }

  /// Validates a Card Verification Value (CVV/CVC) code based on the brand.
  static String? validateCvv(String? value, CardBrand brand) {
    if (value == null || value.trim().isEmpty) {
      return 'CVV is required';
    }

    final clean = value.replaceAll(RegExp(r'\D'), '');
    final expectedLength = brand == CardBrand.amex ? 4 : 3;

    if (clean.length != expectedLength) {
      return brand == CardBrand.amex ? 'Amex CVV must be 4 digits' : 'CVV must be 3 digits';
    }

    return null;
  }

  /// Extracts the last 4 digits of a card number.
  static String extractLast4(String cardNumber) {
    final clean = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 4) return clean;
    return clean.substring(clean.length - 4);
  }

  /// Parses month and year integers from an MM/YY string.
  static ({int month, int year}) parseExpiry(String expiryString) {
    final clean = expiryString.replaceAll(RegExp(r'\D'), '');
    if (clean.length >= 4) {
      final month = int.parse(clean.substring(0, 2));
      final yearSuffix = int.parse(clean.substring(2, 4));
      return (month: month, year: 2000 + yearSuffix);
    }
    return (month: 1, year: DateTime.now().year);
  }
}

/// TextInputFormatter that formats card numbers into spaced groups.
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final isAmex = text.startsWith('34') || text.startsWith('37');
    final buffer = StringBuffer();

    if (isAmex) {
      // Amex grouping: 4 - 6 - 5
      for (int i = 0; i < text.length && i < 15; i++) {
        if (i == 4 || i == 10) buffer.write(' ');
        buffer.write(text[i]);
      }
    } else {
      // Standard grouping: 4 - 4 - 4 - 4
      for (int i = 0; i < text.length && i < 19; i++) {
        if (i > 0 && i % 4 == 0) buffer.write(' ');
        buffer.write(text[i]);
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// TextInputFormatter that auto-formats expiration dates to MM/YY.
class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
