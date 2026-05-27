class BankTransferInfo {
  final String banckName;
  final String accountNumber;
  final String accountType;
  final String accountHoldersName;
  final String documentNumber;

  const BankTransferInfo({
    required this.banckName,
    required this.accountNumber,
    required this.accountType,
    required this.accountHoldersName,
    required this.documentNumber,
  });

  bool get isValid =>
      banckName.isNotEmpty &&
      accountNumber.isNotEmpty &&
      accountType.isNotEmpty &&
      accountHoldersName.isNotEmpty &&
      documentNumber.isNotEmpty;

  static BankTransferInfo? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final name = data['banckName']?.toString() ?? '';
    final number = data['accountNumber']?.toString() ?? '';
    final type = data['accountType']?.toString() ?? '';
    final holder = data['accountHoldersName']?.toString() ?? '';
    final doc = data['documentNumber']?.toString() ?? '';
    if (name.isEmpty && number.isEmpty) return null;
    return BankTransferInfo(
      banckName: name,
      accountNumber: number,
      accountType: type,
      accountHoldersName: holder,
      documentNumber: doc,
    );
  }
}
