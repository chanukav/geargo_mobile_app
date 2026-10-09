const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Configurable currency symbol. Defaults to 'RM' to match group members' screens.
String currencySymbol = 'RM';

void setCurrencySymbol(String symbol) {
  currencySymbol = symbol;
}

/// Centralized currency formatter.
String money(double value, [String? symbol]) {
  final s = symbol ?? currencySymbol;
  return '$s ${value.toStringAsFixed(2)}';
}

/// Formats a DateTime as "Oct 15".
String fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

/// Formats a DateTime as "Oct 15, 2026".
String fmtDateFull(DateTime d) =>
    '${_months[d.month - 1]} ${d.day}, ${d.year}';

/// Centralized rental duration business rule:
/// Calculated as calendar day difference, with a minimum fallback of 1 day.
int calculateRentalDays(DateTime pickupDate, DateTime returnDate) {
  final diff = returnDate.difference(pickupDate).inDays;
  return diff < 1 ? 1 : diff;
}
