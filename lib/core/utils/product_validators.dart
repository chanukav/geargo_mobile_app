/// Form validators for shop equipment listing and editing.
class ProductValidators {
  ProductValidators._();

  /// Validates that a required text field is non-empty.
  static String? requiredField(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  /// Validates non-negative monetary amounts (e.g. price per day, deposit).
  static String? money(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Enter a valid amount';
    }
    final n = double.tryParse(v.trim());
    if (n == null || n < 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  /// Validates non-negative integer stock quantities.
  static String? quantity(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Enter a whole number';
    }
    final n = int.tryParse(v.trim());
    if (n == null || n < 0) {
      return 'Enter a whole number';
    }
    return null;
  }
}
