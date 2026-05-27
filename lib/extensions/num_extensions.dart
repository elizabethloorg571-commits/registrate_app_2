extension NumExtensions on num {
  num toMoney() => double.parse(toStringAsFixed(2));
}
