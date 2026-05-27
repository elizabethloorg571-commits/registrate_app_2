extension DoubleExtensions on double {
  double toMoney() => double.parse(toStringAsFixed(2));
}
