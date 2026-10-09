const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Currency display. Matches the Milestone 02 prototype ($).
/// Change this one line if the group decides to switch to Rs.
String money(double value) => '\$${value.toStringAsFixed(2)}';

String fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

String fmtDateFull(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';
