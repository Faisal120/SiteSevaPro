String compactInr(num value) {
  final amount = value.toDouble();
  if (amount.abs() >= 10000000) {
    return 'INR ${(amount / 10000000).toStringAsFixed(_precision(amount, 10000000))} Cr';
  }
  if (amount.abs() >= 100000) {
    return 'INR ${(amount / 100000).toStringAsFixed(_precision(amount, 100000))} L';
  }
  if (amount.abs() >= 1000) {
    return 'INR ${(amount / 1000).toStringAsFixed(_precision(amount, 1000))} K';
  }
  return 'INR ${amount.toStringAsFixed(0)}';
}

String appDate(DateTime? value, {String fallback = 'Not set'}) {
  if (value == null || value.millisecondsSinceEpoch == 0) return fallback;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

int _precision(double value, int divisor) => value % divisor == 0 ? 0 : 1;
