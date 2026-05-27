class MarketplaceDeliveryData {
  const MarketplaceDeliveryData({
    this.province,
    this.canton,
    this.parish,
    this.mainAddress,
    this.secondaryAddress,
    this.reference,
    this.cellphone,
    this.lat,
    this.lng,
  });

  final String? province;
  final String? canton;
  final String? parish;
  final String? mainAddress;
  final String? secondaryAddress;
  final String? reference;
  final String? cellphone;
  final String? lat;
  final String? lng;

  factory MarketplaceDeliveryData.fromForm({
    required String province,
    required String canton,
    required String parish,
    required String mainAddress,
    required String secondaryAddress,
    required String reference,
    required String cellphone,
    required String lat,
    required String lng,
  }) {
    return MarketplaceDeliveryData(
      province: _trimOrNull(province),
      canton: _trimOrNull(canton),
      parish: _trimOrNull(parish),
      mainAddress: _trimOrNull(mainAddress),
      secondaryAddress: _trimOrNull(secondaryAddress),
      reference: _trimOrNull(reference),
      cellphone: _trimOrNull(cellphone),
      lat: _trimOrNull(lat),
      lng: _trimOrNull(lng),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'province': province,
      'canton': canton,
      'parish': parish,
      'main_address': mainAddress,
      'secondary_address': secondaryAddress,
      'reference': reference,
      'cellphone': cellphone,
      'lat': lat,
      'lng': lng,
    };
  }

  static String? _trimOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
