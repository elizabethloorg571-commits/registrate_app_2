class MoneyUtils {
  static String formatCurrency(num amount, {String separator = ','}) {
    String formattedAmount = amount
        .toStringAsFixed(2)
        .replaceAll('.', separator);
    return '\$$formattedAmount';
  }

  static double parseCurrency(String amount) {
    return double.tryParse(amount.replaceAll('\$', '')) ?? 0.0;
  }

  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(2)}%';
  }
}
