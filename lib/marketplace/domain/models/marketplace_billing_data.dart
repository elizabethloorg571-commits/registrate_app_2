class MarketplaceBillingData {
  const MarketplaceBillingData({
    required this.fullName,
    required this.dni,
    required this.email,
    required this.address,
    required this.phone,
  });

  final String fullName;
  final String dni;
  final String email;
  final String address;
  final String phone;

  factory MarketplaceBillingData.fromUserBillingData(
    Map<String, dynamic>? rawData,
  ) {
    return MarketplaceBillingData(
      fullName: rawData?['nombres']?.toString() ?? '',
      dni: rawData?['num_documento']?.toString() ?? '',
      email: rawData?['email']?.toString() ?? '',
      address: rawData?['direccion']?.toString() ?? '',
      phone:
          rawData?['celular']?.toString() ??
          rawData?['telefono']?.toString() ??
          '',
    );
  }

  factory MarketplaceBillingData.fromForm({
    required String fullName,
    required String dni,
    required String email,
    required String address,
    required String phone,
  }) {
    return MarketplaceBillingData(
      fullName: fullName.trim(),
      dni: dni.trim(),
      email: email.trim(),
      address: address.trim(),
      phone: phone.trim(),
    );
  }

  Map<String, dynamic> toOrderJson() {
    return {
      'numero_documento': dni,
      'nombres': fullName,
      'email': email,
      'direccion': address,
      'celular': phone,
    };
  }

  Map<String, dynamic> toUserBillingJson() {
    return {
      'nombres': fullName,
      'apellidos': '',
      'num_documento': dni,
      'email': email,
      'direccion': address,
      'celular': phone,
    };
  }

  bool equalsUserBillingData(Map<String, dynamic>? rawData) {
    final current = MarketplaceBillingData.fromUserBillingData(rawData);
    return current.fullName == fullName &&
        current.dni == dni &&
        current.email == email &&
        current.address == address &&
        current.phone == phone;
  }
}
